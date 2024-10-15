local flib_migration = require("__flib__.migration")

local infinity_accumulator = require("scripts.infinity-accumulator")
local infinity_loader = require("scripts.infinity-loader")
local inventory_filters = require("scripts.inventory-filters")
local inventory_sync = require("scripts.inventory-sync")
local linked_belt = require("scripts.linked-belt")

local version_migrations = {
  ["2.0.0"] = function()
    -- Preserve testing lab state
    local testing_lab_state = {}
    for player_index, player_table in pairs(storage.players) do
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
    storage = { testing_lab_state = testing_lab_state, wagons = storage.wagons }
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
    infinity_accumulator.on_init()
    infinity_loader.on_init()
    inventory_filters.on_init()
    inventory_sync.on_init()
    linked_belt.on_init()
  end,
  ["2.3.0"] = function()
    storage.aggregate_filters = nil
    storage.infinity_pipe_amount_type = nil
    for _, gui in pairs(storage.infinity_pipe_gui or {}) do
      local window = gui.elems.ee_infinity_pipe_window
      if window and window.valid then
        window.destroy()
      end
    end
    storage.infinity_pipe_gui = nil
  end,
}

local migrations = {}

migrations.on_configuration_changed = function(e)
  flib_migration.on_config_changed(e, version_migrations)
end

return migrations
