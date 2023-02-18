local direction_util = require("__flib__/direction")
local position = require("__flib__/position")

--- @type table<defines.direction, Vector>
local offsets = {
  [defines.direction.north] = { 0, -1 },
  [defines.direction.east] = { 1, 0 },
  [defines.direction.south] = { 0, 1 },
  [defines.direction.west] = { -1, 0 },
}

local transport_belt_connectables = {
  "transport-belt",
  "underground-belt",
  "splitter",
  "loader",
  "loader-1x1",
  "linked-belt",
}

--- @param entity LuaEntity
local function snap(entity)
  local offset_direction = entity.direction
  if entity.loader_type == "input" then
    offset_direction = direction_util.opposite(offset_direction)
  end
  local belt_position = position.add(entity.position, offsets[offset_direction])
  local belt =
    entity.surface.find_entities_filtered({ position = belt_position, type = transport_belt_connectables })[1]
  if not belt then
    belt =
      entity.surface.find_entities_filtered({ position = belt_position, ghost_type = transport_belt_connectables })[1]
  end
  if not belt then
    return
  end
  if belt.direction == direction_util.opposite(entity.direction) then
    entity.loader_type = entity.loader_type == "output" and "input" or "output"
  end
end

--- @param entity LuaEntity
--- @param chest LuaEntity?
local function sync_chest_filter(entity, chest)
  if not chest then
    chest = entity.surface.find_entity("ee-infinity-loader-chest", entity.position)
  end
  if not chest then
    entity.destroy()
    return
  end
  local filter = entity.get_filter(1)
  if filter then
    chest.set_infinity_container_filter(1, {
      index = 1,
      name = filter,
      count = game.item_prototypes[filter].stack_size * 5,
      mode = "exactly",
    })
  else
    chest.set_infinity_container_filter(1, nil)
  end
end

--- @param e BuiltEvent
local function on_built(e)
  local entity = e.entity or e.created_entity or e.destination
  if not entity.valid then
    return
  end

  if entity.name ~= "ee-infinity-loader" then
    return
  end

  -- Create chest
  local chest = entity.surface.create_entity({
    name = "ee-infinity-loader-chest",
    position = entity.position,
    force = entity.force,
    create_build_effect_smoke = false,
    raise_built = true,
  })

  if not chest then
    entity.destroy()
    return
  end

  chest.remove_unfiltered_items = true
  sync_chest_filter(entity, chest)
  snap(entity)
end

--- @param e DestroyedEvent
local function on_destroyed(e)
  local entity = e.entity
  if not entity.valid or entity.name ~= "ee-infinity-loader" then
    return
  end
  local chest = entity.surface.find_entity("ee-infinity-loader-chest", entity.position)
  if chest then
    chest.destroy({ raise_destroy = true })
  end
end

--- @param e EventData.on_player_rotated_entity
local function on_rotated(e)
  local entity = e.entity
  if not entity.valid or entity.name ~= "ee-infinity-loader" then
    return
  end
  sync_chest_filter(entity)
end

--- @param e EventData.on_entity_settings_pasted
local function on_settings_pasted(e)
  local destination = e.destination
  if not destination.valid or destination.name ~= "ee-infinity-loader" then
    return
  end
  -- TODO: Handle to/from a constant combinator
  sync_chest_filter(destination)
end

--- @param e EventData.on_gui_opened
local function on_gui_opened(e)
  if e.gui_type ~= defines.gui_type.entity then
    return
  end
  local entity = e.entity --[[@as LuaEntity]]
  if entity.name == "ee-infinity-loader" then
    global.infinity_loader_open[e.player_index] = entity
  end
end

--- @param e EventData.on_gui_closed
local function on_gui_closed(e)
  if e.gui_type ~= defines.gui_type.entity then
    return
  end
  local loader = global.infinity_loader_open[e.player_index]
  if loader and loader.valid then
    sync_chest_filter(loader)
    global.infinity_loader_open[e.player_index] = nil
  end
end

local infinity_loader = {}

function infinity_loader.on_init()
  --- @type table<uint, LuaEntity>
  global.infinity_loader_open = {}
end

infinity_loader.events = {
  [defines.events.on_built_entity] = on_built,
  [defines.events.on_entity_cloned] = on_built,
  [defines.events.on_entity_died] = on_destroyed,
  [defines.events.on_entity_settings_pasted] = on_settings_pasted,
  [defines.events.on_gui_closed] = on_gui_closed,
  [defines.events.on_gui_opened] = on_gui_opened,
  [defines.events.on_player_mined_entity] = on_destroyed,
  [defines.events.on_player_rotated_entity] = on_rotated,
  [defines.events.on_robot_built_entity] = on_built,
  [defines.events.on_robot_mined_entity] = on_destroyed,
  [defines.events.script_raised_built] = on_built,
  [defines.events.script_raised_destroy] = on_destroyed,
  [defines.events.script_raised_revive] = on_built,
}

infinity_loader.on_nth_tick = {
  [5] = function()
    for _, loader in pairs(global.infinity_loader_open) do
      sync_chest_filter(loader)
    end
  end,
}

return infinity_loader
