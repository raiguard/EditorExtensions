--- @class LabState
--- @field lab StateData
--- @field normal StateData
--- @field player LuaPlayer
--- @field refresh boolean?

--- @class StateData
--- @field force LuaForce
--- @field position MapPosition
--- @field surface LuaSurface
--- @field vehicle LuaEntity?
--- @field is_driver boolean?

--- @alias LabSetting
--- | "force"
--- | "off"
--- | "personal"

local empty_map_gen_settings = {
  default_enable_all_autoplace_controls = false,
  property_expression_names = { cliffiness = 0 },
  autoplace_settings = {
    tile = { settings = { ["out-of-map"] = { frequency = "normal", size = "normal", richness = "normal" } } },
  },
  starting_area = "none",
}

--- @param player LuaPlayer
--- @param lab_setting LabSetting
--- @return LabState?
local function create_lab(player, lab_setting)
  local key
  if lab_setting == "personal" then
    key = player.index
  elseif game.forces["EE_TESTSURFACE_shared"] then
    -- For versions prior to 1.13.0, all forces used the "shared" lab
    key = "shared"
  else
    -- Use the actual force name, not the testing lab force name
    key = string.gsub(player.force.name, "EE_TESTFORCE_", "")
  end
  local surface_name = "EE_TESTSURFACE_" .. key
  local force_name = "EE_TESTFORCE_" .. key

  local surface = game.get_surface(surface_name)
  if not surface then
    surface = game.create_surface(surface_name, empty_map_gen_settings)
    if not surface then
      player.print("Could not create test surface")
      return
    end
    -- Lab conditions
    surface.generate_with_lab_tiles = true
    surface.freeze_daytime = true
    surface.show_clouds = false
    surface.daytime = 0
    -- Warn the player about the passage of time
    player.print({ "message.ee-time-passes-in-lab" })
  end

  local force = game.forces[force_name]
  if not game.forces[force_name] then
    if table_size(game.forces) == 64 then
      player.print(
        "Cannot create a testing lab force. Factorio only supports up to 64 forces at once. Please use a shared lab."
      )
      return
    end

    force = game.create_force(force_name)
    if settings.global["ee-testing-lab-match-research"].value then
      -- Sync research techs with the parent force
      for name, tech in pairs(player.force.technologies) do
        force.technologies[name].researched = tech.researched
      end
    else
      force.research_all_technologies()
    end
  end

  return {
    lab = { force = force, position = { x = 0, y = 0 }, surface = surface },
    normal = { force = player.force, position = player.position, surface = player.surface },
    player = player,
  }
end

--- @param player LuaPlayer
--- @param to_state StateData
local function transfer_player(player, to_state)
  if not to_state.force.valid or not to_state.surface.valid then
    return
  end

  -- Change force first to avoid spilling items into the real world on inventory size change - see #143
  player.force = to_state.force
  player.teleport(to_state.position, to_state.surface)
end

--- @param player LuaPlayer
local function enter_lab(player)
  local lab_state = global.testing_lab_state[player.index]
  if not lab_state then
    return
  end

  local normal_data = lab_state.normal
  normal_data.force = player.force --[[@as LuaForce]]
  normal_data.position = player.position
  normal_data.surface = player.surface

  transfer_player(player, lab_state.lab)
end

--- @param lab_state LabState
local function exit_lab(lab_state)
  local lab_data = lab_state.lab
  if lab_state.player.surface == lab_data.surface then
    lab_data.position = lab_state.player.position
  end

  transfer_player(lab_state.player, lab_state.normal)
end

--- @param player LuaPlayer
--- @return LabSetting
local function get_lab_setting(player)
  return player.mod_settings["ee-testing-lab"].value --[[@as LabSetting]]
end

--- @param e EventData.on_pre_player_toggled_map_editor
local function on_pre_player_toggled_map_editor(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  local lab_setting = get_lab_setting(player)
  if lab_setting == "off" then
    return
  end

  local in_editor = player.controller_type == defines.controllers.editor
  local lab_state = global.testing_lab_state[e.player_index]
  if not lab_state and not in_editor then
    lab_state = create_lab(player, lab_setting)
    global.testing_lab_state[e.player_index] = lab_state
  end
  if not lab_state then
    return
  end

  local current_state = in_editor and lab_state.lab or lab_state.normal
  current_state.vehicle = player.vehicle
  current_state.is_driver = player.driving

  if in_editor then
    exit_lab(lab_state)
  end
end

--- @param player LuaPlayer
local function sync_vehicle_state(player)
  local lab_state = global.testing_lab_state[player.index]
  if not lab_state then
    return
  end

  local in_editor = player.controller_type == defines.controllers.editor
  local new_state = in_editor and lab_state.lab or lab_state.normal

  local vehicle = new_state.vehicle
  if not vehicle or not vehicle.valid then
    return
  end

  if new_state.is_driver and not vehicle.get_driver() then
    new_state.vehicle.set_driver(player)
  elseif not new_state.is_driver and not vehicle.get_passenger() then
    new_state.vehicle.set_passenger(player)
  end
end

--- @param e EventData.on_player_toggled_map_editor
local function on_player_toggled_map_editor(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  if get_lab_setting(player) == "off" then
    return
  end

  if player.controller_type == defines.controllers.editor then
    enter_lab(player)
  end

  sync_vehicle_state(player)
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

local function on_match_research_setting_changed()
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

--- @param e EventData.on_runtime_mod_setting_changed
local function on_testing_lab_setting_changed(e)
  local lab_state = global.testing_lab_state[e.player_index]
  if lab_state then
    lab_state.refresh = true
  end
end

--- @param e EventData.on_runtime_mod_setting_changed
local function on_runtime_mod_setting_changed(e)
  if e.setting == "ee-testing-lab-match-research" then
    on_match_research_setting_changed()
  elseif e.setting == "ee-testing-lab" then
    on_testing_lab_setting_changed(e)
  end
end

local testing_lab = {}

testing_lab.on_init = function()
  --- @type table<uint, LabState?>
  global.testing_lab_state = {}
end

testing_lab.events = {
  [defines.events.on_force_reset] = on_force_reset,
  [defines.events.on_player_toggled_map_editor] = on_player_toggled_map_editor,
  [defines.events.on_pre_player_toggled_map_editor] = on_pre_player_toggled_map_editor,
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
      if
        ts_setting == "off"
        or not in_editor
        or not global.testing_lab_state
        or not global.testing_lab_state[player.index]
      then
        return player.force
      end

      return global.testing_lab_state[player.index].normal.force
    end,
  })
end

return testing_lab
