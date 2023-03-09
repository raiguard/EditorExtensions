-- Set aggregate chest inventory size
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
  "spidertron-remote",
  "tool",
  "upgrade-item",
}
-- Start with four extra slots to account for inserter interactions
local slot_count = 4
for _, category in pairs(to_check) do
  slot_count = slot_count + table_size(data.raw[category])
end
-- Apply to aggregate chests
for _, container in pairs(data.raw["infinity-container"]) do
  if string.find(container.name, "aggregate") then
    -- Set aggregate chest inventory size to the number of item prototypes
    container.inventory_size = slot_count
  end
end

-- Allow all science packs to be placed in the super lab
local packs_build = {}
for _, lab in pairs(data.raw["lab"]) do
  for _, input in pairs(lab.inputs) do
    packs_build[input] = true
  end
end
local packs = {}
for pack in pairs(packs_build) do
  table.insert(packs, pack)
end
data.raw["lab"]["ee-super-lab"].inputs = packs

-- Allow equipment to be placed in all existing grid categories
local categories = {}
for _, category in pairs(data.raw["equipment-category"]) do
  table.insert(categories, category.name)
end
data.raw["generator-equipment"]["ee-infinity-fusion-reactor-equipment"].categories = categories
data.raw["roboport-equipment"]["ee-super-personal-roboport-equipment"].categories = categories
data.raw["movement-bonus-equipment"]["ee-super-exoskeleton-equipment"].categories = categories
data.raw["energy-shield-equipment"]["ee-super-energy-shield-equipment"].categories = categories
data.raw["night-vision-equipment"]["ee-super-night-vision-equipment"].categories = categories

-- Reset all super modules to be able to be used in all recipes
local modules = {
  "ee-super-speed-module",
  "ee-super-effectivity-module",
  "ee-super-productivity-module",
  "ee-super-clean-module",
  "ee-super-slow-module",
  "ee-super-ineffectivity-module",
  "ee-super-dirty-module",
}
for _, name in pairs(modules) do
  data.raw["module"][name].limitation = nil
end

-- Allow all character prototypes to craft testing tools
for _, character in pairs(data.raw["character"]) do
  character.crafting_categories = character.crafting_categories or {}
  character.crafting_categories[#character.crafting_categories + 1] = "ee-testing-tool"
end

-- Set infinity loader and linked belt speed to max
local fastest_speed = 0
for _, prototype in pairs(data.raw["underground-belt"]) do
  if prototype.speed > fastest_speed then
    fastest_speed = prototype.speed
  end
end
data.raw["linked-belt"]["ee-linked-belt"].speed = fastest_speed
data.raw["loader-1x1"]["ee-infinity-loader"].speed = fastest_speed
