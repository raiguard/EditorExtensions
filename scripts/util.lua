local constants = require("__EditorExtensions__/scripts/constants")

--- @class Util
local util = {}

local coreutil = require("__core__/lualib/util")
util.parse_energy = coreutil.parse_energy

function util.add_cursor_enhancements_overrides()
	if
		remote.interfaces["CursorEnhancements"]
		and remote.call("CursorEnhancements", "version") == constants.cursor_enhancements_interface_version
	then
		remote.call("CursorEnhancements", "add_overrides", constants.cursor_enhancements_overrides)
	end
end

--- @param handler GuiElemHandler
function util.close_button(handler)
	return {
		type = "sprite-button",
		style = "frame_action_button",
		sprite = "utility/close_white",
		hovered_sprite = "utility/close_black",
		clicked_sprite = "utility/close_black",
		tooltip = { "gui.close-instruction" },
		mouse_button_filter = { "left" },
		handler = { [defines.events.on_gui_click] = handler },
	}
end

--- @param mode InfinityPipeMode
--- @return GuiElemDef
function util.mode_radio_button(mode)
	return {
		type = "radiobutton",
		name = "mode_radio_button_" .. string.gsub(mode, "%-", "_"),
		caption = { "gui-infinity-container." .. mode },
		tooltip = { "gui-infinity-pipe." .. mode .. "-tooltip" },
		state = false,
		tags = { mode = mode },
		actions = {
			on_checked_state_changed = { gui = "infinity_pipe", action = "change_amount_mode", mode = mode },
		},
	}
end

function util.pusher()
	return { type = "empty-widget", style = "flib_horizontal_pusher", ignored_by_interaction = true }
end

--- @param player LuaPlayer
--- @param message LocalisedString
--- @param play_sound boolean?
--- @param position MapPosition?
function util.flying_text(player, message, play_sound, position)
	player.create_local_flying_text({
		text = message,
		create_at_cursor = not position,
		position = position,
	})
	if play_sound then
		player.play_sound({ path = "utility/cannot_build" })
	end
end

--- @param player LuaPlayer
--- @return boolean
function util.player_can_use_editor(player)
	local can_use_editor = player.admin
	local permission_group = player.permission_group
	if permission_group then
		can_use_editor = permission_group.allows_action(defines.input_action.toggle_map_editor)
	end
	player.set_shortcut_available("ee-toggle-map-editor", can_use_editor)
	return can_use_editor
end

--- @param e EventData.on_player_setup_blueprint
--- @return LuaItemStack?
function util.get_blueprint(e)
	local player = game.get_player(e.player_index)
	if not player then
		return
	end

	local bp = player.blueprint_to_setup
	if bp and bp.valid_for_read then
		return bp
	end

	bp = player.cursor_stack
	if not bp or not bp.valid_for_read then
		return
	end

	if bp.type == "blueprint-book" then
		local item_inventory = bp.get_inventory(defines.inventory.item_main)
		if item_inventory then
			bp = item_inventory[bp.active_index]
		else
			return
		end
	end

	return bp
end

return util
