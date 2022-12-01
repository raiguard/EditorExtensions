local util = require("__EditorExtensions__/scripts/util")

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

--- @param entity LuaEntity
--- @return boolean
function infinity_loader.check_is_loader(entity)
  local name = entity.name
  if name == "ee-infinity-loader-chest" then
    return false
  end
  return string.find(entity.name, "ee-infinity-loader", nil, true) and true or false
end

--- Snaps the loader to the transport-belt-connectable entity that it's facing. If `target` is supplied, it will check
--- against that entity, and will not snap if it cannot connect to it.
--- @param entity LuaEntity
--- @param target LuaEntity?
function infinity_loader.snap(entity, target)
  if not entity or not entity.valid then
    return
  end

  -- Check for a connected belt, then flip and try again, then flip back if failed
  for _ = 1, 2 do
    local connection = entity.belt_neighbours[entity.loader_type .. "s"][1]
    if connection and (not target or connection.unit_number == target.unit_number) then
      -- Snap the belt type
      local belt_type = util.get_belt_type(connection)
      if belt_type and util.get_belt_type(entity) ~= belt_type then
        -- Fast-replace does not work because the loader collides with the chest
        local surface = entity.surface
        local position = entity.position
        local direction = entity.direction
        local loader_type = entity.loader_type
        local force = entity.force
        local last_user = entity.last_user
        if last_user == "" then
          last_user = nil
        end
        local filter = entity.get_filter(1)
        entity.destroy({ raise_destroy = true }) -- The chest will be destroyed here
        local new = surface.create_entity({
          name = "ee-infinity-loader" .. (#belt_type > 0 and "-" .. belt_type or ""),
          position = position,
          direction = direction,
          type = loader_type,
          force = force,
          player = last_user,
          create_build_effect_smoke = false,
          raise_built = true,
        })
        if not new then
          return
        end
        new.set_filter(1, filter)
        infinity_loader.sync_chest_filter(new)
      end
      break
    else
      -- Flip the direction
      entity.loader_type = entity.loader_type == "output" and "input" or "output"
    end
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
    chest.set_infinity_container_filter(
      1,
      { index = 1, name = filter, count = game.item_prototypes[filter].stack_size * 5, mode = "exactly" }
    )
    chest.remove_unfiltered_items = false -- Tiny performance benefit
  else
    chest.set_infinity_container_filter(1, nil)
    chest.remove_unfiltered_items = true
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
