local compatibility = {}

local event = require("__flib__.event")

local infinity_loader = require("scripts.entity.infinity-loader")

function compatibility.add_cursor_enhancements_overrides()
  if script.active_mods["CursorEnhancements"] then
    remote.call("CursorEnhancements", "add_overrides", {
      -- chests
      ["ee-infinity-chest"] = "ee-infinity-chest-active-provider",
      ["ee-infinity-chest-active-provider"] = "ee-infinity-chest-passive-provider",
      ["ee-infinity-chest-passive-provider"] = "ee-infinity-chest-storage",
      ["ee-infinity-chest-storage"] = "ee-infinity-chest-buffer",
      ["ee-infinity-chest-buffer"] = "ee-infinity-chest-requester",
      ["ee-aggregate-chest"] = "ee-aggregate-chest-passive-provider",
      -- electric poles
      ["ee-super-electric-pole"] = "ee-super-substation",
      -- trains
      ["ee-super-locomotive"] = "ee-infinity-cargo-wagon",
      ["ee-infinity-cargo-wagon"] = "ee-infinity-fluid-wagon"
    })
  end
end

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