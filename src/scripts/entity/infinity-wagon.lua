local infinity_wagon = {}

local util = require("scripts.util")

local math_abs = math.abs

infinity_wagon.wagon_names = {
  ["ee-infinity-cargo-wagon"] = true,
  ["ee-infinity-fluid-wagon"] = true
}

function infinity_wagon.build(entity, tags)
  local proxy = entity.surface.create_entity{
    name = "ee-infinity-wagon-"..(entity.name == "ee-infinity-cargo-wagon" and "chest" or "pipe"),
    position = entity.position,
    force = entity.force
  }
  -- create all api lookups here to save time in on_tick()
  local data = {
    wagon = entity,
    wagon_name = entity.name,
    wagon_inv = entity.get_inventory(defines.inventory.cargo_wagon),
    wagon_fluidbox = entity.fluidbox,
    proxy = proxy,
    proxy_inv = proxy.get_inventory(defines.inventory.chest),
    proxy_fluidbox = proxy.fluidbox,
    flip = 0
  }
  global.wagons[entity.unit_number] = data
  -- apply any pre-existing filters
  if tags and tags.EditorExtensions then
    if entity.name == "ee-infinity-cargo-wagon" then
      data.proxy.infinity_container_filters = tags.EditorExtensions
    elseif entity.name == "ee-infinity-fluid-wagon" then
      data.proxy.set_infinity_pipe_filter(tags.EditorExtensions)
    end
  end
end

-- clear the wagon's inventory and set FLIP to 3 to prevent it from being refilled
function infinity_wagon.clear_inventory(entity)
  global.wagons[entity.unit_number].flip = 3
  entity.get_inventory(defines.inventory.cargo_wagon).clear()
end

-- restart syncing the proxy's inventory
function infinity_wagon.reset(entity)
  global.wagons[entity.unit_number].flip = 0
end

function infinity_wagon.destroy(entity)
  global.wagons[entity.unit_number].proxy.destroy()
  global.wagons[entity.unit_number] = nil
end

function infinity_wagon.check_and_open(player, selected)
  if selected and selected.name == "ee-infinity-fluid-wagon" then
    if util.position.distance(player.position, selected.position) <= player.reach_distance then
      player.opened = global.wagons[selected.unit_number].proxy
    end
  end
end

-- called during `on_tick`
function infinity_wagon.flip_inventories()
  for _, t in pairs(global.wagons) do
    if t.wagon.valid and t.proxy.valid then
      if t.wagon_name == "ee-infinity-cargo-wagon" then
        if t.flip == 0 then
          t.wagon_inv.clear()
          for n, c in pairs(t.proxy_inv.get_contents()) do t.wagon_inv.insert{name=n, count=c} end
          t.flip = 1
        elseif t.flip == 1 then
          t.proxy_inv.clear()
          for n, c in pairs(t.wagon_inv.get_contents()) do t.proxy_inv.insert{name=n, count=c} end
          t.flip = 0
        end
      elseif t.wagon_name == "ee-infinity-fluid-wagon" then
        if t.flip == 0 then
          local fluid = t.proxy_fluidbox[1]
          t.wagon_fluidbox[1] = fluid and fluid.amount > 0
            and {name=fluid.name, amount=(math_abs(fluid.amount) * 250), temperature=fluid.temperature}
            or nil
          t.flip = 1
        elseif t.flip == 1 then
          local fluid = t.wagon_fluidbox[1]
          t.proxy_fluidbox[1] = fluid
            and fluid.amount > 0
            and {name=fluid.name, amount=(math_abs(fluid.amount) / 250), temperature=fluid.temperature}
            or nil
          t.flip = 0
        end
      end
      t.proxy.teleport(t.wagon.position)
    end
  end
end

function infinity_wagon.open(player_index, entity)
  game.get_player(player_index).opened = global.wagons[entity.unit_number].proxy
end

function infinity_wagon.paste_settings(source, destination)
  global.wagons[destination.unit_number].proxy.copy_settings(global.wagons[source.unit_number].proxy)
end

function infinity_wagon.setup_cargo_blueprint(blueprint_entity, entity)
    if entity then
      if not blueprint_entity.tags then blueprint_entity.tags = {} end
      blueprint_entity.tags.EditorExtensions = global.wagons[entity.unit_number].proxy.infinity_container_filters
    end
    return blueprint_entity
end

function infinity_wagon.setup_fluid_blueprint(blueprint_entity, entity)
  if entity then
    if not blueprint_entity.tags then blueprint_entity.tags = {} end
    blueprint_entity.tags.EditorExtensions = global.wagons[entity.unit_number].proxy.get_infinity_pipe_filter()
  end
  return blueprint_entity
end

return infinity_wagon