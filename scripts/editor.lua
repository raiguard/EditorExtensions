local util = require("__EditorExtensions__/scripts/util")

local editor_gui_width = 474

--- @param player LuaPlayer
--- @return boolean
local function se_check_in_spaceship(player)
  local se_interface = remote.interfaces["space-exploration"]
  if not se_interface or not se_interface.get_surface_type then
    return false
  end
  local surface_type = remote.call("space-exploration", "get_surface_type", { surface_index = player.surface_index })
  return surface_type == "spaceship"
end

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
    player.print({ "message.ee-cannot-use-map-editor" })
    return
  end

  local lab_setting = player.mod_settings["ee-testing-lab"].value
  if lab_setting ~= "off" and se_check_in_spaceship(player) then
    player.print({ "message.ee-cannot-use-testing-lab-spaceship" })
    return
  end

  player.toggle_map_editor()
end

--- @param e EventData.on_player_toggled_map_editor
local function on_player_toggled_map_editor(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  player.set_shortcut_toggled("ee-toggle-map-editor", player.controller_type == defines.controllers.editor)

  local in_editor = player.controller_type == defines.controllers.editor
  local margin = in_editor and editor_gui_width or 0
  player.gui.top.style.left_margin = margin
  player.gui.left.style.left_margin = margin

  if global.editor_toggled or not game.tick_paused then
    return
  end
  global.editor_toggled = true
  if game.tick_paused and settings.global["ee-prevent-initial-pause"].value then
    game.tick_paused = false
  end
end

--- @param e EventData.on_player_created
local function on_player_created(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  util.player_can_use_editor(player)

  if player.mod_settings["ee-auto-alt-mode"].value then
    local game_view_settings = player.game_view_settings
    game_view_settings.show_entity_info = true
    player.game_view_settings = game_view_settings
  end

  if not util.in_debug_world() and not util.in_testing_scenario() then
    player.print({ "message.ee-welcome" })
  end
end

--- @param e EventData.on_permission_group_edited
local function on_permission_group_edited(e)
  if string.find(e.type, "permission") and e.action ~= defines.input_action.toggle_map_editor then
    return
  end
  for _, player in pairs(e.group.players) do
    util.player_can_use_editor(player)
  end
end

--- @class SERemoteViewToggledEventData: EventData
--- @field player_index uint

local function register_se_events()
  local se = remote.interfaces["space-exploration"]
  if not se then
    return
  end
  if se.get_on_remote_view_started_event then
    script.on_event(remote.call("space-exploration", "get_on_remote_view_started_event"), function(e)
      --- @cast e SERemoteViewToggledEventData
      game.get_player(e.player_index).set_shortcut_available("ee-toggle-map-editor", false)
    end)
  end
  if se.get_on_remote_view_stopped_event then
    script.on_event(remote.call("space-exploration", "get_on_remote_view_stopped_event"), function(e)
      --- @cast e SERemoteViewToggledEventData
      util.player_can_use_editor(game.get_player(e.player_index) --[[@as LuaPlayer]])
    end)
  end
end

local editor = {}

editor.on_init = function()
  for player_index in pairs(game.players) do
    --- @cast player_index uint
    on_player_created({ player_index = player_index })
  end
  register_se_events()
end

editor.on_load = register_se_events

editor.on_configuration_changed = function()
  for _, player in pairs(game.players) do
    util.player_can_use_editor(player)
  end
end

editor.events = {
  [defines.events.on_lua_shortcut] = on_toggle_editor,
  [defines.events.on_permission_group_edited] = on_permission_group_edited,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_toggled_map_editor] = on_player_toggled_map_editor,
  ["ee-toggle-map-editor"] = on_toggle_editor,
}

return editor
