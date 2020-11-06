local infinity_loader = {}

local gui = require("__flib__.gui")
local util = require("scripts.util")

local constants = require("scripts.constants")

-- -----------------------------------------------------------------------------
-- LOCAL UTILITIES

local function get_belt_type(entity)
  local type = entity.name
  for pattern, replacement in pairs(constants.belt_type_patterns) do
    type = type:gsub(pattern, replacement)
  end
  -- check to see if the loader prototype exists
  if type ~= "" and not game.entity_prototypes["ee-infinity-loader-loader-"..type] then
    -- print warning message
    game.print{"", "EDITOR EXTENSIONS: ", {"ee-message.unable-to-identify-belt"}}
    game.print("entity_name = \""..entity.name.."\", parse_result = \""..type.."\"")
    -- set to default type
    type = "express"
  end
  return type
end

local function check_is_loader(entity)
  if entity.name:find("infinity%-loader%-loader") then return true end
  return false
end

-- get the direction that the mouth of the loader is facing
local function get_loader_direction(loader)
  if loader.loader_type == "input" then
    return util.direction.opposite(loader.direction)
  end
  return loader.direction
end

local function num_inserters(entity)
  return math.ceil(entity.prototype.belt_speed / constants.belt_speed_for_60_per_second) * 2
end

