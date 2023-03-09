local constants = {}

constants.aggregate_chest_data = {
  { t = { 255, 255, 225 }, o = "ba" },
  { lm = "passive-provider", t = { 255, 141, 114 }, o = "bb" },
}

constants.aggregate_chest_icon = {
  icon = "__EditorExtensions__/graphics/item/aggregate-chest.png",
  icon_size = 64,
  icon_mipmaps = 4,
}

constants.empty_circuit_wire_connection_points = {
  { wire = {}, shadow = {} },
  { wire = {}, shadow = {} },
  { wire = {}, shadow = {} },
  { wire = {}, shadow = {} },
}

constants.empty_sheet = {
  filename = "__core__/graphics/empty.png",
  priority = "very-low",
  width = 1,
  height = 1,
  frame_count = 1,
}

constants.equipment_background_color = { r = 0.5, g = 0.25, b = 0.5, a = 1 }
constants.equipment_background_color_hovered = { r = 0.6, g = 0.35, b = 0.6, a = 1 }

constants.infinity_accumulator_data = {
  {
    name = "primary-input",
    priority = "primary-input",
    render_no_power_icon = false,
  },
  {
    name = "primary-output",
    priority = "primary-output",
    render_no_power_icon = false,
  },
  {
    name = "secondary-input",
    priority = "secondary-input",
    render_no_power_icon = false,
  },
  {
    name = "secondary-output",
    priority = "secondary-output",
    render_no_power_icon = false,
  },
  {
    name = "tertiary-buffer",
    priority = "tertiary",
    render_no_power_icon = true,
  },
  {
    name = "tertiary-input",
    priority = "tertiary",
    render_no_power_icon = false,
  },
  {
    name = "tertiary-output",
    priority = "tertiary",
    render_no_power_icon = false,
  },
}

constants.infinity_chest_data = {
  { t = { 255, 255, 225 }, o = "aa" },
  { lm = "active-provider", t = { 218, 115, 255 }, o = "ab" },
  { lm = "passive-provider", t = { 255, 141, 114 }, o = "ac" },
  { lm = "storage", s = 1, t = { 255, 220, 113 }, o = "ad" },
  { lm = "buffer", t = { 114, 255, 135 }, o = "ae" },
  { lm = "requester", t = { 114, 236, 255 }, o = "af" },
}

constants.infinity_chest_icon = {
  icon = "__EditorExtensions__/graphics/item/infinity-chest.png",
  icon_size = 64,
  icon_mipmaps = 4,
}

constants.infinity_tint = { r = 1, g = 0.5, b = 1, a = 1 }

constants.linked_belt_tint = { r = 0.6, g = 1, b = 1, a = 1 }

constants.module_data = {
  {
    name = "ee-super-speed-module",
    icon_ref = "module-3",
    order = "ba",
    category = "speed",
    tier = 50,
    effect = { speed = { bonus = 2.5 } },
    tint = { r = 0.4, g = 0.6, b = 1 },
  },
  {
    name = "ee-super-effectivity-module",
    icon_ref = "module-3",
    order = "bb",
    category = "effectivity",
    tier = 50,
    effect = { consumption = { bonus = -2.5 } },
    tint = { r = 0.4, g = 1, b = 0.4 },
  },
  {
    name = "ee-super-productivity-module",
    icon_ref = "module-3",
    order = "bc",
    category = "productivity",
    tier = 50,
    effect = { productivity = { bonus = 2.5 } },
    tint = { r = 1, g = 0.4, b = 0.4 },
  },
  {
    name = "ee-super-clean-module",
    icon_ref = "module-3",
    order = "bd",
    category = "effectivity",
    tier = 50,
    effect = { pollution = { bonus = -2.5 } },
    tint = { r = 0.4, g = 1, b = 1 },
  },
  {
    name = "ee-super-slow-module",
    icon_ref = "module-1",
    order = "ca",
    category = "speed",
    tier = 50,
    effect = { speed = { bonus = -2.5 } },
    tint = { r = 0.4, g = 0.6, b = 1 },
  },
  {
    name = "ee-super-ineffectivity-module",
    icon_ref = "module-1",
    order = "cb",
    category = "effectivity",
    tier = 50,
    effect = { consumption = { bonus = 2.5 } },
    tint = { r = 0.4, g = 1, b = 0.4 },
  },
  {
    name = "ee-super-dirty-module",
    icon_ref = "module-1",
    order = "cc",
    category = "effectivity",
    tier = 50,
    effect = { pollution = { bonus = 2.5 } },
    tint = { r = 0.4, g = 1, b = 1 },
  },
}

return constants
