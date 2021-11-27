local global_data = {}

function global_data.init()
  global.flags = {
    in_debug_world = false,
    map_editor_toggled = false,
  }
  global.linked_belt_sources = {}
  global.players = {}
  global.wagons = {}
end

function global_data.read_fastest_belt_type()
  local fastest_speed = 0
  local fastest_suffix = ""
  for name, prototype in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "loader-1x1" } })) do
    if string.find(name, "ee%-infinity%-loader%-loader") and prototype.belt_speed > fastest_speed then
      fastest_speed = prototype.belt_speed
      fastest_suffix = string.gsub(name, "ee%-infinity%-loader%-loader%-?", "")
    end
  end

  global.fastest_belt_type = fastest_suffix
end

return global_data
