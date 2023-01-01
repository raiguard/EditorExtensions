local gui = require("__flib__/gui-lite")
local math = require("__flib__/math")

local constants = require("__EditorExtensions__/scripts/constants")
local util = require("__EditorExtensions__/scripts/util")

local entity_names = {
	["ee-infinity-accumulator-primary-input"] = true,
	["ee-infinity-accumulator-primary-output"] = true,
	["ee-infinity-accumulator-secondary-input"] = true,
	["ee-infinity-accumulator-secondary-output"] = true,
	["ee-infinity-accumulator-tertiary-buffer"] = true,
	["ee-infinity-accumulator-tertiary-input"] = true,
	["ee-infinity-accumulator-tertiary-output"] = true,
}

--- @alias InfinityAccumulatorMode
--- | "output"
--- | "input"
--- | "buffer"

--- @alias InfinityAccumulatorPriority
--- | "primary"
--- | "secondary"
--- | "tertiary"

--- @param name string
local function get_settings_from_name(name)
	local priority, mode = string.match(name, "^ee%-infinity%-accumulator%-(%a+)%-(%a+)$")
	return priority, mode
end

--- @param entity LuaEntity
--- @param mode string
--- @param buffer_size double?
local function set_entity_settings(entity, mode, buffer_size)
	local watts = util.parse_energy((buffer_size * 60) .. "W")

	if mode == "output" then
		entity.power_production = watts
		entity.power_usage = 0
		entity.electric_buffer_size = buffer_size
	elseif mode == "input" then
		entity.power_production = 0
		entity.power_usage = watts
		entity.electric_buffer_size = buffer_size
	elseif mode == "buffer" then
		entity.power_production = 0
		entity.power_usage = 0
		entity.electric_buffer_size = buffer_size * 60
	end
end

--- @param entity LuaEntity
--- @param priority string
--- @param mode string
--- @return LuaEntity?
local function change_entity(entity, priority, mode)
	local new_entity = entity.surface.create_entity({
		name = "ee-infinity-accumulator-" .. priority .. "-" .. mode,
		position = entity.position,
		force = entity.force,
		last_user = entity.last_user,
		create_build_effect_smoke = false,
	})
	if not new_entity then
		return
	end

	-- Calculate new buffer size
	local buffer_size = entity.electric_buffer_size
	local _, old_mode = get_settings_from_name(entity.name)
	if old_mode ~= mode and old_mode == "buffer" then
		-- coming from buffer, divide by 60
		buffer_size = buffer_size / 60
	end

	set_entity_settings(new_entity, mode, buffer_size)
	entity.destroy()

	return new_entity
end

--- Returns the slider value and dropdown selected index based on the entity's buffer size
local function calc_gui_values(buffer_size, mode)
	if mode ~= "buffer" then
		-- The slider is controlling watts, so inflate the buffer size by 60x to get that value
		buffer_size = buffer_size * 60
	end
	-- Determine how many orders of magnitude there are
	local len = string.len(string.format("%.0f", math.floor(buffer_size)))
	-- `power` is the dropdown value - how many sets of three orders of magnitude there are, rounded down
	local power = math.floor((len - 1) / 3)
	-- Slider value is the buffer size scaled to its base-three order of magnitude
	return math.floored(buffer_size / 10 ^ (power * 3), 0.001), math.max(power, 1)
end

--- Returns the entity buffer size based on the slider value and dropdown selected index
local function calc_buffer_size(slider_value, dropdown_index)
	return util.parse_energy(slider_value .. constants.ia.si_suffixes_joule[dropdown_index]) / 60
end

--- @param player LuaPlayer
local function destroy_gui(player)
	local pgui = global.infinity_accumulator_gui[player.index]
	if not pgui then
		return
	end
	global.infinity_accumulator_gui[player.index] = nil
	local window = pgui.elems.ee_infinity_accumulator
	if not window.valid then
		return
	end
	window.destroy()
end

--- @param e EventData.on_gui_closed|EventData.on_gui_click
local function on_close_ia_gui(e)
	local player = game.get_player(e.player_index)
	if not player then
		return
	end
	destroy_gui(player)
	player.play_sound({ path = "entity-close/ee-infinity-accumulator-tertiary-buffer" })
end

