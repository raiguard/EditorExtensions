local global_data = {}

function global_data.init()
  global.flags = {
    in_testing_scenario = remote.interfaces["EditorExtensions_TestingScenario"] and true or false,
    map_editor_toggled = false
  }
  global.players = {}
  global.wagons = {}
end

return global_data