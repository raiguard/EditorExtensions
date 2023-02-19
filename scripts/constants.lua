local table = require("__flib__/table")

--- @class Constants
local constants = {}

-- TEST SURFACE

constants.empty_map_gen_settings = {
  default_enable_all_autoplace_controls = false,
  property_expression_names = { cliffiness = 0 },
  autoplace_settings = {
    tile = { settings = { ["out-of-map"] = { frequency = "normal", size = "normal", richness = "normal" } } },
  },
  starting_area = "none",
}

constants.testing_lab_setting = {
  off = 1,
  personal = 2,
  shared = 3,
}

return constants
