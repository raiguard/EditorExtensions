local aggregate_chest = {}

local chest_names = {
  "ee-aggregate-chest",
  "ee-aggregate-chest-passive-provider"
}

-- set the filters for the given aggregate chest
function aggregate_chest.set_filters(entity)
  entity.remove_unfiltered_items = true
  local i = 0
  for name, stack_size in pairs(global.aggregate_data) do
    i = i + 1
    entity.set_infinity_container_filter(i, {name=name, count=stack_size, mode="exactly", index=i})
  end
end

-- updates the filters of all existing aggregate chests
function aggregate_chest.update_all_filters()
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name=chest_names}) do
      aggregate_chest.set_filters(entity)
    end
  end
end

-- retrieve each item prototype and its stack size
function aggregate_chest.update_data()
  local include_hidden = settings.global["ee-aggregate-include-hidden"].value
  local data = {}
  for name, prototype in pairs(game.item_prototypes) do
    if prototype.type ~= "mining-tool" and include_hidden or not prototype.has_flag("hidden") then
      data[name] = prototype.stack_size
    end
  end
  global.aggregate_data = data
end

return aggregate_chest