local recipe_names = {
  'infinity-accumulator',
  'infinity-beacon',
  'infinity-chest',
  'infinity-electric-pole',
  'infinity-fuel',
  'heat-interface',
  'infinity-inserter',
  'infinity-lab',
  'infinity-loader',
  'infinity-locomotive',
  'infinity-pipe',
  'infinity-substation',
  'infinity-pump',
  'infinity-radar',
  'infinity-roboport',
  'infinity-construction-robot',
  'infinity-logistic-robot',
  'infinity-cargo-wagon',
  'infinity-fluid-wagon',
  'tesseract-chest'
}
local function register_recipes(t)
  for _,k in ipairs(t) do
    data:extend{
      {
        type = 'recipe',
        name = 'ee_tool_'..k,
        ingredients = {},
        enabled = false,
        result = k
      }
    }
  end
end

register_recipes(recipe_names)
for lm,t in pairs(infinity_chest_data) do
  register_recipes{'infinity-chest-'..lm}
end
for lm,t in pairs(tesseract_chest_data) do
  if lm ~= '' then
    register_recipes{'tesseract-chest-'..lm}
  end
end
for _,t in ipairs(module_data) do
  register_recipes{t.name}
end