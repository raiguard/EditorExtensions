--- @class Util
local util = {}

local coreutil = require("__core__/lualib/util")
util.parse_energy = coreutil.parse_energy

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
--- @param handler GuiElemHandler
--- @return GuiElemDef
function util.mode_radio_button(mode, handler)
  return {
    type = "radiobutton",
    name = "mode_radio_button_" .. string.gsub(mode, "%-", "_"),
    caption = { "gui-infinity-container." .. mode },
    tooltip = { "gui-infinity-pipe." .. mode .. "-tooltip" },
    state = false,
    tags = { mode = mode },
    handler = { [defines.events.on_gui_checked_state_changed] = handler },
  }
end

function util.pusher()
  return { type = "empty-widget", style = "flib_horizontal_pusher", ignored_by_interaction = true }
end

--- @return boolean
function util.in_debug_world()
  if not settings.global["ee-override-debug-world"].value then
    return false
  end
  if script.level.mod_name ~= "base" or script.level.level_name ~= "freeplay" then
    return false
  end
  local nauvis = game.get_surface("nauvis")
  if not nauvis then
    return false
  end
  local mps = nauvis.map_gen_settings
  return mps.height == 50 and mps.width == 50
end

--- @return boolean
function util.in_testing_scenario()
  return script.level.mod_name == "EditorExtensions" and script.level.level_name == "testing"
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
--- @param to_state boolean?
--- @return boolean
function util.player_can_use_editor(player, to_state)
  local can_use_editor = to_state
  if can_use_editor == nil then
    local permission_group = player.permission_group
    if permission_group then
      can_use_editor = permission_group.allows_action(defines.input_action.toggle_map_editor)
      if not can_use_editor and player.controller_type == defines.controllers.editor then
        player.print({ "message.ee-cannot-use-map-editor" })
        -- XXX: We need to re-enable the capability in order to get them out of the editor
        permission_group.set_allows_action(defines.input_action.toggle_map_editor, true)
        player.toggle_map_editor()
        permission_group.set_allows_action(defines.input_action.toggle_map_editor, false)
      end
    end
  end
  player.set_shortcut_available("ee-toggle-map-editor", can_use_editor or false)
  return can_use_editor and player.admin or false
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
