--- @param e EventData.CustomInputEvent|EventData.on_lua_shortcut
local function on_toggle_editor(e)
	local input = e.prototype_name or e.input_name
	if input ~= "ee-toggle-map-editor" then
		return
	end

	local player = game.get_player(e.player_index)
	if not player then
		return
	end

	local group = player.permission_group
	if not player.admin or (group and not group.allows_action(defines.input_action.toggle_map_editor)) then
		player.print({ "message.ee-editor-denied-not-admin" })
		return
	end

	player.toggle_map_editor()
end

local function on_player_toggled_map_editor()
	if global.editor_toggled or not game.tick_paused then
		return
	end
	global.editor_toggled = true
	if game.tick_paused and settings.global["ee-prevent-initial-pause"].value then
		game.tick_paused = false
	end
end

local editor = {}

editor.events = {
	[defines.events.on_lua_shortcut] = on_toggle_editor,
	[defines.events.on_player_toggled_map_editor] = on_player_toggled_map_editor,
	["ee-toggle-map-editor"] = on_toggle_editor,
}

return editor
