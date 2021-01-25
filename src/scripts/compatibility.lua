local compatibility = {}

local event = require("__flib__.event")

local constants = require("scripts.constants")
local infinity_loader = require("scripts.entity.infinity-loader")

function compatibility.add_cursor_enhancements_overrides()
  if
    remote.interfaces["CursorEnhancements"]
    and remote.call("CursorEnhancements", "version") == constants.cursor_enhancements_interface_version
  then
    remote.call("CursorEnhancements", "add_overrides", constants.cursor_enhancements_overrides)
  end
end

function compatibility.check_for_space_exploration()
  return script.active_mods["space-exploration"] and true or false
end

function compatibility.in_se_satellite_view(player)
  return compatibility.check_for_space_exploration() and player.controller_type == defines.controllers.god
end

function compatibility.check_for_testing_scenario()
  return remote.interfaces["EditorExtensions_TestingScenario"] and true or false
end

function compatibility.register_picker_dollies()
  if remote.interfaces["PickerDollies"] then
    event.register(remote.call("PickerDollies", "dolly_moved_entity_id"), infinity_loader.picker_dollies_move)
  end
end

return compatibility
