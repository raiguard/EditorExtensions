local global_data = {}

function global_data.init()
  local in_testing_scenario = false
  if remote.interfaces["EditorExtensions_TestingScenario"] then
    in_testing_scenario = true
  end

  global.flags = {
    in_testing_scenario = in_testing_scenario,
    map_editor_toggled = false
  }
  global.players = {}
  global.wagons = {}
end

return global_data