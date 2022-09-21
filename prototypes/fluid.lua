data:extend({
  {
    type = "fluid",
    name = "ee-super-pump-speed-fluid",
    icons = {
      { icon = "__core__/graphics/cancel.png", icon_size = 64 },
    },
    heat_capacity = "1J",
    base_color = { 1, 1, 1 },
    flow_color = { 1, 1, 1 },
    hidden = true,
    max_temperature = math.huge,
    default_temperature = 0, -- follow up on default pump speed
    auto_barrel = false,
  },
})
