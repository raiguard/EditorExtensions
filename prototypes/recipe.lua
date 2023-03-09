local constants = require("__EditorExtensions__/prototypes/constants")

local recipe_names = {
  "ee-infinity-accumulator",
  "ee-infinity-cargo-wagon",
  "ee-infinity-fluid-wagon",
  "ee-infinity-fusion-reactor-equipment",
  "ee-infinity-heat-pipe",
  "ee-infinity-loader",
  "ee-infinity-pipe",
  "ee-linked-belt",
  "ee-linked-chest",
  "ee-super-battery-equipment",
  "ee-super-beacon",
  "ee-super-construction-robot",
  "ee-super-electric-pole",
  "ee-super-energy-shield-equipment",
  "ee-super-exoskeleton-equipment",
  "ee-super-fuel",
  "ee-super-inserter",
  "ee-super-lab",
  "ee-super-locomotive",
  "ee-super-logistic-robot",
  "ee-super-night-vision-equipment",
  "ee-super-personal-roboport-equipment",
  "ee-super-pump",
  "ee-super-radar",
  "ee-super-roboport",
  "ee-super-substation",
}
local function register_recipes(t)
  for _, k in ipairs(t) do
    data:extend({
      {
        type = "recipe",
        name = k,
        ingredients = {},
        category = "ee-testing-tool",
        result = k,
        enabled = false,
      },
    })
  end
end

register_recipes(recipe_names)
for _, t in pairs(constants.infinity_chest_data) do
  register_recipes({ "ee-infinity-chest" .. (t.lm and "-" .. t.lm or "") })
end
for _, t in pairs(constants.aggregate_chest_data) do
  register_recipes({ "ee-aggregate-chest" .. (t.lm and "-" .. t.lm or "") })
end
for _, t in ipairs(constants.module_data) do
  register_recipes({ t.name })
end
