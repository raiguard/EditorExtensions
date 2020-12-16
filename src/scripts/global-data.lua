local global_data = {}

function global_data.init()
  global.flags = {
    map_editor_toggled = false
  }
  global.linked_belt_sources = {}
  global.players = {}
  global.wagons = {}
end

return global_data