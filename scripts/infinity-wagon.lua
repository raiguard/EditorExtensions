--- @class InfinityCargoWagonData
--- @field flip integer
--- @field proxy LuaEntity
--- @field proxy_inv LuaInventory
--- @field wagon LuaEntity
--- @field wagon_inv LuaInventory
--- @field wagon_last_position MapPosition
--- @field wagon_name string

--- @class InfinityFluidWagonData
--- @field flip integer
--- @field proxy LuaEntity
--- @field proxy_fluidbox LuaFluidBox
--- @field wagon LuaEntity
--- @field wagon_last_position MapPosition
--- @field wagon_name string

local wagon_names = {
  ["ee-infinity-cargo-wagon"] = true,
  ["ee-infinity-fluid-wagon"] = true,
}

--- @param player LuaPlayer
--- @param entity LuaEntity
local function open_gui(player, entity)
  player.opened = storage.wagons[entity.unit_number].proxy
end

--- @param e BuiltEvent
local function on_entity_built(e)
  local entity = e.entity or e.destination
  if not entity or not entity.valid or not wagon_names[entity.name] then
    return
  end

  local proxy = entity.surface.create_entity({
    name = "ee-infinity-wagon-" .. (entity.name == "ee-infinity-cargo-wagon" and "chest" or "pipe"),
    position = entity.position,
    force = entity.force,
  })
  if not proxy then
    return
  end

  -- Create all api lookups here to save time in on_tick()
  local data = {
    flip = 0,
    proxy = proxy,
    proxy_fluidbox = proxy.fluidbox,
    proxy_inv = proxy.get_inventory(defines.inventory.chest),
    wagon = entity,
    wagon_inv = entity.get_inventory(defines.inventory.cargo_wagon),
    wagon_last_position = entity.position,
    wagon_name = entity.name,
  }
  storage.wagons[entity.unit_number] = data

  -- Apply any pre-existing filters
  local tags = e.tags
  if not tags or not tags.EditorExtensions then
    return
  end
  local tags = tags.EditorExtensions
  if entity.name == "ee-infinity-cargo-wagon" then
    -- LEGACY: Before v1.9.16, we did not store the `remove unfiltered items` setting
    if tags.filters then
      data.proxy.infinity_container_filters = tags.filters
      data.proxy.remove_unfiltered_items = tags.remove_unfiltered_items
    else
      --- @cast tags InfinityInventoryFilter[]
      data.proxy.infinity_container_filters = tags
    end
  elseif entity.name == "ee-infinity-fluid-wagon" then
    --- @cast tags InfinityPipeFilter
    proxy.set_infinity_pipe_filter(tags)
  end
end

--- @param e DestroyedEvent
local function on_entity_destroyed(e)
  local entity = e.entity
  if not entity or not entity.valid or not wagon_names[entity.name] then
    return
  end

  local proxy = storage.wagons[entity.unit_number].proxy
  if proxy and proxy.valid then
    proxy.destroy({})
  end
  storage.wagons[entity.unit_number] = nil
end

--- @param e EventData.on_marked_for_deconstruction
local function on_marked_for_deconstruction(e)
  local entity = e.entity
  if not entity.valid or entity.name ~= "ee-infinity-cargo-wagon" then
    return
  end
  storage.wagons[entity.unit_number].flip = 3
  entity.get_inventory(defines.inventory.cargo_wagon).clear()
end

--- @param e EventData.on_cancelled_deconstruction
local function on_cancelled_deconstruction(e)
  local entity = e.entity
  if not entity.valid or entity.name ~= "ee-infinity-cargo-wagon" then
    return
  end
  -- Resume syncing
  storage.wagons[entity.unit_number].flip = 0
end

--- @param data InfinityCargoWagonData
local function sync_cargo(data)
  if data.flip == 0 then
    data.wagon_inv.clear()
    for _, item in pairs(data.proxy_inv.get_contents()) do
      data.wagon_inv.insert({ name = item.name, count = item.count, quality = item.quality })
    end
    data.flip = 1
  elseif data.flip == 1 then
    data.proxy_inv.clear()
    for _, item in pairs(data.wagon_inv.get_contents()) do
      data.proxy_inv.insert({ name = item.name, count = item.count, quality = item.quality })
    end
    data.flip = 0
  end
end

local abs = math.abs

--- @param data InfinityFluidWagonData
local function sync_fluid(data)
  if data.flip == 0 then
    local fluid = data.proxy_fluidbox[1]
    data.wagon.set_fluid(1, fluid and fluid.amount > 0 and {
      name = fluid.name,
      amount = (abs(fluid.amount) * 250),
      temperature = fluid.temperature,
    } or nil)
    data.flip = 1
  elseif data.flip == 1 then
    local fluid = data.wagon.get_fluid(1)
    data.proxy_fluidbox[1] = fluid
        and fluid.amount > 0
        and {
          name = fluid.name,
          amount = (abs(fluid.amount) / 250),
          temperature = fluid.temperature,
        }
        or nil
    data.flip = 0
  end
