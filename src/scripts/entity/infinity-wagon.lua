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

function infinity_wagon.on_tick()
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
          t.wagon_fluidbox[1] = fluid and fluid.amount > 0 and {name=fluid.name, amount=(math_abs(fluid.amount) * 250), temperature=fluid.temperature} or nil
          t.flip = 1
        elseif t.flip == 1 then
          local fluid = t.wagon_fluidbox[1]
          t.proxy_fluidbox[1] = fluid and fluid.amount > 0 and {name=fluid.name, amount=(math_abs(fluid.amount) / 250), temperature=fluid.temperature} or nil
          t.flip = 0
        end
      end
      t.proxy.teleport(t.wagon.position)
    end
  end
end

function infinity_wagon.on_gui_opened(e)
  if e.entity and infinity_wagon.wagon_names[e.entity.name] then
    game.players[e.player_index].opened = global.wagons[e.entity.unit_number].proxy
  end
end

function infinity_wagon.on_entity_settings_pasted(e)
  if e.source.name == "ee-infinity-cargo-wagon" and e.destination.name == "ee-infinity-cargo-wagon" then
    global.wagons[e.destination.unit_number].proxy.copy_settings(global.wagons[e.source.unit_number].proxy)
  elseif e.source.name == "ee-infinity-fluid-wagon" and e.destination.name == "ee-infinity-fluid-wagon" then
    global.wagons[e.destination.unit_number].proxy.copy_settings(global.wagons[e.source.unit_number].proxy)
  end
end

function infinity_wagon.on_player_setup_blueprint(e)
  local player = game.get_player(e.player_index)
  local bp = player.blueprint_to_setup
  if not bp or not bp.valid_for_read then
    bp = player.cursor_stack
  end
  local entities = bp.get_blueprint_entities()
  if not entities then return end
  local chests = player.surface.find_entities_filtered{name="ee-infinity-wagon-chest"}
  local pipes = player.surface.find_entities_filtered{name="ee-infinity-wagon-pipe"}
  local chest_index = 0
  local pipe_index = 0
  for _, en in pairs(entities) do
    -- if the entity is an infinity wagon
    if en.name == "ee-infinity-cargo-wagon" then
      chest_index = chest_index + 1
      if not en.tags then en.tags = {} end
      en.tags.EditorExtensions = chests[chest_index].infinity_container_filters
    elseif en.name == "ee-infinity-fluid-wagon" then
      pipe_index = pipe_index + 1
      if not en.tags then en.tags = {} end
      en.tags.EditorExtensions = pipes[pipe_index].get_infinity_pipe_filter()
    end
  end
  bp.set_blueprint_entities(entities)
end

return infinity_wagon