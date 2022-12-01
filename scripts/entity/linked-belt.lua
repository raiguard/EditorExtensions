local util = require("__EditorExtensions__/scripts/util")

local linked_belt = {}

function linked_belt.init()
  --- @type table<uint, table<uint, boolean>>
  global.linked_belt_sources = {}
end

--- @param player LuaPlayer
--- @param player_table PlayerTable
--- @param entity LuaEntity
--- @param shift boolean?
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

  local source_players = global.linked_belt_sources[source.unit_number] or {}
  source_players[player.index] = true
  global.linked_belt_sources[source.unit_number] = source_players

  linked_belt.render_connection(player, player_table)
end

--- @param player LuaPlayer
--- @param player_table PlayerTable
--- @param entity LuaEntity
--- @param shift boolean?
function linked_belt.finish_connection(player, player_table, entity, shift)
  local source = player_table.linked_belt_source
  if not source then
    return
  end
  local neighbour = entity.linked_belt_neighbour
  if entity.unit_number ~= source.unit_number and (shift or not neighbour) then
    if neighbour then
      linked_belt.sever_connection(player, player_table, entity)
    end
    entity.linked_belt_type = source.linked_belt_type == "input" and "output" or "input"
    entity.connect_linked_belts(source)
    player_table.flags.connecting_linked_belts = false
    player_table.linked_belt_source = nil
    local source_players = global.linked_belt_sources[source.unit_number]
    source_players[player.index] = nil
    if table_size(source_players) == 0 then
      global.linked_belt_sources[source.unit_number] = nil
    end
    linked_belt.render_connection(player, player_table)
  else
    util.error_text(player, { "ee-message.connection-blocked" }, entity.position)
  end
end

--- @param player LuaPlayer
--- @param player_table PlayerTable
function linked_belt.cancel_connection(player, player_table)
  player_table.flags.connecting_linked_belts = false
  local source = player_table.linked_belt_source
  if not source then
    return
  end
  local source_players = global.linked_belt_sources[source.unit_number]
  source_players[player.index] = nil
  if table_size(source_players) == 0 then
    global.linked_belt_sources[source.unit_number] = nil
  end
  player_table.linked_belt_source = nil
  linked_belt.render_connection(player, player_table)
end

--- @param player LuaPlayer
--- @param player_table PlayerTable
--- @param entity LuaEntity
function linked_belt.sever_connection(player, player_table, entity)
  entity.disconnect_linked_belts()
  linked_belt.render_connection(player, player_table)
end

--- @param objects table
--- @param color Color
--- @param dashed boolean
--- @param player_index uint
--- @param source LuaEntity
--- @param destination LuaEntity?
local function draw_connection(objects, color, dashed, player_index, source, destination)
  for _, entity in ipairs({ source, destination }) do
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

local colors = {
  red = { r = 1, g = 0.5, b = 0.5 },
  green = { r = 0.3, g = 0.8, b = 0.3 },
  teal = { r = 0.5, g = 1, b = 1 },
}

--- @param player LuaPlayer
--- @param player_table PlayerTable
function linked_belt.render_connection(player, player_table)
  local objects = player_table.linked_belt_render_objects
  for i = 1, #objects do
    rendering.destroy(objects[i])
  end

  objects = {} -- new objects table

  local active_source = player_table.linked_belt_source
  if active_source and active_source.valid then
    local neighbour = active_source.linked_belt_neighbour
    if neighbour then
      draw_connection(objects, colors.red, false, player.index, active_source, active_source.linked_belt_neighbour)
    end
  end

  local selected = player.selected
  if selected and selected.name == "ee-linked-belt" then
    local neighbour = selected.linked_belt_neighbour
    if
      neighbour
      and not (active_source and active_source.unit_number == selected.unit_number)
      and not (active_source and active_source.unit_number == neighbour.unit_number)
    then
      draw_connection(objects, colors.green, false, player.index, selected, neighbour)
    end
    if active_source and active_source.valid then
      draw_connection(objects, colors.teal, true, player.index, active_source, selected)
    end
  elseif active_source and active_source.valid then
    draw_connection(objects, colors.teal, true, player.index, active_source)
  end

  player_table.linked_belt_render_objects = objects
end

--- @param e on_player_rotated_entity
function linked_belt.on_rotated(e)
  local entity = e.entity

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

return linked_belt
