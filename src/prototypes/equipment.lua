local constants = require("prototypes.constants")

local personal_battery = table.deepcopy(data.raw["battery-equipment"]["battery-equipment"])
personal_battery.name = "ee-super-battery-equipment"
personal_battery.background_color = constants.equipment_background_color
personal_battery.shape = {width = 1, height = 1, type = "full"}
personal_battery.sprite.tint = constants.infinity_tint
personal_battery.take_result = "ee-super-battery-equipment"
personal_battery.flags = {"hidden"}
personal_battery.energy_source.buffer_capacity = "1000YJ"
data:extend{personal_battery}

-- infinity personal fusion reactor
data:extend{
  {
    type = "movement-bonus-equipment",
    name = "ee-super-exoskeleton-equipment",
    sprite = {
      filename = "__base__/graphics/equipment/exoskeleton-equipment.png",
      width = 64,
      height = 128,
      priority = "medium",
      tint = constants.infinity_tint
    },
    background_color = constants.equipment_background_color,
    shape = {width = 1, height = 1, type = "full"},
    energy_source = {type = "electric", usage_priority = "secondary-input"},
    energy_consumption = "1kW",
    movement_bonus = 2,
    categories = {"armor"},
    flags = {"hidden"}
  },
  {
    type = "generator-equipment",
    name = "ee-infinity-fusion-reactor-equipment",
    sprite = {
      filename = "__base__/graphics/equipment/fusion-reactor-equipment.png",
      width = 128,
      height = 128,
      priority = "medium",
      tint = constants.infinity_tint
    },
    background_color = constants.equipment_background_color,
    shape = {width = 1, height = 1, type = "full"},
    energy_source = {type = "electric", usage_priority = "primary-output"},
    power = "1000YW",
    categories = {"armor"},
    flags = {"hidden"}
  }
}

local energy_shield = table.deepcopy(data.raw["energy-shield-equipment"]["energy-shield-equipment"])
energy_shield.name = "ee-super-energy-shield-equipment"
energy_shield.background_color = constants.equipment_background_color
energy_shield.sprite.tint = constants.infinity_tint
energy_shield.shape = {width = 1, height = 1, type = "full"}
energy_shield.max_shield_value = 1000000
energy_shield.energy_source = {
  type = "electric",
  usage_priority = "primary-input",
  input_flow_limit = "100YW",
  buffer_capacity = "100YJ"
}
energy_shield.take_result = "ee-super-energy-shield-equipment"
energy_shield.flags = {"hidden"}
data:extend{energy_shield}

local night_vision = table.deepcopy(data.raw["night-vision-equipment"]["night-vision-equipment"])
night_vision.name = "ee-super-night-vision-equipment"
night_vision.background_color = constants.equipment_background_color
night_vision.sprite.tint = constants.infinity_tint
night_vision.shape = {width = 1, height = 1, type = "full"}
night_vision.darkness_to_turn_on = 0
night_vision.color_lookup = {{0.5, "__core__/graphics/color_luts/identity-lut.png"}}
night_vision.take_result = "ee-super-night-vision-equipment"
night_vision.flags = {"hidden"}
data:extend{night_vision}

local personal_roboport = table.deepcopy(data.raw["roboport-equipment"]["personal-roboport-mk2-equipment"])
personal_roboport.name = "ee-super-personal-roboport-equipment"
personal_roboport.background_color = constants.equipment_background_color
personal_roboport.shape = {width = 1, height = 1, type = "full"}
personal_roboport.sprite.tint = constants.infinity_tint
personal_roboport.charging_energy = "1000GJ"
personal_roboport.charging_station_count = 1000
personal_roboport.robot_limit = 1000
personal_roboport.construction_radius = 100
personal_roboport.energy_source = {
  type = "electric",
  usage_priority = "secondary-input",
  buffer_capacity = "100YJ",
  input_flow_limit = "100YW"
}
personal_roboport.take_result = "ee-super-personal-roboport-equipment"
personal_roboport.flags = {"hidden"}
data:extend{personal_roboport}
