local empty_map_gen_settings = {
  default_enable_all_autoplace_controls = false,
  property_expression_names = { cliffiness = 0 },
  autoplace_settings = {
    tile = { settings = { ["out-of-map"] = { frequency = "normal", size = "normal", richness = "normal" } } },
  },
  starting_area = "none",
}

--- @class TestingLabState
--- @field surface LuaSurface
--- @field force LuaForce
--- @field player LuaPlayer

--- @param player LuaPlayer
--- @param ts_setting string
local function toggle_lab(player, ts_setting)
  local key
  if ts_setting == "personal" then
    key = player.index
  elseif game.forces["EE_TESTSURFACE_shared"] then
    -- For versions prior to 1.13.0, all forces used the "shared" lab
    key = "shared"
  else
    -- Use the actual force name, not the testing lab force name
    key = string.gsub(player.force.name, "EE_TESTFORCE_", "")
  end
  local testing_surface_name = "EE_TESTSURFACE_" .. key
  local testing_force_name = "EE_TESTFORCE_" .. key
  local in_editor = player.controller_type == defines.controllers.editor

  -- VERIFY INFO

  local to_state = global.testing_lab_state[player.index]

  -- If the surface is invalid in any way, or its name does not match our lab's name, or the force is invalid
  if
    not to_state
    or not to_state.surface.valid
    or (string.find(to_state.surface.name, "EE_TESTSURFACE_") and to_state.surface.name ~= testing_surface_name)
    or not to_state.force.valid
  then
    local testing_surface = game.get_surface(testing_surface_name)
    if not testing_surface then
      testing_surface = game.create_surface(testing_surface_name, empty_map_gen_settings)
      if not testing_surface then
        player.print("Could not create test surface")
        return
      end
      -- Lab conditions
      testing_surface.generate_with_lab_tiles = true
      testing_surface.freeze_daytime = true
      testing_surface.show_clouds = false
      testing_surface.daytime = 0
      -- Warn the player about the passage of time
      player.print({ "message.ee-time-passes-in-lab" })
    end

    local force = game.forces[testing_force_name]
    if not game.forces[testing_force_name] then
      if table_size(game.forces) == 64 then
        player.print(
          "Cannot create a testing lab force. Factorio only supports up to 64 forces at once. Please use a shared lab."
        )
        return
      end

      force = game.create_force(testing_force_name)
      if settings.global["ee-testing-lab-match-research"].value then
        -- Sync research techs with the parent force
        for name, tech in pairs(player.force.technologies) do
          force.technologies[name].researched = tech.researched
        end
      else
        force.research_all_technologies()
      end
    end

    to_state = { force = force, position = { x = 0, y = 0 }, surface = testing_surface }
  end

  --- @type TestingLabState?
  local current_state = nil
  if in_editor then
    local force = player.force --[[@as LuaForce]]
    current_state = {
      force = force,
      position = player.position,
      surface = player.surface,
    }
  else
    current_state = {
      force = game.forces[testing_force_name],
      position = player.position,
      surface = game.get_surface(testing_surface_name),
    }
  end
  global.testing_lab_state[player.index] = current_state

  if to_state.surface.valid and to_state.force.valid then
    player.force = to_state.force
    player.teleport(to_state.position, to_state.surface)
  end
end

--- @param e EventData.on_force_reset
local function on_force_reset(e)
  local parent_force = e.force
  if string.find(parent_force.name, "EE_TESTFORCE_") then
    return
  end
  if not settings.global["ee-testing-lab-match-research"].value then
    return
  end

  local testing_force = game.forces["EE_TESTFORCE_" .. parent_force.name]
  if not testing_force then
    return
  end

  for name, tech in pairs(parent_force.technologies) do
    testing_force.technologies[name].researched = tech.researched
  end
  testing_force.reset_technology_effects()
end

--- @param e EventData.on_player_toggled_map_editor
local function on_player_toggled_map_editor(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  local testing_lab_setting = player.mod_settings["ee-testing-lab"].value --[[@as string]]
  if testing_lab_setting == "off" then
    return
  end

  toggle_lab(player, testing_lab_setting)
end

--- @param e EventData.on_research_reversed
local function on_research_reversed(e)
  local parent_force = e.research.force
  if string.find(parent_force.name, "EE_TESTFORCE_") then
    return
  end
  if not settings.global["ee-testing-lab-match-research"].value then
    return
  end

  local testing_force = game.forces["EE_TESTFORCE_" .. parent_force.name]
  if testing_force then
    testing_force.technologies[e.research.name].researched = false
  end

  for i in pairs(parent_force.players) do
    local testing_force = game.forces["EE_TESTFORCE_" .. i]
    if testing_force then
      testing_force.technologies[e.research.name].researched = false
    end
  end
end

--- @param e EventData.on_research_finished
local function on_research_finished(e)
  local parent_force = e.research.force
  if string.find(parent_force.name, "EE_TESTFORCE_") then
    return
  end
  if not settings.global["ee-testing-lab-match-research"].value then
    return
  end

  local testing_force = game.forces["EE_TESTFORCE_" .. parent_force.name]
  if testing_force then
    testing_force.technologies[e.research.name].researched = true
  end

  for i in pairs(parent_force.players) do
    local testing_force = game.forces["EE_TESTFORCE_" .. i]
    if testing_force then
      testing_force.technologies[e.research.name].researched = true
    end
  end
end

--- @param e EventData.on_runtime_mod_setting_changed
local function on_runtime_mod_setting_changed(e)
  if e.setting ~= "ee-testing-lab-match-research" then
    return
  end
  for _, force in pairs(game.forces) do
    local _, _, force_key = string.find(force.name, "EE_TESTFORCE_(.*)")
    if not force_key then
      goto continue
    end
    if not settings.global["ee-testing-lab-match-research"].value then
      force.research_all_technologies()
      goto continue
    end

    local parent_force
    local force_key_num = tonumber(force_key) --- @cast force_key_num uint?
    if force_key_num then
      local player = game.get_player(force_key_num) --[[@as LuaPlayer]]
      parent_force = remote.call("EditorExtensions", "get_player_proper_force", player)
    else
      parent_force = game.forces[force_key]
    end
    if parent_force then
      -- Sync research techs with the parent force
      for name, tech in pairs(parent_force.technologies) do
        force.technologies[name].researched = tech.researched
      end
    end
    force.reset_technology_effects()
    ::continue::
  end
end

local testing_lab = {}

testing_lab.on_init = function()
  --- @type table<uint, TestingLabState>
  global.testing_lab_state = {}
end

testing_lab.events = {
  [defines.events.on_force_reset] = on_force_reset,
  [defines.events.on_player_toggled_map_editor] = on_player_toggled_map_editor,
  [defines.events.on_research_finished] = on_research_finished,
  [defines.events.on_research_reversed] = on_research_reversed,
  [defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed,
}

testing_lab.add_remote_interface = function()
  remote.add_interface("EditorExtensions", {
    --- Get the force that the player is actually on, ignoring the testing lab force.
    --- @param player LuaPlayer
    --- @return ForceIdentification
    get_player_proper_force = function(player)
      if not player or not player.valid then
        error("Did not pass a valid LuaPlayer")
      end
      local in_editor = player.controller_type == defines.controllers.editor
      local ts_setting = player.mod_settings["ee-testing-lab"].value
      if ts_setting == "off" or not in_editor then
        return player.force
      else
        return global.testing_lab_state[player.index].force
      end
    end,
  })
end

return testing_lab
