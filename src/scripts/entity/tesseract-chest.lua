local tesseract_chest = {}

local chest_names = {
  "ee-tesseract-chest",
  "ee-tesseract-chest-passive-provider"
}

-- set the filters for the given tesseract chest
function tesseract_chest.set_filters(entity)
  entity.remove_unfiltered_items = true
  local i = 0
  for name, stack_size in pairs(global.tesseract_data) do
    i = i + 1
    entity.set_infinity_container_filter(i, {name=name, count=stack_size, mode="exactly", index=i})
  end
end

-- updates the filters of all existing tesseract chests
function tesseract_chest.update_all_filters()
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name=chest_names}) do
      tesseract_chest.set_filters(entity)
    end
  end
end

-- retrieve each item prototype and its stack size
function tesseract_chest.update_data()
  local include_hidden = settings.global["ee-tesseract-include-hidden"].value
  local data = {}
  for name, prototype in pairs(game.item_prototypes) do
    if include_hidden or not prototype.has_flag("hidden") then
      data[name] = prototype.stack_size
    end
  end
  -- remove dummy-steel-axe, since trying to include it will crash the game
  data["dummy-steel-axe"] = nil
  global.tesseract_data = data
end

return tesseract_chest