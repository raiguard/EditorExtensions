local math2d = require("__core__/lualib/math2d")
local util = require("__core__/lualib/util")

local constants = require("__EditorExtensions__/scripts/constants")

-- GENERAL

--- @param player LuaPlayer
function util.freeze_time_on_all_surfaces(player)
  player.print({ "ee-message.time-frozen" })
  for _, surface in pairs(game.surfaces) do
    surface.freeze_daytime = true
    surface.daytime = 0
  end
end

util.position = math2d.position

-- creates an area that is the tile the position is contained in
--- @param pos MapPosition
function util.position.to_tile_area(pos)
  return {
    left_top = { x = math.floor(pos.x), y = math.floor(pos.y) },
    right_bottom = { x = math.ceil(pos.x), y = math.ceil(pos.y) },
  }
end

--- @param entity LuaEntity
--- @return string
function util.get_belt_type(entity)
  local type = entity.type == "entity-ghost" and entity.ghost_name or entity.name
  for pattern, replacement in pairs(constants.belt_type_patterns) do
    type = string.gsub(type, pattern, replacement)
  end
  -- check to see if the loader prototype exists
  if type ~= "" and not game.entity_prototypes["ee-infinity-loader-" .. type] then
    -- print warning message
    game.print({ "", "EDITOR EXTENSIONS: ", { "ee-message.unable-to-identify-belt" } })
    game.print('entity_name = "' .. entity.name .. '", parse_result = "' .. type .. '"')
    -- set to default type
    type = global.fastest_belt_type
  end
  return type
end

function util.close_button(actions)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = "utility/close_white",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black",
    tooltip = { "gui.close-instruction" },
    mouse_button_filter = { "left" },
    actions = actions,
  }
end

--- @param player LuaPlayer
--- @param text LocalisedString
--- @position MapPosition?
function util.error_text(player, text, position)
  player.create_local_flying_text({
    text = text,
    position = position,
    create_at_cursor = not position and true or nil,
  })
  player.play_sound({ path = "utility/cannot_build" })
end

return util
