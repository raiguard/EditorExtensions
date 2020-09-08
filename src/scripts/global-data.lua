local global_data = {}

local compatibility = require("scripts.compatibility")

function global_data.init()
  global.flags = {
    in_testing_scenario = compatibility.check_for_testing_scenario(),
    map_editor_toggled = false
  }
  global.players = {}
  global.wagons = {}
end

return global_data