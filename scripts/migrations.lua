local player_data = require("__EditorExtensions__/scripts/player-data")
local util = require("__EditorExtensions__/scripts/util")

local aggregate_chest = require("__EditorExtensions__/scripts/entity/aggregate-chest")
local infinity_loader = require("__EditorExtensions__/scripts/entity/infinity-loader")
local infinity_pipe = require("__EditorExtensions__/scripts/entity/infinity-pipe")

local migrations = {}

function migrations.generic()
  aggregate_chest.update_data()
  aggregate_chest.update_all_filters()
  infinity_loader.cleanup_orphans()

  util.add_cursor_enhancements_overrides()

  for i, player in pairs(game.players) do
    player_data.refresh(player, global.players[i])
  end
end

migrations.by_version = {
  ["1.12.0"] = function()
    infinity_pipe.init()
  end,
  ["2.0.0"] = function()
    infinity_loader.init()
  end,
}

return migrations
