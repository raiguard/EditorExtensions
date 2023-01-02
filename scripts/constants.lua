local table = require("__flib__/table")

--- @class Constants
local constants = {}

-- CURSOR ENHANCEMENTS

constants.cursor_enhancements_interface_version = 1

constants.cursor_enhancements_overrides = {
	-- chests
	["ee-infinity-chest"] = "ee-infinity-chest-active-provider",
	["ee-infinity-chest-active-provider"] = "ee-infinity-chest-passive-provider",
	["ee-infinity-chest-passive-provider"] = "ee-infinity-chest-storage",
	["ee-infinity-chest-storage"] = "ee-infinity-chest-buffer",
	["ee-infinity-chest-buffer"] = "ee-infinity-chest-requester",
	["ee-infinity-chest-requester"] = "ee-aggregate-chest",
	["ee-aggregate-chest"] = "ee-aggregate-chest-passive-provider",
	-- electricity
	["ee-super-electric-pole"] = "ee-super-substation",
	["ee-super-substation"] = "ee-infinity-accumulator",
	-- trains
	["ee-super-locomotive"] = "ee-infinity-cargo-wagon",
	["ee-infinity-cargo-wagon"] = "ee-infinity-fluid-wagon",
}

-- INFINITY WAGON

constants.infinity_wagon_names = {
	["ee-infinity-cargo-wagon"] = true,
	["ee-infinity-fluid-wagon"] = true,
}

-- OTHER

constants.editor_gui_width = 474

-- SUPER PUMP

constants.sp_slider_to_temperature = {
	[0] = 0,
	[1] = 100,
	[2] = 200,
	[3] = 300,
	[4] = 400,
	[5] = 500,
	[6] = 600,
	[7] = 700,
	[8] = 800,
	[9] = 900,
	[10] = 1000,
	[11] = 2000,
	[12] = 3000,
	[13] = 4000,
	[14] = 5000,
	[15] = 6000,
	[16] = 7000,
	[17] = 8000,
	[18] = 9000,
	[19] = 10000,
	[20] = 15000,
	[21] = 20000,
	[22] = 25000,
	[23] = 30000,
}

constants.sp_temperature_to_slider = table.invert(constants.sp_slider_to_temperature)

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
