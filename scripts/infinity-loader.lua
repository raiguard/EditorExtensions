local flib_direction = require("__flib__.direction")
local flib_migration = require("__flib__.migration")
local position = require("__flib__.position")

local transport_belt_connectables = {
  "transport-belt",
  "underground-belt",
  "splitter",
  "loader",
  "loader-1x1",
  "linked-belt",
  "lane-splitter",
}

--- @param entity LuaEntity
local function snap(entity)
  local offset_direction = entity.direction
  if entity.loader_type == "input" then
    offset_direction = flib_direction.opposite(offset_direction)
  end
  local belt_position = position.add(entity.position, flib_direction.to_vector(offset_direction))
  local belt =
    entity.surface.find_entities_filtered({ position = belt_position, type = transport_belt_connectables })[1]
  if not belt then
    belt =
      entity.surface.find_entities_filtered({ position = belt_position, ghost_type = transport_belt_connectables })[1]
  end
  if not belt then
    return
  end
  if belt.direction == flib_direction.opposite(entity.direction) then
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
  for i = 1, 2 do
    local filter = entity.get_filter(i)
    if filter then
      chest.set_infinity_container_filter(i, {
        index = i,
        name = filter.name --[[@as string]],
        quality = filter.quality,
        count = prototypes.item[filter.name].stack_size * 5,
        mode = "exactly",
      })
    else
      chest.set_infinity_container_filter(i, nil)
    end
  end
end

--- @param loader LuaEntity
--- @param combinator LuaEntity
local function copy_from_loader_to_combinator(loader, combinator)
  local cb = combinator.get_or_create_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
  --- @type LuaLogisticSection?
  local section
  for _, sec in pairs(cb.sections) do
    if sec.group == "" then
      section = sec
      break
    end
  end
  if not section then
    section = cb.add_section()
  end
  if not section then
    return -- When will this ever happen?
  end
  --- @type ItemFilter?
  local first_filter
  for i = 1, 2 do
    local filter = loader.get_filter(i)
    if not filter then
      goto continue
    end
    if i == 1 then
      first_filter = filter
    elseif first_filter and filter.name == first_filter.name and filter.quality == first_filter.quality then
      return
    end
    section.set_slot(i, {
      value = {
        type = "item",
        name = filter.name --[[@as string]],
        quality = filter.quality,
      },
      min = 1,
    })
    ::continue::
  end
end

--- @param combinator LuaEntity
--- @param loader LuaEntity
local function copy_from_combinator_to_loader(combinator, loader)
  local cb = combinator.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior?]]
  if not cb then
    return
  end
  local section = cb.get_section(1)
  if not section then
    return
  end
  for i = 1, 2 do
    local filter = section.filters[i]
    if filter then
      local value = filter.value
      if value and prototypes[value.type or "item"][value.name] then
        loader.set_filter(i, { name = value.name, quality = value.quality })
      else
        loader.set_filter(i, nil)
      end
    end
  end
  sync_chest_filter(loader)
end

--- @param e BuiltEvent
local function on_entity_built(e)
  local entity = e.entity or e.destination
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
local function on_entity_destroyed(e)
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
local function on_entity_rotated(e)
  local entity = e.entity
  if not entity.valid or entity.name ~= "ee-infinity-loader" then
    return
  end
  sync_chest_filter(entity)
end

--- @param e EventData.on_entity_settings_pasted
local function on_entity_settings_pasted(e)
  local source, destination = e.source, e.destination
  if not source.valid or not destination.valid then
    return
  end
  local source_is_loader, destination_is_loader =
    source.name == "ee-infinity-loader", destination.name == "ee-infinity-loader"
  if source_is_loader and destination.name == "constant-combinator" then
    copy_from_loader_to_combinator(source, destination)
  elseif source.name == "constant-combinator" and destination_is_loader then
    copy_from_combinator_to_loader(source, destination)
  elseif destination_is_loader then
    sync_chest_filter(destination)
  end
end

