local global_data = {}

local cheat_mode = require("scripts.cheat-mode")
local player_data = require("scripts.player-data")

function global_data.init()
  global.combinators = {}
  global.flags = {
    map_editor_toggled = false
  }
  global.players = {}
  for i, p in pairs(game.players) do
    player_data.init(i)
    if p.cheat_mode then
      cheat_mode.enable_recipes(p)
    end
  end
  global.wagons = {}
end

return global_data