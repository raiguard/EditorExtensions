local compatibility = {}

local event = require("__flib__.event")

local infinity_loader = require("scripts.entity.infinity-loader")

function compatibility.check_for_space_exploration()
  return script.active_mods["space-exploration"] and true or false
end

function compatibility.check_for_testing_scenario()
  return remote.interfaces["EditorExtensions_TestingScenario"] and true or false
end

function compatibility.register_picker_dollies()
  if script.active_mods["PickerDollies"] then
    event.register(remote.call("PickerDollies", "dolly_moved_entity_id"), infinity_loader.picker_dollies_move)
  end
end

return compatibility