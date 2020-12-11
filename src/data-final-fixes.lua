local constants = require("prototypes.constants")
local util = require("prototypes.util")

-- set aggregate chest inventory size
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
  "upgrade-item"
}
-- start with four extra slots to account for inserter interactions
local slot_count = 4
for _, category in pairs(to_check) do
  slot_count = slot_count + table_size(data.raw[category])
end
-- apply to aggregate chests
for _, container in pairs(data.raw["infinity-container"]) do
  if string.find(container.name, "aggregate") then
    -- set aggregate chest inventory size to the number of item prototypes
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

-- allow all character prototypes to craft testing tools
for _, character in pairs(data.raw["character"]) do
  character.crafting_categories = character.crafting_categories or {}
  character.crafting_categories[#character.crafting_categories+1] = "ee-testing-tool"
end

-- generate linked belts and infinity loaders

local linked_belt_base = table.deepcopy(data.raw["linked-belt"]["linked-belt"])
linked_belt_base.icons = util.extract_icon_info(linked_belt_base)
linked_belt_base.localised_name = {"entity-name.ee-linked-belt"}
linked_belt_base.localised_description = {"entity-description.ee-linked-belt"}
linked_belt_base.placeable_by = {item = "ee-linked-belt", count = 1}
linked_belt_base.minable = {result = "ee-linked-belt", mining_time = 0.1}
util.recursive_tint(linked_belt_base, constants.alternate_tint)

local function create_linked_belt(base_prototype, suffix)
  local entity = table.deepcopy(linked_belt_base)
  entity.name = "ee-linked-belt"..suffix

  entity.belt_animation_set = base_prototype.belt_animation_set
  entity.speed = base_prototype.speed

  data:extend{entity}
end

local loader_base = table.deepcopy(data.raw["loader-1x1"]["loader-1x1"])
loader_base.structure = table.deepcopy(linked_belt_base.structure)
loader_base.icons = table.deepcopy(linked_belt_base.icons)
loader_base.icon = nil
loader_base.icon_size = nil
loader_base.icon_mipmaps = nil
loader_base.localised_name = {"entity-name.ee-infinity-loader"}
loader_base.localised_description = {"entity-name.ee-infinity-loader"}
loader_base.selectable_in_game = false
loader_base.belt_length = 0.6
loader_base.container_distance = 0
util.recursive_tint(loader_base)

local function create_loader(base_prototype, suffix)
  local entity = table.deepcopy(loader_base)
  entity.name = "ee-infinity-loader-loader"..suffix
  entity.belt_animation_set = base_prototype.belt_animation_set
  entity.speed = base_prototype.speed

  data:extend{entity}
end

for name, prototype in pairs(table.deepcopy(data.raw["underground-belt"])) do
  -- determine suffix
  local suffix = name
  for pattern, replacement in pairs(constants.belt_name_patterns) do
    suffix = string.gsub(suffix, pattern, replacement)
  end
  if suffix ~= "" then
    suffix = "-"..suffix
  end

  create_linked_belt(prototype, suffix)
  create_loader(prototype, suffix)
end