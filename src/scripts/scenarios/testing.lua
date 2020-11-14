local event = require("__flib__.event")
local migration = require("__flib__.migration")

local silo_script = require("__core__.lualib.silo-script")

-- -----------------------------------------------------------------------------
-- UTILITIES

local radius = 200
local function setup_force(force)
  local spawn_pos = force.get_spawn_position("nauvis")
  force.chart("nauvis", {
    {(spawn_pos.x - radius), (spawn_pos.y - radius)}, {(spawn_pos.x + radius), (spawn_pos.y + radius)}
  })

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
  end
}

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

event.on_init(function()
  silo_script.on_init()
  remote.call("silo_script", "set_no_victory", true)

  if remote.interfaces["kr-crash-site"] then
    remote.call("kr-crash-site", "crash_site_enabled", false)
  end

  for _, force in pairs(game.forces) do
    setup_force(force)
  end
end)

event.on_load(silo_script.on_load)

event.on_configuration_changed(function(e)
  migration.on_config_changed(e, migrations, "EditorExtensions")
  silo_script.on_configuration_changed(e)
  remote.call("silo_script", "set_no_victory", true)
end)

event.on_force_created(function(e)
  setup_force(e.force)
end)

event.on_player_created(function(e)
  game.get_player(e.player_index).cheat_mode = true
end)

event.on_gui_click(silo_script.on_gui_click)
event.on_rocket_launched(silo_script.on_rocket_launched)

-- disable AAI industry crash site
remote.add_interface("EditorExtensions_TestingScenario", {
  allow_aai_crash_sequence = function() return {allow = false, weight = 1} end
})