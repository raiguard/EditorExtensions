local infinity_loader = {}

function infinity_loader.init()
  --- @type table<uint, LuaEntity>
  global.infinity_loader_open = {}
end

--- @param entity LuaEntity
function infinity_loader.on_built(entity)
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
  infinity_loader.sync_chest_filter(entity, chest)
  infinity_loader.snap(entity)
end

--- @param entity LuaEntity
function infinity_loader.on_destroyed(entity)
  local chest = entity.surface.find_entity("ee-infinity-loader-chest", entity.position)
  if chest then
    chest.destroy({ raise_destroy = true })
  end
end

--- Snaps the loader to the transport-belt-connectable entity that it's facing. If `target` is supplied, it will check
--- against that entity, and will not snap if it cannot connect to it.
--- @param entity LuaEntity
--- @param target LuaEntity?
function infinity_loader.snap(entity, target)
  -- Check for a connected belt, then flip and try again, then flip back if failed
  for _ = 1, 2 do
    local connection = entity.belt_neighbours[entity.loader_type .. "s"][1]
    if connection and (not target or connection.unit_number == target.unit_number) then
      break
    else
      -- Flip the direction
      entity.loader_type = entity.loader_type == "output" and "input" or "output"
    end
  end
end

--- Snaps all neighbouring infinity loaders.
--- @param entity LuaEntity
function infinity_loader.snap_belt_neighbours(entity)
  local linked_belt_neighbour
  if entity.type == "linked-belt" then
    linked_belt_neighbour = entity.linked_belt_neighbour
    if linked_belt_neighbour then
      entity.disconnect_linked_belts()
    end
  end

  local to_snap = {}
  for _ = 1, (entity.type == "transport-belt" or entity.type == "linked-belt") and 4 or 2 do
    -- Catalog neighbouring loaders for this rotation
    for _, neighbours in pairs(entity.belt_neighbours) do
      for _, neighbour in ipairs(neighbours) do
        if neighbour.name == "ee-infinity-loader" then
          table.insert(to_snap, neighbour)
        end
      end
    end
    -- Rotate or flip linked belt type
    if entity.type == "linked-belt" then
      entity.linked_belt_type = entity.linked_belt_type == "output" and "input" or "output"
    else
      entity.rotate()
    end
  end

  if linked_belt_neighbour then
    entity.connect_linked_belts(linked_belt_neighbour)
  end

  for _, loader in pairs(to_snap) do
    infinity_loader.snap(loader, entity)
  end
end

--- @param entity LuaEntity
--- @param chest LuaEntity?
function infinity_loader.sync_chest_filter(entity, chest)
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
      count = game.item_prototypes[filter].stack_size * 5, --- @diagnostic disable-line
      mode = "exactly",
    })
  else
    chest.set_infinity_container_filter(1, nil)
  end
end

function infinity_loader.cleanup_orphans()
  for _, surface in pairs(game.surfaces) do
    for _, chest in ipairs(surface.find_entities_filtered({ name = "ee-infinity-loader-chest" })) do
      -- If there is no loader
      if #surface.find_entities_filtered({ type = "loader-1x1", position = chest.position }) == 0 then
        -- Destroy the chest
        chest.destroy()
      end
    end
  end
end

return infinity_loader