end

local function on_tick()
  for unit_number, data in pairs(storage.wagons) do
    if not data.wagon.valid or not data.proxy.valid then
      if data.wagon.valid then
        data.wagon.destroy({ raise_destroy = true })
      end
      if data.proxy.valid then
        data.proxy.destroy({ raise_destroy = true })
      end
      storage.wagons[unit_number] = nil
      goto continue
    end
    if data.wagon_name == "ee-infinity-cargo-wagon" then
      --- @cast data InfinityCargoWagonData
      sync_cargo(data)
    elseif data.wagon_name == "ee-infinity-fluid-wagon" then
      --- @cast data InfinityFluidWagonData
      sync_fluid(data)
    end
    local position = data.wagon.position
    local last_position = data.wagon_last_position
    if not last_position or last_position.x ~= position.x or last_position.y ~= position.y then
      data.proxy.teleport(data.wagon.position)
      data.wagon_last_position = data.wagon.position
    end
    ::continue::
  end
end

--- @param e EventData.on_gui_opened
local function on_gui_opened(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local entity = e.entity
  if not entity or not entity.valid or not wagon_names[entity.name] then
    return
  end
  open_gui(player, entity)
end

--- @param e EventData.CustomInputEvent
local function on_linked_open_gui(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local entity = player.selected
  if not entity or entity.name ~= "ee-infinity-fluid-wagon" then
    return
  end
  if not player.can_reach_entity(entity) then
    return
  end
  open_gui(player, entity)
end

--- @param e EventData.on_entity_settings_pasted
local function on_entity_settings_pasted(e)
  local source, destination = e.source, e.destination
  if not source.valid or not destination.valid then
    return
  end
  if not wagon_names[source.name] or not wagon_names[destination.name] then
    return
  end
  if source.name ~= destination.name then
    return
  end

  storage.wagons[destination.unit_number].proxy.copy_settings(storage.wagons[source.unit_number].proxy)
end

--- @param e EventData.on_player_setup_blueprint
local function on_player_setup_blueprint(e)
  local blueprint = e.stack
  if not blueprint then
    return
  end

  local entities = blueprint.get_blueprint_entities()
  if not entities then
    return
  end
  for i, entity in pairs(entities) do
    --- @cast i uint
    if not wagon_names[entity.name] then
      goto continue
    end
    local real_entity = e.surface.find_entity(entity.name, entity.position)
    if not real_entity then
      goto continue
    end
    local proxy = storage.wagons[real_entity.unit_number].proxy
    local tags = {}
    if entity.name == "ee-infinity-cargo-wagon" then
      tags.filters = proxy.infinity_container_filters
      tags.remove_unfiltered_items = proxy.remove_unfiltered_items
    else
      tags = proxy.get_infinity_pipe_filter()
    end
    blueprint.set_blueprint_entity_tag(i, "EditorExtensions", tags --[[@as AnyBasic]])
    ::continue::
  end
end

local infinity_wagon = {}

infinity_wagon.on_init = function()
  --- @type table<uint, InfinityCargoWagonData|InfinityFluidWagonData>
  storage.wagons = {}
end

infinity_wagon.events = {
  [defines.events.on_built_entity] = on_entity_built,
  [defines.events.on_cancelled_deconstruction] = on_cancelled_deconstruction,
  [defines.events.on_entity_cloned] = on_entity_built,
  [defines.events.on_entity_died] = on_entity_destroyed,
  [defines.events.on_entity_settings_pasted] = on_entity_settings_pasted,
  [defines.events.on_gui_opened] = on_gui_opened,
  [defines.events.on_marked_for_deconstruction] = on_marked_for_deconstruction,
  [defines.events.on_player_mined_entity] = on_entity_destroyed,
  [defines.events.on_player_setup_blueprint] = on_player_setup_blueprint,
  [defines.events.on_robot_built_entity] = on_entity_built,
  [defines.events.on_robot_mined_entity] = on_entity_destroyed,
  [defines.events.on_tick] = on_tick,
  [defines.events.script_raised_built] = on_entity_built,
  [defines.events.script_raised_destroy] = on_entity_destroyed,
  [defines.events.script_raised_revive] = on_entity_built,
  [defines.events.on_space_platform_built_entity] = on_entity_built,
  [defines.events.on_space_platform_mined_entity] = on_entity_destroyed,
  ["ee-linked-open-gui"] = on_linked_open_gui,
}

return infinity_wagon
