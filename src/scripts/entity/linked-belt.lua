local util = require("scripts.util")

local linked_belt = {}

--[[
  INTERACTIONS
  Left click:
    - Not holding end:
      - No connection: Connect this end, put other end in cursor
      - Connection: Disconnect this end and put in cursor
    - Holding end:
      - No connection: Connect to other end
      - Connection: Error (flying text)
  Shift + left click:
    - Not holding end:
      - No connection: Connect this end, put other end in cursor
      - Connection: Disconnect other end and put it in the cursor
    - Holding end:
      - No connection: Connect to other end
      - Connection: Sever current connection, connect to other end
  Shift + right click:
    - Not holding end:
      - No connection: Error (flying text)
      - Connection: Sever current connection
    - Holding end:
      - No connection: Error (flying text)
      - Connection: Sever current connection
  Rotate:
    - No connection: toggle input/output on self
    - Connection: toggle input/output on both ends of the connection
  Snapping:
    - No connection: direction and belt type?
    - Connection: belt type only
]]

function linked_belt.check_is_linked_belt(entity)
  return string.find(entity.name, "ee%-linked%-belt")
end

function linked_belt.start_connection(player, player_table, entity, shift)
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
  player_table.flags.connecting_linked_belts = true
  player_table.linked_belt_source = source

  linked_belt.render_connection(player, player_table)
end

function linked_belt.finish_connection(player, player_table, entity, shift)
  local neighbour = entity.linked_belt_neighbour
  local source = player_table.linked_belt_source
  if entity.unit_number ~= source.unit_number and (shift or not neighbour) then
    if neighbour then
      linked_belt.sever_connection(player, player_table, entity)
    end
    entity.linked_belt_type = source.linked_belt_type == "input" and "output" or "input"
    entity.connect_linked_belts(source)
    player_table.flags.connecting_linked_belts = false
    player_table.linked_belt_source = nil
    linked_belt.render_connection(player, player_table)
  else
    util.error_text(player, {"ee-message.cannot-connect"}, entity.position)
  end
end

function linked_belt.cancel_connection(player, player_table)
  player_table.flags.connecting_linked_belts = false
  player_table.linked_belt_source = nil
  linked_belt.render_connection(player, player_table)
end

function linked_belt.sever_connection(player, player_table, entity)
  entity.disconnect_linked_belts()
  linked_belt.render_connection(player, player_table)
end

local function draw_connection(player_index, source, destination, color)
  if source.surface == destination.surface then
    return rendering.draw_line{
      color = color,
      width = 2,
      from = source.position,
      to = destination.position,
      surface = source.surface,
      players = {player_index}
    }
  else
  end
end

function linked_belt.render_connection(player, player_table)
  local objects = player_table.linked_belt_render_objects
  if objects then
    for i = 1, #objects do
      rendering.destroy(objects[i])
    end
  end
  player_table.linked_belt_render_objects = nil

  objects = {} -- new objects table

  local active_source = player_table.linked_belt_source
  if active_source then
    local neighbour = active_source.linked_belt_neighbour
    if neighbour then
      objects[#objects+1] = draw_connection(player.index, active_source, neighbour, {r = 1, g = 0.5, b = 0.5, a = 0.8})
    end
  end

  local selected = player.selected
  if selected and linked_belt.check_is_linked_belt(selected) then
    local neighbour = selected.linked_belt_neighbour
    if neighbour then
      objects[#objects+1] = draw_connection(player.index, selected, neighbour, {r = 0.5, g = 1, b = 0.5, a = 0.8})
    end
    if active_source then
      objects[#objects+1] = draw_connection(player.index, selected, active_source, {r = 0.5, g = 1, b = 1, a = 0.8})
    end
  end

  player_table.linked_belt_render_objects = objects
end

return linked_belt