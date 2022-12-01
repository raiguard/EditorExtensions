local compatibility = {}

local constants = require("__EditorExtensions__/scripts/constants")

function compatibility.add_cursor_enhancements_overrides()
  if
    remote.interfaces["CursorEnhancements"]
    and remote.call("CursorEnhancements", "version") == constants.cursor_enhancements_interface_version
  then
    remote.call("CursorEnhancements", "add_overrides", constants.cursor_enhancements_overrides)
  end
end

--- @param player LuaPlayer
function compatibility.in_qis_window(player)
  local opened = player.opened
  if
    opened
    and player.opened_gui_type == defines.gui_type.custom
    and string.find(opened.name --[[@as string]], "^qis")
  then
    return true
  end
  return false
end

return compatibility
