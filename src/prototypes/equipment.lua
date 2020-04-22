-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EQUIPMENT

local util = require("prototypes.util")

-- infinity personal fusion reactor
data:extend{
  {
    type = "movement-bonus-equipment",
    name = "ee-infinity-exoskeleton-equipment",
    sprite = {
      filename = "__base__/graphics/equipment/exoskeleton-equipment.png",
      width = 64,
      height = 128,
      priority = "medium",
      tint = util.infinity_tint
    },
    background_color = util.equipment_background_color,
    shape = {width=1, height=1, type="full"},
    energy_source = {type="electric", usage_priority="secondary-input"},
    energy_consumption = "200kW",
    movement_bonus = 2,
    categories = {"armor"}
  },
  {
    type = "generator-equipment",
    name = "ee-infinity-fusion-reactor-equipment",
    sprite = {
      filename = "__base__/graphics/equipment/fusion-reactor-equipment.png",
      width = 128,
      height = 128,
      priority = "medium",
      tint = util.infinity_tint
    },
    background_color = util.equipment_background_color,
    shape = {width=1, height=1, type="full"},
    energy_source = {type="electric", usage_priority="primary-output"},
    power = "1000YW",
    categories = {"armor"},
    flags = {"hidden"}
  }
}

local personal_roboport = table.deepcopy(data.raw["roboport-equipment"]["personal-roboport-mk2-equipment"])
personal_roboport.name = "ee-infinity-personal-roboport-equipment"
personal_roboport.background_color = util.equipment_background_color
personal_roboport.shape = {width=1, height=1, type="full"}
personal_roboport.sprite = personal_roboport.sprite
personal_roboport.sprite.tint = util.equipment_background_color
personal_roboport.charging_energy = "1000GJ"
personal_roboport.charging_station_count = 1000
personal_roboport.robot_limit = 1000
personal_roboport.construction_radius = 100
personal_roboport.take_result = "ee-infinity-personal-roboport-equipment"
personal_roboport.flags = {"hidden"}
data:extend{personal_roboport}