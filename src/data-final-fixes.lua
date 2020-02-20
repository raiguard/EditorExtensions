-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EDITOR EXTENSIONS PROTOTYPES - FINAL FIXES

local util = require('prototypes/util')

-- TESSERACT CHEST
local to_check = {
  'ammo',
  'armor',
  'blueprint',
  'blueprint-book',
  'capsule',
  'copy-paste-tool',
  'deconstruction-item',
  'gun',
  'item',
  'item-with-entity-data',
  'item-with-inventory',
  'item-with-label',
  'item-with-tags',
  'module',
  'rail-planner',
  'repair-tool',
  'selection-tool',
  'tool',
  'upgrade-item'
}
-- start with four extra slots to account for inserter interactions
local slot_count = 4
for _,n in pairs(to_check) do
  slot_count = slot_count + table_size(data.raw[n])
end
-- apply to tesseract chests
for _,p in pairs(data.raw['infinity-container']) do
  if p.name:find('tesseract') then
    -- set tesseract chest inventory size to the number of item prototypes
    p.inventory_size = slot_count
  end
end

-- INFINITY LAB
local lab = data.raw['lab']['infinity-lab']
-- fill this table with any future science pack names that don't match the pattern
local pattern_overrides = {}
local packs = {}
for _,p in pairs(data.raw['lab']) do
  for _, input in pairs(p.inputs) do
    packs[input] = true
  end
end
local over = {}
for p,_ in pairs(packs) do
  table.insert(over, p)
end
lab.inputs = over

-- INFINITY EQUIPMENT
-- allow equipment to be placed in all existing grid categories
local categories = {}
for _,t in pairs(data.raw['equipment-category']) do
  table.insert(categories, t.name)
end
data.raw['generator-equipment']['infinity-fusion-reactor-equipment'].categories = categories
data.raw['roboport-equipment']['infinity-personal-roboport-equipment'].categories = categories

-- MODULES
local modules = {
  'super-speed-module',
  'super-effectivity-module',
  'super-productivity-module',
  'super-clean-module',
  'super-slow-module',
  'super-ineffectivity-module',
  'super-dirty-module'
}
-- reset all modules to be able to be used in all recipes
for _,name in pairs(modules) do
  data.raw['module'][name].limitation = nil
end