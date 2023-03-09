local flib_migration = require("__flib__/migration")

local aggregate_chest = require("__EditorExtensions__/scripts/aggregate-chest")
local infinity_accumulator = require("__EditorExtensions__/scripts/infinity-accumulator")
local infinity_loader = require("__EditorExtensions__/scripts/infinity-loader")
local infinity_pipe = require("__EditorExtensions__/scripts/infinity-pipe")
local inventory_filters = require("__EditorExtensions__/scripts/inventory-filters")
local inventory_sync = require("__EditorExtensions__/scripts/inventory-sync")
local linked_belt = require("__EditorExtensions__/scripts/linked-belt")

local version_migrations = {
  ["2.0.0"] = function()
    -- Preserve testing lab state
    local testing_lab_state = {}
    for player_index, player_table in pairs(global.players) do
      local player = game.get_player(player_index)
      if player and player_table.lab_state and player_table.normal_state then
        testing_lab_state[player_index] = {
          normal = player_table.normal_state,
          lab = player_table.lab_state,
          player = player,
          refresh = false,
        }
      end
    end
    -- NUKE EVERYTHING
    global = { testing_lab_state = testing_lab_state, wagons = global.wagons }
    rendering.clear("EditorExtensions")
    for _, player in pairs(game.players) do
      for _, gui in pairs({ player.gui.top, player.gui.left, player.gui.center, player.gui.screen, player.gui.relative }) do
        for _, child in pairs(gui.children) do
          if child.get_mod() == "EditorExtensions" then
            child.destroy()
          end
        end
      end
    end
    -- Start over
    aggregate_chest.on_init()
    infinity_accumulator.on_init()
    infinity_loader.on_init()
    infinity_pipe.on_init()
    inventory_filters.on_init()
    inventory_sync.on_init()
    linked_belt.on_init()
  end,
}

local migrations = {}

migrations.on_configuration_changed = function(e)
  flib_migration.on_config_changed(e, version_migrations)
end

return migrations
