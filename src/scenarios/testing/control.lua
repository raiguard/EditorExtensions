if (__DebugAdapter or __Profiler) then
  (__DebugAdapter or __Profiler).levelPath("EditorExtensions", "scenarios/testing/")
end

local event = require("__flib__.event")

event.on_init(function()
  -- set lab tiles
  local nauvis = game.surfaces.nauvis
  -- nauvis.generate_with_lab_tiles = true
  nauvis.clear(true)

  -- freeze time at noonday
  nauvis.freeze_daytime = true
  nauvis.daytime = 0
end)

event.on_player_created(function(e)
  if not global.message_shown then
    global.message_shown = true
    if game.is_multiplayer() then
      game.get_player(e.player_index).print{"description"}
    else
      game.show_message_dialog{text={"description"}, point_to={type="position", position={0,-1.5}}}
    end
  end
end)

remote.add_interface("EditorExtensions_TestingScenario", {})