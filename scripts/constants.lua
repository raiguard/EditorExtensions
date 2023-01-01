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

-- INFINITY ACCUMULATOR

constants.ia = {}

constants.ia.index_to_mode = { "output", "input", "buffer" }
constants.ia.index_to_priority = { "primary", "secondary", "tertiary" }

constants.ia.localised_modes = { { "gui.ee-output" }, { "gui.ee-input" }, { "gui.ee-buffer" } }
constants.ia.localised_priorities = { { "gui.ee-primary" }, { "gui.ee-secondary" }, { "gui.ee-tertiary" } }
constants.ia.localised_si_suffixes_joule = {}
constants.ia.localised_si_suffixes_watt = {}

constants.ia.mode_to_index = { output = 1, input = 2, buffer = 3 }

constants.ia.power_prefixes = { "kilo", "mega", "giga", "tera", "peta", "exa", "zetta", "yotta" }
constants.ia.power_suffixes_by_mode = { output = "watt", input = "watt", buffer = "joule" }

constants.ia.priority_to_index = { primary = 1, secondary = 2, tertiary = 3 }

constants.ia.si_suffixes_joule = { "kJ", "MJ", "GJ", "TJ", "PJ", "EJ", "ZJ", "YJ" }
constants.ia.si_suffixes_watt = { "kW", "MW", "GW", "TW", "PW", "EW", "ZW", "YW" }

for i, v in pairs(constants.ia.power_prefixes) do
	constants.ia.localised_si_suffixes_watt[i] = { "", { "si-prefix-symbol-" .. v }, { "si-unit-symbol-watt" } }
	constants.ia.localised_si_suffixes_joule[i] = { "", { "si-prefix-symbol-" .. v }, { "si-unit-symbol-joule" } }
end

-- INFINITY PIPE

constants.ip_crafter_snapping_types = {
	["assembling-machine"] = true,
	["furnace"] = true,
	["rocket-silo"] = true,
}

constants.infinity_pipe_modes = {
	"at-least",
	"at-most",
	"exactly",
	"add",
	"remove",
}

constants.infinity_pipe_amount_type = {
	percent = 1,
	units = 2,
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
