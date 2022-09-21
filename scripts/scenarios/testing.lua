local event = require("__flib__.event")
local migration = require("__flib__.migration")
local mod_gui = require("mod-gui")

local callbacks = {}

-- -----------------------------------------------------------------------------
-- UTILITIES

--- @param force LuaForce
local function setup_force(force)
  force.research_all_technologies()

  force.max_successful_attempts_per_tick_per_construction_queue = 30
  force.max_failed_attempts_per_tick_per_construction_queue = 10
end

-- migrations are based on EE versions
local migrations = {
  ["1.5.18"] = function()
    -- add bot bonuses to all forces
    for _, force in pairs(game.forces) do
      force.max_successful_attempts_per_tick_per_construction_queue = 30
      force.max_failed_attempts_per_tick_per_construction_queue = 10
    end
  end,
  ["1.8.3"] = function()
    -- remove rocket silo GUI
    for _, player in pairs(game.players) do
      local button = mod_gui.get_button_flow(player).silo_gui_sprite_button
      if button then
        button.destroy()
      end
      local frame = mod_gui.get_frame_flow(player).silo_gui_frame
      if frame then
        frame.destroy()
      end
    end
  end,
}

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

event.on_init(function()
  if remote.interfaces["kr-crash-site"] then
    remote.call("kr-crash-site", "crash_site_enabled", false)
  end

  for _, force in pairs(game.forces) do
    setup_force(force)
  end

  if callbacks.on_init then
    callbacks.on_init()
  end
end)

event.on_configuration_changed(function(e)
  migration.on_config_changed(e, migrations, "EditorExtensions")

  if callbacks.on_configuration_changed then
    callbacks.on_configuration_changed(e)
  end
end)

event.on_force_created(function(e)
  setup_force(e.force)

  if callbacks.on_force_created then
    callbacks.on_force_created(e)
  end
end)

event.on_player_created(function(e)
  game.get_player(e.player_index).cheat_mode = true

  if callbacks.on_player_created then
    callbacks.on_player_created(e)
  end
end)

remote.add_interface("EditorExtensions_TestingScenario", {
  -- disable AAI industry crash site
  allow_aai_crash_sequence = function()
    return { allow = false, weight = 1 }
  end,
})

return callbacks
