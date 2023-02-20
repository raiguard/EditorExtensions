local migration_util = require("__flib__/migration")

local aggregate_chest = require("__EditorExtensions__/scripts/aggregate-chest")
local infinity_accumulator = require("__EditorExtensions__/scripts/infinity-accumulator")
local infinity_loader = require("__EditorExtensions__/scripts/infinity-loader")
local infinity_pipe = require("__EditorExtensions__/scripts/infinity-pipe")
local infinity_wagon = require("__EditorExtensions__/scripts/infinity-wagon")
local inventory_filters = require("__EditorExtensions__/scripts/inventory-filters")
local inventory_sync = require("__EditorExtensions__/scripts/inventory-sync")
local linked_belt = require("__EditorExtensions__/scripts/linked-belt")
local testing_lab = require("__EditorExtensions__/scripts/testing-lab")

local version_migrations = {
  ["2.0.0"] = function()
    -- NUKE EVERYTHING
    global = {}
    rendering.clear("EditorExtensions")
    -- Start over
    -- TODO: Migrate testing lab state and infinity pipe types
    aggregate_chest.on_init()
    infinity_accumulator.on_init()
    infinity_loader.on_init()
    infinity_pipe.on_init()
    infinity_wagon.on_init()
    inventory_filters.on_init()
    inventory_sync.on_init()
    linked_belt.on_init()
    testing_lab.on_init()
  end,
}

local migrations = {}

migrations.on_configuration_changed = function(e)
  migration_util.on_config_changed(e, version_migrations)
end

return migrations
