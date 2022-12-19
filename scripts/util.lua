local flib_gui = require("__flib__/gui-lite")

--- @class Util
local util = {}

-- GENERAL

function util.close_button(actions)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = "utility/close_white",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black",
    tooltip = { "gui.close-instruction" },
    mouse_button_filter = { "left" },
    actions = actions,
  }
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

--- @param gui table
--- @param name string
--- @param wrapper function
function util.add_gui_handlers(gui, name, wrapper)
  local handlers = {}
  for key, val in pairs(gui) do
    if type(val) == "function" then
      handlers[name .. ":" .. key] = val
    end
  end
  flib_gui.add_handlers(handlers, wrapper)
end

return util