--- @param player LuaPlayer
--- @param entity LuaEntity
local function create_gui(player, entity)
	destroy_gui(player)

	local priority, mode = get_settings_from_name(entity.name)
	local slider_value, dropdown_index = calc_gui_values(entity.electric_buffer_size, mode)
	local elems = gui.add(player.gui.screen, {
		type = "frame",
		name = "ee_infinity_accumulator",
		direction = "vertical",
		elem_mods = { auto_center = true },
		handler = { [defines.events.on_gui_closed] = on_close_ia_gui },
		{
			type = "flow",
			style = "flib_titlebar_flow",
			drag_target = "ee_infinity_accumulator",
			{
				type = "label",
				style = "frame_title",
				caption = { "entity-name.ee-infinity-accumulator" },
				ignored_by_interaction = true,
			},
			{ type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
			util.close_button(on_close_ia_gui),
		},
		{
			type = "frame",
			style = "entity_frame",
			direction = "vertical",
			{
				type = "frame",
				style = "deep_frame_in_shallow_frame",
				{
					type = "entity-preview",
					name = "preview",
					style = "wide_entity_button",
					elem_mods = { entity = entity },
				},
			},
			{
				type = "flow",
				style_mods = { top_margin = 4, vertical_align = "center" },
				{ type = "label", caption = { "gui.ee-mode" } },
				{ type = "empty-widget", style = "flib_horizontal_pusher" },
				{
					type = "drop-down",
					name = "mode_dropdown",
					items = constants.ia.localised_modes,
					selected_index = constants.ia.mode_to_index[mode],
					-- actions = { on_selection_state_changed = { gui = "ia", action = "update_mode" } },
				},
			},
			{ type = "line", direction = "horizontal" },
			{
				type = "flow",
				style_mods = { vertical_align = "center" },
				{
					type = "label",
					caption = { "", { "gui.ee-priority" }, " [img=info]" },
					tooltip = { "gui.ee-ia-priority-description" },
				},
				{ type = "empty-widget", style = "flib_horizontal_pusher" },
				{
					type = "drop-down",
					name = "priority_dropdown",
					items = constants.ia.localised_priorities,
					selected_index = constants.ia.priority_to_index[priority],
					elem_mods = { enabled = mode ~= "buffer" },
					-- actions = {
					-- 	on_selection_state_changed = { gui = "ia", action = "update_priority" },
					-- },
				},
			},
			{ type = "line", direction = "horizontal" },
			{
				type = "flow",
				style_mods = { vertical_align = "center" },
				{
					type = "label",
					style_mods = { right_margin = 6 },
					caption = { "gui.ee-power" },
				},
				{
					type = "slider",
					name = "slider",
					style_mods = { horizontally_stretchable = true },
					minimum_value = 0,
					maximum_value = 999,
					value = slider_value,
					-- actions = { on_value_changed = { gui = "ia", action = "update_power_from_slider" } },
				},
				{
					type = "textfield",
					name = "slider_textfield",
					style = "ee_slider_textfield",
					text = slider_value,
					numeric = true,
					allow_decimal = true,
					lose_focus_on_confirm = true,
					clear_and_focus_on_right_click = true,
					-- actions = {
					-- 	on_confirmed = { gui = "ia", action = "confirm_textfield" },
					-- 	on_text_changed = { gui = "ia", action = "update_power_from_textfield" },
					-- },
				},
				{
					type = "drop-down",
					name = "slider_dropdown",
					style_mods = { width = 69 },
					selected_index = dropdown_index,
					items = constants.ia["localised_si_suffixes_" .. constants.ia.power_suffixes_by_mode[mode]],
					-- actions = {
					-- 	on_selection_state_changed = { gui = "ia", action = "update_units_of_measure" },
					-- },
				},
			},
		},
	})

	player.opened = elems.ee_infinity_accumulator

	--- @class InfinityAccumulatorGui
	global.infinity_accumulator_gui[player.index] = {
		elems = elems,
		entity = entity,
	}
end

--- @param e EventData.on_gui_opened
local function on_gui_opened(e)
	if e.gui_type ~= defines.gui_type.entity then
		return
	end
	local entity = e.entity
	if not entity or not entity.valid or not entity_names[entity.name] then
		return
	end
	local player = game.get_player(e.player_index)
	if not player then
		return
	end
	create_gui(player, entity)
end

local infinity_accumulator = {}

-- TODO: Close open GUIs
-- TODO: Sync GUI state with all open GUIs
-- TODO: Paste settings

infinity_accumulator.on_init = function()
	--- @type table<uint, InfinityAccumulatorGui>
	global.infinity_accumulator_gui = {}
end

infinity_accumulator.events = {
	[defines.events.on_gui_opened] = on_gui_opened,
}

gui.add_handlers({
	on_close_ia_gui = on_close_ia_gui,
})

return infinity_accumulator
