--- @param force LuaForce
local function setup_force(force)
  force.max_successful_attempts_per_tick_per_construction_queue = 30
  force.max_failed_attempts_per_tick_per_construction_queue = 10
  force.research_all_technologies()
end

script.on_init(function()
  for _, force in pairs(game.forces) do
    setup_force(force)
  end
end)

script.on_event(defines.events.on_force_created, function(e)
  setup_force(e.force)
end)

script.on_event(defines.events.on_player_created, function(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  player.cheat_mode = true

  local start_in_editor = settings.global["ee-testing-start-in-editor"]
  if start_in_editor and start_in_editor.value then
    player.toggle_map_editor()
  end
end)

remote.add_interface("EditorExtensions_TestingScenario", {
  -- disable AAI industry crash site
  allow_aai_crash_sequence = function()
    return { allow = false, weight = 1 }
  end,
})
