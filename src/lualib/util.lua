local math2d = require('__core__/lualib/math2d')
local util = require('__core__/lualib/util')

-- returns true if the table contains the specified value
function table.contains(table, value)
  for k,v in pairs(table) do
    if v == value then
      return true
    end
  end
  return false
end

table.merge = util.merge

-- flips a table's keys with its values
function table.invert(table)
  local new_table = {}
  for k,v in pairs(table) do
    new_table[v] = k
  end
  return new_table
end

-- GENERAL

-- returns the player and his global table
function util.get_player(obj)
  if type(obj) == 'number' then return game.players[obj], global.players[obj] -- gave the player_index itself
  elseif obj.__self then return game.players[obj.index], global.players[obj.index] -- gave a player object
  else return game.players[obj.player_index], global.players[obj.player_index] end -- gave the event table
end

-- just returns the player table
function util.player_table(obj)
  if type(obj) == 'number' then return global.players[obj] -- gave the player_index itself
  elseif obj.__self then return global.players[obj.index] -- gave a player object
  else return global.players[obj.player_index] end -- gave the event table
end

util.constants = {
  -- commonly-used set of events for when an entity is built
  entity_built_events = {
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive
  },
  -- commonly-used set of events for when an entity is destroyed
  entity_destroyed_events = {
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_entity_died,
    defines.events.script_raised_destroy
  },
  -- close button for frames, as defined in the titlebar submodule
  close_button_def = {
    name = 'close',
    sprite = 'utility/close_white',
    hovered_sprite = 'utility/close_black',
    clicked_sprite = 'utility/close_black'
  }
}

util.area = math2d.bounding_box

-- utilities for prototype creation
util.data = {
  empty_circuit_wire_connection_points = {
    {wire={},shadow={}},
    {wire={},shadow={}},
    {wire={},shadow={}},
    {wire={},shadow={}}
  },
  empty_sheet = {
    filename = '__core__/graphics/empty.png',
    priority = 'very-low',
    width = 1,
    height = 1,
    frame_count = 1
  }
}

util.entity = {}

-- apply the function to each belt neighbor connected to this entity, and return entities for which the function returned true
function util.entity.check_belt_neighbors(entity, func, type_agnostic)
  local belt_neighbors = entity.belt_neighbours
  local matched_entities = {}
  for _,type in pairs{'inputs', 'outputs'} do
    if not type_agnostic then matched_entities[type] = {} end
    for _,e in ipairs(belt_neighbors[type] or {}) do
      if func(e) then
        table.insert(type_agnostic and matched_entities or matched_entities[type], e)
      end
    end
  end
  return matched_entities
end

-- apply the function to each entity on neighboring tiles, returning entities for which the function returned true
function util.entity.check_tile_neighbors(entity, func, eight_way, dir_agnostic)
  local matched_entities = {}
  for i=0,7,eight_way and 1 or 2 do
    if not dir_agnostic then matched_entities[i] = {} end
    local entities = entity.surface.find_entities(util.position.to_tile_area(util.position.add(entity.position, util.direction.to_vector(i, 1))))
    for _,e in ipairs(entities) do
      if func(e) then
        table.insert(dir_agnostic and matched_entities or matched_entities[i], e)
      end
    end
  end
  return matched_entities
end

util.direction = {}
util.direction.opposite = util.oppositedirection

-- borrowed from STDLIB: returns the next or previous direction
function util.direction.next(direction, reverse, eight_way)
  return (direction + (eight_way and ((reverse and -1) or 1) or ((reverse and -2) or 2))) % 8
end

-- gets a vector based on a cardinal direction
function util.direction.to_vector(direction, longitudinal, orthogonal)
  orthogonal = orthogonal or 0
  if direction == defines.direction.north then
    return {x=orthogonal, y=-longitudinal}
  elseif direction == defines.direction.south then
    return {x=-orthogonal, y=longitudinal}
  elseif direction == defines.direction.east then
    return {x=longitudinal, y=orthogonal}
  elseif direction == defines.direction.west then
    return {x=-longitudinal, y=-orthogonal}
  end
end

util.gui = {}

function util.gui.add_pusher(parent, name, vertical)
  if vertical then
    return parent.add{type='empty-widget', name=name, style='ee_invisible_vertical_pusher'}
  else
    return parent.add{type='empty-widget', name=name, style='ee_invisible_horizontal_pusher'}
  end
end

-- simple logging function - prints the string or table to the dev console or the ingame console
function util.log(message, print_to_game, serpent_options)
  local func = print_to_game and game.print or log
  if type(message) == 'table' then
    func('\n'..serpent.block(message, serpent_options))
  else
    func(message)
  end
end

util.position = math2d.position

-- creates an area that is the tile the position is contained in
function util.position.to_tile_area(pos)
  return {
    left_top = {x=math.floor(pos.x), y=math.floor(pos.y)},
    right_bottom = {x=math.ceil(pos.x), y=math.ceil(pos.y)}
  }
end

util.textfield = {}

-- clamps numeric textfields to between two values, and sets the textfield style if it is invalid
function util.textfield.clamp_number_input(element, clamps, last_value)
  local text = element.text
  if text == ''
  or (clamps[1] and tonumber(text) < clamps[1])
  or (clamps[2] and tonumber(text) > clamps[2]) then
    element.style = 'ee_invalid_slider_textfield'
  else
    element.style = 'ee_slider_textfield'
    last_value = text
  end
  return last_value
end

-- sets the numeric textfield to the last valid value and resets the style
function util.textfield.set_last_valid_value(element, last_value)
  if element.text ~= last_value then
    element.text = last_value
    element.style = 'ee_slider_textfield'
  end
  return element.text
end

return util