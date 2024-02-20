-- Start with four extra slots to account for inserter interactions
local slot_count = 4
for category in pairs(defines.prototypes.item) do
  slot_count = slot_count + table_size(data.raw[category] or {})
end
for _, container in pairs(data.raw["infinity-container"]) do
  if string.find(container.name, "aggregate") then
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
