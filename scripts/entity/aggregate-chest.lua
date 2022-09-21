local aggregate_chest = {}

local constants = require("__EditorExtensions__.scripts.constants")

--- Set the filters for the given aggregate chest and removes the bar if there is one
--- @param entity LuaEntity
function aggregate_chest.set_filters(entity)
  entity.remove_unfiltered_items = true
  entity.infinity_container_filters = global.aggregate_filters
  entity.get_inventory(defines.inventory.chest).set_bar()
end

-- update the filters of all existing aggregate chests
function aggregate_chest.update_all_filters()
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered({ name = constants.aggregate_chest_names })) do
      aggregate_chest.set_filters(entity)
    end
  end
end

-- retrieve each item prototype and its stack size
function aggregate_chest.update_data()
  local include_hidden = settings.global["ee-aggregate-include-hidden"].value
  local data = {}
  local i = 0
  for name, prototype in pairs(game.item_prototypes) do
    if prototype.type ~= "mining-tool" and include_hidden or not prototype.has_flag("hidden") then
      i = i + 1
      data[i] = { name = name, count = prototype.stack_size, mode = "exactly", index = i }
    end
  end
  global.aggregate_filters = data
end

--- Remove filters on aggregate chests when blueprinted
--- @param entity BlueprintEntity
function aggregate_chest.setup_blueprint(entity)
  entity.infinity_settings.filters = nil
end

return aggregate_chest
