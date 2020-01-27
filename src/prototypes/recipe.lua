-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RECIPES
-- For use in cheat mode so you can use the tools outside of the editor

local util = require('prototypes/util')

local recipe_names = {
  'heat-interface',
  'infinity-accumulator',
  'infinity-beacon',
  'infinity-cargo-wagon',
  'infinity-chest',
  'infinity-combinator',
  'infinity-construction-robot',
  'infinity-electric-pole',
  'infinity-exoskeleton-equipment',
  'infinity-fluid-wagon',
  'infinity-fuel',
  'infinity-fusion-reactor-equipment',
  'infinity-inserter',
  'infinity-lab',
  'infinity-loader',
  'infinity-locomotive',
  'infinity-logistic-robot',
  'infinity-personal-roboport-equipment',
  'infinity-pipe',
  'infinity-pump',
  'infinity-radar',
  'infinity-roboport',
  'infinity-substation',
  'tesseract-chest'
}
local function register_recipes(t)
  for _,k in ipairs(t) do
    data:extend{
      {
        type = 'recipe',
        name = 'ee-'..k,
        ingredients = {},
        enabled = false,
        result = k
      }
    }
  end
end

register_recipes(recipe_names)
for lm,t in pairs(util.infinity_chest_data) do
  register_recipes{'infinity-chest-'..lm}
end
for lm,t in pairs(util.tesseract_chest_data) do
  if lm ~= '' then
      register_recipes{'tesseract-chest-'..lm}
  end
end
for _,t in ipairs(util.module_data) do
  register_recipes{t.name}
end