local global_data = {}

function global_data.init()
  global.combinators = {}
  global.flags = {
    map_editor_toggled = false
  }
  global.players = {}
  global.wagons = {}
end

return global_data