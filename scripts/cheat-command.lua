local cheat_mode = require("__EditorExtensions__/scripts/cheat-mode")
local debug_world = require("__EditorExtensions__/scripts/debug-world")

local cheat_command = {}

function cheat_command.init()
  global.executed_cheat_command = {}
  global.tried_cheat_command = {}
end

function cheat_command.handle(e)
  local tried_tick = global.tried_cheat_command[e.player_index]
  if global.executed_cheat_command[e.player_index] or (tried_tick and tried_tick + (60 * 60) >= game.ticks_played) then
    global.executed_cheat_command[e.player_index] = true
    global.tried_cheat_command[e.player_index] = nil

    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    if e.parameters == "lab" then
      debug_world.lab(player.surface)
    elseif e.parameters == "all" then
      cheat_mode.set_loadout(player)
    end
  else
    global.tried_cheat_command[e.player_index] = game.ticks_played
  end
end

return cheat_command
