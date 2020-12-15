local direction = require("__flib__.direction")
local math2d = require("__core__.lualib.math2d")
local util = require("__core__.lualib.util")

local constants = require("scripts.constants")

-- GENERAL

function util.freeze_time_on_all_surfaces(player)
  player.print{"ee-message.time-frozen"}
  for _, surface in pairs(game.surfaces) do
    surface.freeze_daytime = true
    surface.daytime = 0
  end
end

util.position = math2d.position

-- creates an area that is the tile the position is contained in
function util.position.to_tile_area(pos)
  return {
    left_top = {x = math.floor(pos.x), y = math.floor(pos.y)},
    right_bottom = {x = math.ceil(pos.x), y = math.ceil(pos.y)}
  }
end

function util.get_belt_type(entity)
  local type = entity.name
  for pattern, replacement in pairs(constants.belt_type_patterns) do
    type = string.gsub(type, pattern, replacement)
  end
  -- check to see if the loader prototype exists
  if type ~= "" and not game.entity_prototypes["ee-infinity-loader-loader-"..type] then
    -- print warning message
    game.print{"", "EDITOR EXTENSIONS: ", {"ee-message.unable-to-identify-belt"}}
    game.print("entity_name = \""..entity.name.."\", parse_result = \""..type.."\"")
    -- set to default type
    type = "express"
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
    mouse_button_filter = {"left"},
    actions = actions
  }
end

function util.error_text(player, text, position)
  player.create_local_flying_text{
    text = text,
    position = position,
    create_at_cursor = (not position) and true or nil
  }
  player.play_sound{path = "utility/cannot_build"}
end

-- SNAPPING

-- apply the function to each belt neighbor connected to this entity, and return entities that the callback matched
function util.check_belt_neighbors(entity, func, type_agnostic)
  local belt_neighbors = entity.belt_neighbours
  local matched_entities = {}
  for _, type in pairs{"inputs", "outputs"} do
    if not type_agnostic then matched_entities[type] = {} end
    for _, e in ipairs(belt_neighbors[type] or {}) do
      if func(e) then
        table.insert(type_agnostic and matched_entities or matched_entities[type], e)
      end
    end
  end
  return matched_entities
end

-- apply the function to each entity on neighboring tiles, returning entities that the callback matched
function util.check_tile_neighbors(entity, func, eight_way, direction_agnostic)
  local matched_entities = {}
  for i = 0, 7, eight_way and 1 or 2 do
    if not direction_agnostic then matched_entities[i] = {} end
    local entities = entity.surface.find_entities(
      util.position.to_tile_area(util.position.add(entity.position, direction.to_vector(i, 1)))
    )
    for _, e in ipairs(entities) do
      if func(e) then
        table.insert(direction_agnostic and matched_entities or matched_entities[i], e)
      end
    end
  end
  return matched_entities
end

return util