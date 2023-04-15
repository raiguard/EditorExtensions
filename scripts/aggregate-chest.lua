local util = require("__EditorExtensions__/scripts/util")

local aggregate_chest_names = {
  ["ee-aggregate-chest"] = "ee-aggregate-chest",
  ["ee-aggregate-chest-passive-provider"] = "ee-aggregate-chest-passive-provider",
}

--- Set the filters for the given aggregate chest and removes the bar if there is one
--- @param entity LuaEntity
local function set_filters(entity)
  entity.remove_unfiltered_items = true
  entity.infinity_container_filters = global.aggregate_filters
  entity.get_inventory(defines.inventory.chest).set_bar()
end

-- Update the filters of all existing aggregate chests
local function update_all_filters()
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered({ name = aggregate_chest_names })) do
      set_filters(entity)
    end
  end
end

-- Retrieve each item prototype and its stack size
local function build_filter_cache()
  local include_hidden = settings.global["ee-aggregate-include-hidden"].value
  --- @type InfinityInventoryFilter[]
  local filters = {}
  local i = 0
  for name, prototype in pairs(game.item_prototypes) do
    if prototype.type ~= "mining-tool" and include_hidden or not prototype.has_flag("hidden") then
      i = i + 1
      filters[i] = { name = name, count = prototype.stack_size, mode = "exactly", index = i }
    end
  end
  global.aggregate_filters = filters
end

--- @param e BuiltEvent
local function on_entity_built(e)
  local entity = e.created_entity or e.entity or e.destination
  if not entity or not entity.valid or not aggregate_chest_names[entity.name] then
    return
  end
  set_filters(entity)
end

--- @param e EventData.on_player_setup_blueprint
local function on_player_setup_blueprint(e)
  local blueprint = util.get_blueprint(e)
  if not blueprint then
    return
  end

  local entities = blueprint.get_blueprint_entities()
  if not entities then
    return
  end
  local set = false
  for _, entity in pairs(entities) do
    if aggregate_chest_names[entity.name] then
      set = true
      entity.infinity_settings.filters = nil --- @diagnostic disable-line
    end
  end
  if set then
    blueprint.set_blueprint_entities(entities)
  end
end

local aggregate_chest = {}

aggregate_chest.on_init = build_filter_cache

aggregate_chest.on_configuration_changed = function()
  build_filter_cache()
  update_all_filters()
end

aggregate_chest.events = {
  [defines.events.on_built_entity] = on_entity_built,
  [defines.events.on_entity_cloned] = on_entity_built,
  [defines.events.on_player_setup_blueprint] = on_player_setup_blueprint,
  [defines.events.on_robot_built_entity] = on_entity_built,
  [defines.events.script_raised_built] = on_entity_built,
  [defines.events.script_raised_revive] = on_entity_built,
}

return aggregate_chest