--- @param e EventData.on_gui_opened
local function on_gui_opened(e)
  if e.gui_type ~= defines.gui_type.entity then
    return
  end
  local entity = e.entity
  if not entity or not entity.valid then
    return
  end
  if entity.name == "ee-infinity-loader" then
    storage.infinity_loader_open[e.player_index] = entity
  end
end

--- @param e EventData.on_gui_closed
local function on_gui_closed(e)
  if e.gui_type ~= defines.gui_type.entity then
    return
  end
  local loader = storage.infinity_loader_open[e.player_index]
  if loader and loader.valid then
    sync_chest_filter(loader)
    storage.infinity_loader_open[e.player_index] = nil
  end
end

local infinity_loader = {}

function infinity_loader.on_init()
  --- @type table<uint, LuaEntity>
  storage.infinity_loader_open = {}
end

--- @param e ConfigurationChangedData
function infinity_loader.on_configuration_changed(e)
  flib_migration.on_config_changed(
    e,
    infinity_loader.migrations,
    script.mod_name,
    e.mod_changes.EditorExtensions and e.mod_changes.EditorExtensions.old_version
  )
end

infinity_loader.migrations = {
  ["2.0.0"] = function()
    for _, surface in pairs(game.surfaces) do
      for _, combinator in pairs(surface.find_entities_filtered({ name = "ee-infinity-loader-dummy-combinator" })) do
        local cb = combinator.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior?]]
        if not cb then
          goto continue
        end
        local section = cb.get_section(1)
        if not section then
          goto continue
        end
        local filter_1, filter_2 = section.filters[1], section.filters[2]
        local loader = combinator.surface.create_entity({
          name = "ee-infinity-loader",
          direction = combinator.direction,
          position = combinator.position,
          force = combinator.force,
          last_user = combinator.last_user,
          fast_replace = true,
          create_build_effect_smoke = false,
        })
        if not loader then
          error("Failed to create infinity loader replacement.")
        end
        if filter_1 and filter_1.value then
          loader.set_filter(1, { name = filter_1.value.name, quality = filter_1.value.quality, amount = filter_1.min })
        end
        if filter_2 and filter_2.value then
          loader.set_filter(2, { name = filter_2.value.name, quality = filter_2.value.quality, amount = filter_2.min })
        end
        snap(loader)
        combinator.destroy()
        ::continue::
      end
    end
  end,
  --- @param old_version string
  ["2.4.0"] = function(old_version)
    if not flib_migration.is_newer_version("2.0.0", old_version) then
      return
    end
    for _, surface in pairs(game.surfaces) do
      for _, loader in pairs(surface.find_entities_filtered({ name = "ee-infinity-loader" })) do
        loader.set_filter(2, loader.get_filter(1))
      end
    end
  end,
}

infinity_loader.events = {
  [defines.events.on_built_entity] = on_entity_built,
  [defines.events.on_entity_cloned] = on_entity_built,
  [defines.events.on_entity_died] = on_entity_destroyed,
  [defines.events.on_entity_settings_pasted] = on_entity_settings_pasted,
  [defines.events.on_gui_closed] = on_gui_closed,
  [defines.events.on_gui_opened] = on_gui_opened,
  [defines.events.on_player_mined_entity] = on_entity_destroyed,
  [defines.events.on_player_rotated_entity] = on_entity_rotated,
  [defines.events.on_robot_built_entity] = on_entity_built,
  [defines.events.on_robot_mined_entity] = on_entity_destroyed,
  [defines.events.script_raised_built] = on_entity_built,
  [defines.events.script_raised_destroy] = on_entity_destroyed,
  [defines.events.script_raised_revive] = on_entity_built,
  [defines.events.on_space_platform_built_entity] = on_entity_built,
  [defines.events.on_space_platform_mined_entity] = on_entity_destroyed,
}

infinity_loader.on_nth_tick = {
  [15] = function()
    for unit_number, loader in pairs(storage.infinity_loader_open) do
      if loader.valid then
        sync_chest_filter(loader)
      else
        storage.infinity_loader_open[unit_number] = nil
      end
    end
  end,
}

return infinity_loader
