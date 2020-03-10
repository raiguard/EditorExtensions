-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RECIPES
-- For use in cheat mode so you can use the tools outside of the editor

local util = require('prototypes.util')

local recipe_names = {
  'ee-infinity-accumulator',
  'ee-infinity-beacon',
  'ee-infinity-cargo-wagon',
  'ee-infinity-combinator',
  'ee-infinity-construction-robot',
  'ee-infinity-electric-pole',
  'ee-infinity-exoskeleton-equipment',
  'ee-infinity-fluid-wagon',
  'ee-infinity-fuel',
  'ee-infinity-fusion-reactor-equipment',
  'ee-infinity-heat-pipe',
  'ee-infinity-inserter',
  'ee-infinity-lab',
  'ee-infinity-loader',
  'ee-infinity-locomotive',
  'ee-infinity-logistic-robot',
  'ee-infinity-personal-roboport-equipment',
  'ee-infinity-pipe',
  'ee-infinity-pump',
  'ee-infinity-radar',
  'ee-infinity-roboport',
  'ee-infinity-substation',
}
local function register_recipes(t)
  for _,k in ipairs(t) do
    data:extend{
      {
        type = 'recipe',
        name = k,
        ingredients = {},
        enabled = false,
        result = k
      }
    }
  end
end

register_recipes(recipe_names)
for _,t in pairs(util.infinity_chest_data) do
  register_recipes{'ee-infinity-chest'..(t.lm and '-'..t.lm or '')}
end
for _,t in pairs(util.tesseract_chest_data) do
  register_recipes{'ee-tesseract-chest'..(t.lm and '-'..t.lm or '')}
end
for _,t in ipairs(util.module_data) do
  register_recipes{t.name}
end