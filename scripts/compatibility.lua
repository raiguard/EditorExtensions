--- @class Compatibility
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

return compatibility
