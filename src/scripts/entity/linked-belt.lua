local direction = require("__flib__.direction")

local shared = require("scripts.shared")
local util = require("scripts.util")

local linked_belt = {}

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

  local source_players = global.linked_belt_sources[source.unit_number] or {}
  source_players[player.index] = true
  global.linked_belt_sources[source.unit_number] = source_players

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
    local source_players = global.linked_belt_sources[source.unit_number]
    source_players[player.index] = nil
    if table_size(source_players) == 0 then
      global.linked_belt_sources[source.unit_number] = nil
    end
    linked_belt.render_connection(player, player_table)
    shared.snap_belt_neighbours(entity)
  else
    util.error_text(player, { "ee-message.connection-blocked" }, entity.position)
  end
end

function linked_belt.cancel_connection(player, player_table)
  player_table.flags.connecting_linked_belts = false
  local source = player_table.linked_belt_source
  local source_players = global.linked_belt_sources[source.unit_number]
  source_players[player.index] = nil
  if table_size(source_players) == 0 then
    global.linked_belt_sources[source.unit_number] = nil
  end
  player_table.linked_belt_source = nil
  linked_belt.render_connection(player, player_table)
end

function linked_belt.sever_connection(player, player_table, entity)
  entity.disconnect_linked_belts()
  linked_belt.render_connection(player, player_table)
end

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
  if selected and linked_belt.check_is_linked_belt(selected) then
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

function linked_belt.handle_rotation(e)
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

-- SNAPPING

local function get_linked_belt_direction(belt)
  if belt.linked_belt_type == "output" then
    return direction.opposite(belt.direction)
  end
  return belt.direction
end

local function replace_linked_belt(entity, new_type)
  local entity_data = {
    direction = get_linked_belt_direction(entity),
    force = entity.force,
    last_user = entity.last_user,
    linked_belt_type = entity.linked_belt_type,
    position = entity.position,
    surface = entity.surface,
  }

  entity.destroy()

  local new_entity = entity_data.surface.create_entity({
    name = "ee-linked-belt" .. (new_type == "" and "" or "-" .. new_type),
    direction = entity_data.direction,
    force = entity_data.force,
    player = entity_data.last_user,
    position = entity_data.position,
    create_build_effect_smoke = false,
  })
  new_entity.linked_belt_type = entity_data.linked_belt_type

  return new_entity
end

function linked_belt.snap(entity, target)
  if not entity or not entity.valid then
    return
  end

  -- temporarily disconnect from other end
  local neighbour = entity.linked_belt_neighbour
  if neighbour then
    entity.disconnect_linked_belts()
  end

  -- check for a connected belt, then flip and try again, then flip back if failed
  -- this will inherently snap the direction, and then snap the belt type if they don't match
  -- if the belt already has a neighbour, the direction will not be flipped
  for i = 1, 2 do
    local linked_belt_type = entity.linked_belt_type
    local neighbour_key = linked_belt_type .. "s"

    local connection = entity.belt_neighbours[neighbour_key][1]
    if connection and (not target or connection.unit_number == target.unit_number) then
      -- snap the belt type
      local belt_type = util.get_belt_type(connection)
      if util.get_belt_type(entity) ~= belt_type then
        entity = replace_linked_belt(entity, belt_type)
      end
      -- prevent an actual flip if the belt has a neighbour
      if i == 2 and neighbour then
        entity.linked_belt_type = linked_belt_type == "output" and "input" or "output"
      end
      break
    else
      -- flip the direction
      entity.linked_belt_type = linked_belt_type == "output" and "input" or "output"
    end
  end

  -- reconnect to other end
  if neighbour then
    entity.connect_linked_belts(neighbour)
  end
end

function linked_belt.sync_belt_types(player, entity)
  local neighbour = entity.linked_belt_neighbour
  if neighbour then
    local belt_type = util.get_belt_type(entity)
    if belt_type ~= util.get_belt_type(neighbour) then
      entity.disconnect_linked_belts()
      neighbour = replace_linked_belt(neighbour, belt_type)
      entity.connect_linked_belts(neighbour)
    else
      util.error_text(player, { "ee-message.belt-types-already-synced" }, entity.position)
    end
  end
end

return linked_belt