-- update inserter and chest filters
local function update_filters(combinator, entities)
  entities = entities or {}
  local loader = entities.loader or combinator.surface.find_entities_filtered{
    type = "loader-1x1",
    position = combinator.position
  }[1]
  local inserters = entities.inserters or combinator.surface.find_entities_filtered{
    name = "ee-infinity-loader-inserter", position = combinator.position
  }
  local chest = entities.chest or combinator.surface.find_entities_filtered{
    name = "ee-infinity-loader-chest",
    position = combinator.position
  }[1]
  local control = combinator.get_control_behavior()
  local enabled = control.enabled
  local filters = control.parameters
  local inserter_filter_mode
  if filters[1].signal.name or filters[2].signal.name or loader.loader_type == "output" then
    inserter_filter_mode = "whitelist"
  elseif loader.loader_type == "input" then
    inserter_filter_mode = "blacklist"
  end
  -- update inserter filter based on orthogonal
  for i = 1, #inserters do
    local orthogonal = i > (#inserters/2) and 1 or 2
    inserters[i].set_filter(1, filters[orthogonal].signal.name or nil)
    inserters[i].inserter_filter_mode = inserter_filter_mode
    inserters[i].active = enabled
  end
  -- update chest filters
  for i = 1, 2 do
    local name = filters[i].signal.name
    chest.set_infinity_container_filter(
      i,
      name and {name = name, count = game.item_prototypes[name].stack_size, mode = "exactly", index = i} or nil
    )
  end
  chest.remove_unfiltered_items = true
end

-- update inserter pickup/drop positions
local function update_inserters(loader, entities)
  entities = entities or {}
  local surface = loader.surface
  local inserters = entities.inserters or surface.find_entities_filtered{
    name = "ee-infinity-loader-inserter",
    position = loader.position
  }
  local chest = entities.chest or surface.find_entities_filtered{
    name = "ee-infinity-loader-chest",
    position = loader.position
  }[1]
  local e_type = loader.loader_type
  local e_position = loader.position
  local e_direction = loader.direction
  -- update number of inserters if needed
  if #inserters ~= num_inserters(loader) then
    for _, e in ipairs(inserters) do
      e.destroy()
    end
    inserters = {}
    for i = 1, num_inserters(loader) do
      inserters[i] = surface.create_entity{
        name = "ee-infinity-loader-inserter",
        position = loader.position,
        force = loader.force,
        direction = loader.direction,
        create_build_effect_smoke = false
      }
      inserters[i].inserter_stack_size_override = 1
    end
    update_filters(
      surface.find_entities_filtered{name = "ee-infinity-loader-logic-combinator", position = e_position}[1],
      {loader = loader, inserters = inserters, chest = chest}
    )
  end
  for i = 1, #inserters do
    local orthogonal = i > (#inserters/2) and -0.25 or 0.25
    local inserter = inserters[i]
    local mod = math.min((i % (#inserters/2)),3)
    if e_type == "input" then
      -- pickup on belt, drop in chest
      inserter.pickup_target = loader
      inserter.pickup_position = util.position.add(
        e_position,
        util.direction.to_vector(e_direction, (-mod*0.2 + 0.3), orthogonal)
      )
      inserter.drop_target = chest
      inserter.drop_position = e_position
    elseif e_type == "output" then
      -- pickup from chest, drop on belt
      inserter.pickup_target = chest
      inserter.pickup_position = chest.position
      inserter.drop_target = loader
      inserter.drop_position = util.position.add(
        e_position,
        util.direction.to_vector(e_direction, (mod*0.2 - 0.3), orthogonal)
      )
    end
  end
end

-- update belt type of the given loader
local function update_loader_type(loader, belt_type, overrides)
  overrides = overrides or {}
  -- save settings first
  local position = overrides.position or loader.position
  local direction = overrides.direction or loader.direction
  local force = overrides.force or loader.force
  local last_user = overrides.last_user or loader.last_user
  if last_user == "" then last_user = nil end
  local loader_type = overrides.loader_type or loader.loader_type
  local surface = overrides.surface or loader.surface
  if loader then loader.destroy() end
  local new_loader = surface.create_entity{
    name = "ee-infinity-loader-loader"..(belt_type == "" and "" or "-"..belt_type),
    position = position,
    direction = direction,
    force = force,
    player = last_user,
    type = loader_type,
    create_build_effect_smoke = false
  }
  update_inserters(new_loader)
  return new_loader
end

-- create an infinity loader
local function create_loader(type, mode, surface, position, direction, force)
  local name = "ee-infinity-loader-loader"..(type == "" and "" or "-"..type)
  if not game.entity_prototypes[name] then
    error("Attempted to create an infinity loader with an invalid belt type.")
  end
  local loader = surface.create_entity{
    name = name,
    position = position,
    direction = direction,
    force = force,
    type = mode,
    create_build_effect_smoke = false
  }
  -- fail-out if the loader was not successfully built
  if not loader then return end
  local inserters = {}
  for i = 1, num_inserters(loader) do
      inserters[i] = surface.create_entity{
      name = "ee-infinity-loader-inserter",
      position = position,
      force = force,
      direction = direction,
      create_build_effect_smoke = false
    }
    inserters[i].inserter_stack_size_override = 1
  end
  local chest = surface.create_entity{
    name = "ee-infinity-loader-chest",
    position = position,
    force = force,
    create_build_effect_smoke = false
  }
  local combinator = surface.create_entity{
    name = "ee-infinity-loader-logic-combinator",
    position = position,
    force = force,
    direction = mode == "input" and util.direction.opposite(direction) or direction,
    create_build_effect_smoke = false
  }
  return loader, inserters, chest, combinator
end

-- apply the function to each belt neighbor connected to this entity, and return entities that the callback matched
local function check_belt_neighbors(entity, func, type_agnostic)
  local belt_neighbors = entity.belt_neighbours
  local matched_entities = {}
  for _, type in pairs{"inputs", "outputs"} do
    if not type_agnostic then matched_entities[type] = {} end
    for _, e in ipairs(belt_neighbors[type] or {}) do
      if func(e) then
        table.insert(type_agnostic and matched_entities or matched_entities[type], e)
      end
    end
  end
  return matched_entities
end

-- apply the function to each entity on neighboring tiles, returning entities that the callback matched
local function check_tile_neighbors(entity, func, eight_way, direction_agnostic)
  local matched_entities = {}
  for i= 0, 7, eight_way and 1 or 2 do
    if not direction_agnostic then matched_entities[i] = {} end
    local entities = entity.surface.find_entities(
      util.position.to_tile_area(util.position.add(entity.position, util.direction.to_vector(i, 1)))
    )
    for _, e in ipairs(entities) do
      if func(e) then
        table.insert(direction_agnostic and matched_entities or matched_entities[i], e)
      end
    end
  end
  return matched_entities
end

-- -----------------------------------------------------------------------------
-- GUI

gui.add_templates{
  il_filter_button = {type = "choose-elem-button", style = "ee_il_filter_button", elem_type = "item"}
}

gui.add_handlers{
  il = {
    close_button = {
      on_gui_click = function(e)
        gui.handlers.il.window.on_gui_closed(e)
      end
    },
    state_switch = {
      on_gui_switch_state_changed = function(e)
        local entity = global.players[e.player_index].gui.il.entity
        entity.get_or_create_control_behavior().enabled = e.element.switch_state == "left"
        update_filters(entity)
      end
    },
    filter_button = {
      on_gui_elem_changed = function(e)
        local name = e.element.name
        local index = tonumber(string.sub(name, #name, #name))
        local entity = global.players[e.player_index].gui.il.entity
        local control = entity.get_or_create_control_behavior()
        control.set_signal(
          index,
          e.element.elem_value and {signal = {type = "item", name = e.element.elem_value}, count = 1} or nil
        )
        update_filters(entity)
      end
    },
    window = {
      on_gui_closed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.il
        gui.update_filters("il", e.player_index, nil, "remove")
        gui_data.window.destroy()
        player_table.gui.il = nil
        game.get_player(e.player_index).play_sound{path = "entity-close/express-loader"}
      end
    }
  }
}

-- TODO: update GUI state when any other players change something

local function create_gui(player, player_table, entity)
  local preview_entity = entity.surface.find_entities_filtered{position = entity.position, type = "loader-1x1"}[1]
  local control = entity.get_or_create_control_behavior()
  local parameters = control.parameters
  local gui_data = gui.build(player.gui.screen, {
    {type = "frame", direction = "vertical", handlers = "il.window", save_as = "window", children = {
      {type = "flow", save_as = "titlebar_flow", children = {
        {
          type = "label",
          style = "frame_title",
          caption = {"entity-name.ee-infinity-loader"},
          elem_mods = {ignored_by_interaction = true}
        },
        {template = "titlebar_drag_handle"},
        {template = "close_button", handlers = "il.close_button"}
      }},
      {type = "frame", style = "ee_inside_shallow_frame_for_entity", children = {
        {type = "frame", style = "deep_frame_in_shallow_frame", children = {
          {type = "entity-preview", style_mods = {width = 85, height = 85}, elem_mods = {entity = preview_entity}}
        }},
        {type = "flow", direction = "vertical", children = {
          {template = "vertically_centered_flow", children = {
            {type = "label", caption = {"ee-gui.state"}},
            {template = "pushers.horizontal"},
            {
              type = "switch",
              left_label_caption = {"gui-constant.on"},
              right_label_caption = {"gui-constant.off"},
              switch_state = control.enabled and "left" or "right",
              handlers = "il.state_switch"
            }
          }},
          {template = "pushers.vertical"},
          {template = "vertically_centered_flow", children = {
            {
              type = "label",
              caption = {"", {"ee-gui.filters"}, " [img=info]"},
              tooltip = {"ee-gui.il-filters-description"}
            },
            {type = "empty-widget", style_mods = {width = 20}},
            {type = "frame", style = "slot_button_deep_frame", children = {
              {
                template = "il_filter_button",
                name = "ee_il_filter_button_1",
                item = parameters[1].signal.name,
                handlers = "il.filter_button",
                save_as = "filter_button_1"
              },
              {
                template = "il_filter_button",
                name = "ee_il_filter_button_2",
                item = parameters[2].signal.name,
                handlers = "il.filter_button",
                save_as = "filter_button_2"
              }
            }}
          }}
        }}
      }}
    }}
  })

  gui_data.window.force_auto_center()
  gui_data.titlebar_flow.drag_target = gui_data.window

  player.opened = gui_data.window

  gui_data.entity = entity

  player_table.gui.il = gui_data
end

-- -----------------------------------------------------------------------------
-- SNAPPING
-- "Snapping" in this case usually means matching both direction and belt type

-- snaps the loader to the transport-belt-connectable entity that it's facing
-- if `entity` is supplied, it will check against that entity, and will not snap if it cannot connect to it
local function snap_loader(loader, entity)
  -- in case the loader got snapped before in the same neighbors function, don't do anything
  if loader and not loader.valid then return end

  -- if the entity was not supplied, find it
  if not entity then
    entity = loader.surface.find_entities_filtered{
      area = util.position.to_tile_area(
        util.position.add(loader.position, util.direction.to_vector(get_loader_direction(loader), 1))
      ),
      type = {"transport-belt", "underground-belt", "splitter", "loader", "loader-1x1"}
    }[1]
  end

  if entity then
    -- snap direction
    local belt_neighbors = loader.belt_neighbours
    if #belt_neighbors.inputs == 0 and #belt_neighbors.outputs == 0 then
      -- we are facing something, but cannot connect to it, so rotate and try again
      loader.rotate()
      belt_neighbors = loader.belt_neighbours
      if #belt_neighbors.inputs == 0 and #belt_neighbors.outputs == 0 then
        -- cannot connect to whatever it is, so reset and don't snap belt type
        loader.rotate()
        goto skip_belt_type
      end
    end
    -- snap belt type
    local belt_type = get_belt_type(entity)
    if get_belt_type(loader) ~= belt_type then
      loader = update_loader_type(loader, belt_type)
    end
  end
  ::skip_belt_type::

  -- update internals
  update_inserters(loader)
  update_filters(
    loader.surface.find_entities_filtered{name = "ee-infinity-loader-logic-combinator", position = loader.position}[1],
    {loader = loader}
  )
end

-- checks adjacent tiles for infinity loaders, and calls the snapping function on any it finds
function infinity_loader.snap_tile_neighbors(entity)
  for _, e in pairs(check_tile_neighbors(entity, check_is_loader, false, true)) do
    snap_loader(e, entity)
  end
end

-- checks belt neighbors for both rotations of the source entity for infinity loaders, and calls the snapping function
-- on them
function infinity_loader.snap_belt_neighbors(entity)
  local belt_neighbors = check_belt_neighbors(entity, check_is_loader, true)
  entity.rotate()
  local rev_belt_neighbors = check_belt_neighbors(entity, check_is_loader, true)
  entity.rotate()
  for _, e in ipairs(belt_neighbors) do
    snap_loader(e, entity)
  end
  for _, e in ipairs(rev_belt_neighbors) do
    snap_loader(e, entity)
  end
end

-- -----------------------------------------------------------------------------
-- COMPATIBILITY

-- PICKER DOLLIES

function infinity_loader.picker_dollies_move(e)
  local moved_entity = e.moved_entity
  if moved_entity and moved_entity.name == "ee-infinity-loader-logic-combinator" then
    local loader
    -- move all entities to new position
    for _, entity in pairs(
      e.moved_entity.surface.find_entities_filtered{
        type = {"loader-1x1", "inserter", "infinity-container"},
        position = e.start_pos
      }
    ) do
      if check_is_loader(entity) then
        -- we need to move the loader very last, after all of the other entities are in the new position
        loader = entity
      else
        entity.teleport(moved_entity.position)
      end
    end
    loader = update_loader_type(loader, get_belt_type(loader), {position = moved_entity.position})
    -- snap loader
    snap_loader(loader)
  end
end

-- -----------------------------------------------------------------------------
-- FUNCTIONS

function infinity_loader.build_from_ghost(entity)
  -- convert to dummy combinator ghost
  local old_control = entity.get_or_create_control_behavior()
  local new_entity = entity.surface.create_entity{
    name = "entity-ghost",
    ghost_name = "ee-infinity-loader-dummy-combinator",
    position = entity.position,
    direction = entity.direction,
    force = entity.force,
    player = entity.last_user,
    create_build_effect_smoke = false
  }
  -- transfer control behavior
  local new_control = new_entity.get_or_create_control_behavior()
  new_control.parameters = old_control.parameters
  new_control.enabled = old_control.enabled
  entity.destroy()
end

function infinity_loader.build(entity)
  -- create the loader with default belt type, we will snap it later
  local loader, _, _, combinator = create_loader(
    "express",
    "output",
    entity.surface,
    entity.position,
    entity.direction,
    entity.force
  )
  -- if the loader failed to build, skip the rest of the logic
  if not loader then return end
  -- get and set previous filters, if any
  local old_control = entity.get_or_create_control_behavior()
  local new_control = combinator.get_or_create_control_behavior()
  new_control.parameters = old_control.parameters
  new_control.enabled = old_control.enabled
  entity.destroy()
  -- snap new loader
  snap_loader(loader)
end

function infinity_loader.rotate(entity, previous_direction)
  -- rotate loader instead of combinator
  entity.direction = previous_direction
  local loader = entity.surface.find_entities_filtered{type = "loader-1x1", position = entity.position}[1]
  loader.rotate()
  update_inserters(loader)
  update_filters(entity, {loader = loader})
  -- snap if a loader happens to be facing directly into this loader
  infinity_loader.snap_belt_neighbors(loader)
end

function infinity_loader.destroy(entity)
  -- close open GUIs
  for i, t in pairs(global.players) do
    if t.gui.il and t.gui.il.entity == entity then
      gui.handlers.il.window.on_gui_closed{player_index = i}
    end
  end
  -- destroy entities
  local entities = entity.surface.find_entities_filtered{position = entity.position}
  for _, sub_entity in pairs(entities) do
    if string.sub(sub_entity.name, 1, 18) == "ee-infinity-loader" then
      sub_entity.destroy()
    end
  end
end

function infinity_loader.setup_blueprint(blueprint_entity)
  blueprint_entity.name = "ee-infinity-loader-dummy-combinator"
  blueprint_entity.direction = blueprint_entity.direction or defines.direction.north
  return blueprint_entity
end

function infinity_loader.paste_settings(source, destination)
  -- check if the source has control behavior
  local source_control_behavior = source.get_control_behavior()
  if source_control_behavior then
    -- sanitize filters to remove any non-items
    local parameters = {}
    local items = 0
    for _, parameter in pairs(table.deepcopy(source_control_behavior.parameters)) do
      if parameter.signal and parameter.signal.type == "item" and items < 2 then
        items = items + 1
        parameter.index = items
        table.insert(parameters, parameter)
      end
    end
    destination.get_control_behavior().parameters = parameters
    -- update filters
    update_filters(destination)
  end
end

function infinity_loader.open(player_index, entity)
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]
  create_gui(player, player_table, entity)
  player.play_sound{path = "entity-open/express-loader"}
end

-- check every single infinity loader on every surface to see if it no longer has a loader entity
-- called in on_configuration_changed
function infinity_loader.check_loaders()
  for _, surface in pairs(game.surfaces) do
    for _, entity in ipairs(surface.find_entities_filtered{name = "ee-infinity-loader-logic-combinator"}) do
      -- if its loader is gone, give it a new one with default settings
      if #surface.find_entities_filtered{type = "loader-1x1", position = entity.position} == 0 then
        snap_loader(
          update_loader_type(
            nil,
            "express",
            {
              position = entity.position,
              direction = entity.direction,
              force = entity.force,
              last_user = entity.last_user or "",
              loader_type = "output",
              surface = entity.surface
            }
          )
        )
      end
    end
  end
end

return infinity_loader