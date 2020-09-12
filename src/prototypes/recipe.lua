local constants = require("prototypes.constants")
local util = require("prototypes.util")

local recipe_names = {
  "ee-infinity-accumulator",
  "ee-super-beacon",
  "ee-infinity-cargo-wagon",
  "ee-super-construction-robot",
  "ee-super-electric-pole",
  "ee-super-energy-shield-equipment",
  "ee-super-exoskeleton-equipment",
  "ee-infinity-fluid-wagon",
  "ee-super-fuel",
  "ee-infinity-fusion-reactor-equipment",
  "ee-infinity-heat-pipe",
  "ee-super-inserter",
  "ee-super-lab",
  "ee-infinity-loader",
  "ee-super-locomotive",
  "ee-super-logistic-robot",
  "ee-super-personal-roboport-equipment",
  "ee-infinity-pipe",
  "ee-super-pump",
  "ee-super-radar",
  "ee-super-roboport",
  "ee-super-substation",
  "ee-super-night-vision-equipment"
}
local function register_recipes(t)
  for _, k in ipairs(t) do
    data:extend{
      {
        type = "recipe",
        name = k,
        ingredients = {},
        category = "ee-testing-tool",
        enabled = false,
        result = k
      }
    }
  end
end

register_recipes(recipe_names)
for _, t in pairs(constants.infinity_chest_data) do
  register_recipes{"ee-infinity-chest"..(t.lm and "-"..t.lm or "")}
end
for _, t in pairs(constants.aggregate_chest_data) do
  register_recipes{"ee-aggregate-chest"..(t.lm and "-"..t.lm or "")}
end
for _, t in ipairs(constants.module_data) do
  register_recipes{t.name}
end