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

local function destroy_box(player_table)
  player_table.linked_belt_box.destroy()
  player_table.linked_belt_box = nil
end

function linked_belt.check_is_linked_belt(entity)
  return string.find(entity.name, "ee%-linked%-belt")
end

function linked_belt.start_connection(player, player_table, entity, shift)
  local neighbour = entity.linked_belt_neighbour
  local source
  if neighbour then
    if shift then
      source = entity
    else
      source = neighbour
    end
  else
    source = entity
  end
  player_table.flags.connecting_linked_belts = true
  player_table.linked_belt_source = source
  -- TEMP
  player_table.linked_belt_box = source.surface.create_entity{
    name = "highlight-box",
    position = source.position,
    bounding_box = source.selection_box,
    box_type = "electricity",
    render_player_index = player.index,
    blink_interval = 30
  }
end

function linked_belt.finish_connection(player, player_table, entity, shift)
  local neighbour = entity.linked_belt_neighbour
  local source = player_table.linked_belt_source
  if entity.unit_number ~= source.unit_number and (shift or not neighbour) then
    if neighbour then
      linked_belt.sever_connection(entity)
    end
    entity.linked_belt_type = source.linked_belt_type == "input" and "output" or "input"
    entity.connect_linked_belts(source)
    player_table.flags.connecting_linked_belts = false
    player_table.linked_belt_source = nil
    destroy_box(player_table)
    linked_belt.render_connection(player, player_table, entity)
  else
    util.error_text(player, {"ee-message.cannot-connect"}, entity.position)
  end
end

function linked_belt.cancel_connection(player, player_table)
  player_table.flags.connecting_linked_belts = false
  player_table.linked_belt_source = nil
  destroy_box(player_table)
  if player_table.linked_belt_connection then
    rendering.destroy(player_table.linked_belt_connection)
    player_table.linked_belt_connection = nil
  end
end

function linked_belt.sever_connection(player, player_table, entity)
  entity.disconnect_linked_belts()
  linked_belt.render_connection(player, player_table, entity)
end

function linked_belt.render_connection(player, player_table, entity)
  if player_table.linked_belt_connection then
    rendering.destroy(player_table.linked_belt_connection)
  end
  local neighbour = entity.linked_belt_neighbour
  if neighbour then
    if entity.surface == neighbour.surface then
      player_table.linked_belt_connection = rendering.draw_line{
        color = {r = 0.5, g = 1, b = 0.5},
        width = 2,
        from = entity.position,
        to = neighbour.position,
        surface = entity.surface,
        players = {player.index}
      }
    else
    end
  end
end

return linked_belt