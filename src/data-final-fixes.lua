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

-- generate infinity loader loaders
local loader_base = table.deepcopy(data.raw["underground-belt"]["underground-belt"])
loader_base.icons = {
  {icon = "__EditorExtensions__/graphics/item/infinity-loader.png", icon_size = 64, icon_mipmaps = 4}
}
for name, t in pairs(loader_base.structure) do
  if name ~= "back_patch" and name ~= "front_patch" then
    t.sheet.filename = "__EditorExtensions__/graphics/entity/infinity-loader/infinity-loader.png"
    t.sheet.hr_version.filename = "__EditorExtensions__/graphics/entity/infinity-loader/hr-infinity-loader.png"
  end
end
util.recursive_tint(loader_base)

local belt_patterns = {
  -- factorioextended plus transport: https://mods.factorio.com/mod/FactorioExtended-Plus-Transport
  ["%-?transport%-belt%-to%-ground"] = "",
  -- vanilla and 99% of mods
  ["%-?underground%-belt"] = ""
}

local function create_loader(base_underground)
  local entity = table.deepcopy(data.raw["underground-belt"][base_underground])
  -- adjust pictures and icon
  entity.structure = loader_base.structure
  entity.icons = loader_base.icons
  -- get name
  local suffix = entity.name
  for pattern,  replacement in pairs(belt_patterns) do
    suffix = string.gsub(suffix, pattern, replacement)
  end
  entity.name = "ee-infinity-loader-loader"..(suffix ~= "" and "-"..suffix or "")
  entity.localised_name = {"entity-name.ee-infinity-loader"}
  -- other data
  entity.type = "loader-1x1"
  entity.next_upgrade = nil
  entity.max_distance = 0
  entity.order = "a"
  entity.selectable_in_game = false
  entity.filter_count = 0
  entity.belt_length = 0.6
  entity.container_distance = 0
  entity.next_upgrade = nil
  table.insert(entity.flags, "not-upgradable")
  -- clean up unused data
  entity.icon = nil
  entity.icon_size = nil
  entity.icon_mipmaps = nil
  entity.max_distance = nil
  entity.underground_sprite = nil
  entity.underground_remove_belts_sprite = nil
  entity.structure.direction_in_side_loading = nil
  entity.structure.direction_out_side_loading = nil
  data:extend{entity}
end

for name in pairs(table.deepcopy(data.raw["underground-belt"])) do
  create_loader(name)
end