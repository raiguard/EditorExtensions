if (__DebugAdapter or __Profiler) then
  (__DebugAdapter or __Profiler).levelPath("EditorExtensions", "scenarios/testing/")
end

local event = require("__flib__.event")

event.on_init(function()
  if remote.interfaces["kr-crash-site"] then
    remote.call("kr-crash-site", "crash_site_enabled", false)
  end
end)

event.on_player_created(function(e)
  local player = game.get_player(e.player_index)

  -- chart area
  local player_pos = player.position
  local radius = 200
  player.force.chart(player.surface, {{player_pos.x - radius, player_pos.y - radius}, {player_pos.x + radius, player_pos.y + radius}})

  -- show message
  if game.is_multiplayer() then
    player.print{"description"}
  else
    game.show_message_dialog{text={"description"}, point_to={type="position", position={0,-1.5}}}
  end
end)

remote.add_interface("EditorExtensions_TestingScenario", {})