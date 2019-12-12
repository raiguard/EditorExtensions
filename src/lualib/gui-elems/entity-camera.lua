local util = require('lualib/util')
local entity_camera = {}

function entity_camera.create(parent, name, size, data)
  local frame = parent.add {
    type = 'frame',
    name = name .. '_frame',
    style = 'inside_deep_frame'
  }

  local camera = frame.add {
    type = 'camera',
    name = name .. '_camera',
    position = util.position.add(data.entity.position, data.camera_offset or {0,0}),
    zoom = (data.camera_zoom or 1) * data.player.display_scale
  }

  if type(size) == 'table' then
    camera.style.width = size.x or size[1]
    camera.style.height = size.y or size[2]
  else
    camera.style.width = size
    camera.style.height = size
  end

  return camera
end

return entity_camera