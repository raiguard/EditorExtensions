local util = require("prototypes.util")

-- set tesseract chest inventory size
local to_check = {
  "ammo",
  "armor",
  "blueprint",
  "blueprint-book",
  "capsule",
  "copy-paste-tool",
  "deconstruction-item",
  "gun",
  "item",
  "item-with-entity-data",
  "item-with-inventory",
  "item-with-label",
  "item-with-tags",
  "module",
  "rail-planner",
  "repair-tool",
  "selection-tool",
  "tool",
  "upgrade-item"
}
-- start with four extra slots to account for inserter interactions
local slot_count = 4
for _, category in pairs(to_check) do
  slot_count = slot_count + table_size(data.raw[category])
end
-- apply to tesseract chests
for _, container in pairs(data.raw["infinity-container"]) do
  if string.find(container.name, "tesseract") then
    -- set tesseract chest inventory size to the number of item prototypes
    container.inventory_size = slot_count
  end
end

-- allow all science packs to be placed in the super lab
local packs_build = {}
for _, lab in pairs(data.raw["lab"]) do
  for _,  input in pairs(lab.inputs) do
    packs_build[input] = true
  end
end
local packs = {}
for pack in pairs(packs_build) do
  table.insert(packs, pack)
end
data.raw["lab"]["ee-super-lab"].inputs = packs

-- allow equipment to be placed in all existing grid categories
local categories = {}
for _, category in pairs(data.raw["equipment-category"]) do
  table.insert(categories, category.name)
end
data.raw["generator-equipment"]["ee-infinity-fusion-reactor-equipment"].categories = categories
data.raw["roboport-equipment"]["ee-super-personal-roboport-equipment"].categories = categories
data.raw["movement-bonus-equipment"]["ee-super-exoskeleton-equipment"].categories = categories
data.raw["energy-shield-equipment"]["ee-super-energy-shield-equipment"].categories = categories
data.raw["night-vision-equipment"]["ee-super-night-vision-equipment"].categories = categories

-- reset all modules to be able to be used in all recipes
local modules = {
  "ee-super-speed-module",
  "ee-super-effectivity-module",
  "ee-super-productivity-module",
  "ee-super-clean-module",
  "ee-super-slow-module",
  "ee-super-ineffectivity-module",
  "ee-super-dirty-module"
}
for _, name in pairs(modules) do
  data.raw["module"][name].limitation = nil
end