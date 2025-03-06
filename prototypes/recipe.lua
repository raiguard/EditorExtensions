local constants = require("prototypes.constants")

local recipe_names = {
  "ee-infinity-accumulator",
  "ee-infinity-cargo-wagon",
  "ee-infinity-fluid-wagon",
  "ee-infinity-fission-reactor-equipment",
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
        hidden_in_factoriopedia = true,
        ingredients = {},
        category = "ee-testing-tool",
        results = { { type = "item", name = k, amount = 1 } },
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
