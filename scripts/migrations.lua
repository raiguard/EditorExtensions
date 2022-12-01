local cheat_command = require("__EditorExtensions__/scripts/cheat-command")
local cheat_mode = require("__EditorExtensions__/scripts/cheat-mode")
local compatibility = require("__EditorExtensions__/scripts/compatibility")
local player_data = require("__EditorExtensions__/scripts/player-data")

local aggregate_chest = require("__EditorExtensions__/scripts/entity/aggregate-chest")
local infinity_loader = require("__EditorExtensions__/scripts/entity/infinity-loader")
local infinity_pipe = require("__EditorExtensions__/scripts/entity/infinity-pipe")

local migrations = {}

function migrations.generic()
  aggregate_chest.update_data()
  aggregate_chest.update_all_filters()
  infinity_loader.cleanup_orphans()

  compatibility.add_cursor_enhancements_overrides()

  for i, player in pairs(game.players) do
    player_data.refresh(player, global.players[i])
    -- Space Exploration - do nothing if they are in the satellite view
    if player.cheat_mode and not script.active_mods["space-exploration"] then
      cheat_mode.enable_recipes(player)
    end
  end
end

migrations.by_version = {
  ["1.12.0"] = function()
    infinity_pipe.init()
  end,
  ["2.0.0"] = function()
    cheat_command.init()
    infinity_loader.init()
  end,
}

return migrations
