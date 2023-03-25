local util = require("__EditorExtensions__/scripts/util")

--- @param objects table
--- @param color Color
--- @param dashed boolean
--- @param player_index uint
--- @param source LuaEntity
--- @param destination LuaEntity?
local function draw_connection(objects, color, dashed, player_index, source, destination)
  for _, entity in pairs({ source, destination }) do
    objects[#objects + 1] = rendering.draw_circle({
      color = color,
      radius = 0.15,
      width = 2,
      filled = not dashed,
      target = entity.position,
      surface = entity.surface,
      players = { player_index },
    })
  end
  if destination and source.surface == destination.surface then
    objects[#objects + 1] = rendering.draw_line({
      color = color,
      width = 2,
      gap_length = dashed and 0.3 or 0,
      dash_length = dashed and 0.3 or 0,
      from = source.position,
      to = destination.position,
      surface = source.surface,
      players = { player_index },
    })
  end
end

--- @type table<string, Color>
local colors = {
  red = { r = 1, g = 0.5, b = 0.5 },
  green = { r = 0.3, g = 0.8, b = 0.3 },
  teal = { r = 0.5, g = 1, b = 1 },
}

--- @param player LuaPlayer
local function render_connection(player)
  local objects = global.linked_belt_render_objects[player.index] or {}
  for i = #objects, 1, -1 do
    rendering.destroy(objects[i])
    objects[i] = nil
  end

  local source = global.linked_belt_source[player.index]
  local selected = player.selected
  if selected and selected.name ~= "ee-linked-belt" then
    selected = nil
  end

  if selected then
    local neighbour = selected.linked_belt_neighbour
    if neighbour and neighbour ~= source then
      draw_connection(objects, colors.green, false, player.index, selected, neighbour)
    end
  end

  if source and source.valid then
    local neighbour = source.linked_belt_neighbour
    if neighbour then
      draw_connection(objects, colors.red, false, player.index, source, neighbour)
    end
    if selected and selected ~= neighbour then
      draw_connection(objects, colors.teal, true, player.index, source, selected)
    end
    draw_connection(objects, colors.teal, true, player.index, source)
  end

  if objects[1] then
    global.linked_belt_render_objects[player.index] = objects
  else
    global.linked_belt_render_objects[player.index] = nil
  end
end

--- @param player LuaPlayer
--- @param entity LuaEntity
--- @param shift boolean?
local function start_connection(player, entity, shift)
  local neighbour = entity.linked_belt_neighbour
  local source
  if neighbour then
    if shift then
      source = neighbour
    else
      source = entity
    end
  else
    source = entity
  end
  global.linked_belt_source[player.index] = source

  render_connection(player)
end

--- @param player LuaPlayer
--- @param entity LuaEntity
--- @param shift boolean?
local function finish_connection(player, entity, shift)
  local source = global.linked_belt_source[player.index]
  if not source or not source.valid then
    return
  end

  local neighbour = entity.linked_belt_neighbour
  if entity.unit_number == source.unit_number then
    return
  end
  if neighbour and not shift then
    util.flying_text(player, { "message.ee-connection-blocked" }, true, entity.position)
    return
  end
  if neighbour then
    entity.disconnect_linked_belts()
  end

  entity.linked_belt_type = source.linked_belt_type == "input" and "output" or "input"
  entity.connect_linked_belts(source)

  global.linked_belt_source[player.index] = nil

  render_connection(player)
end

--- @param player LuaPlayer
local function cancel_connection(player)
  local source = global.linked_belt_source[player.index]
  if not source then
    return
  end
  global.linked_belt_source[player.index] = nil
  render_connection(player)
end

--- @param e EventData.on_player_rotated_entity
local function on_player_rotated_entity(e)
  local entity = e.entity
  if not entity.valid or entity.name ~= "ee-linked-belt" then
    return
  end

  entity.direction = e.previous_direction

  local neighbour = entity.linked_belt_neighbour
  if neighbour then
    -- disconnect, flip both ends, reconnect
    entity.disconnect_linked_belts()
    entity.linked_belt_type = entity.linked_belt_type == "output" and "input" or "output"
    neighbour.linked_belt_type = neighbour.linked_belt_type == "output" and "input" or "output"
    entity.connect_linked_belts(neighbour)
  else
    entity.linked_belt_type = entity.linked_belt_type == "output" and "input" or "output"
  end
end

--- @param e EventData.on_selected_entity_changed
local function on_selected_entity_changed(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  render_connection(player)
end

--- @param e EventData.CustomInputEvent
local function on_clear_cursor(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  cancel_connection(player)
end

--- @param e EventData.CustomInputEvent
local function on_left_click(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  local selected = player.selected
  if not selected or selected.name ~= "ee-linked-belt" then
    return
  end

  local source = global.linked_belt_source[e.player_index]
  if source then
    finish_connection(player, selected)
  else
    start_connection(player, selected)
  end
end

--- @param e EventData.CustomInputEvent
local function on_shift_left_click(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  local selected = player.selected
  if not selected or selected.name ~= "ee-linked-belt" then
    return
  end

  local source = global.linked_belt_source[e.player_index]
  if source then
    finish_connection(player, selected, true)
  else
    start_connection(player, selected, true)
  end
end

--- @param e EventData.CustomInputEvent
local function on_shift_right_click(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  local selected = player.selected
  if not selected or selected.name ~= "ee-linked-belt" or not selected.linked_belt_neighbour then
    return
  end

  selected.disconnect_linked_belts()
  render_connection(player)
end

local linked_belt = {}

linked_belt.on_init = function()
  --- @type table<uint, LuaEntity>
  global.linked_belt_source = {}
  --- @type table<uint, uint64[]>
  global.linked_belt_render_objects = {}
end

linked_belt.events = {
  [defines.events.on_player_rotated_entity] = on_player_rotated_entity,
  [defines.events.on_selected_entity_changed] = on_selected_entity_changed,
  ["ee-linked-clear-cursor"] = on_clear_cursor,
  ["ee-linked-copy-entity-settings"] = on_shift_right_click,
  ["ee-linked-open-gui"] = on_left_click,
  ["ee-linked-paste-entity-settings"] = on_shift_left_click,
}

return linked_belt
