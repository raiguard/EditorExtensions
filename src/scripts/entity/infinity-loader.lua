local direction = require("__flib__.direction")
local gui = require("__flib__.gui")
local util = require("scripts.util")

local constants = require("scripts.constants")

local infinity_loader = {}

-- -----------------------------------------------------------------------------
-- LOCAL UTILITIES

local function num_inserters(entity)
  return math.ceil(entity.prototype.belt_speed / constants.belt_speed_for_60_per_second) * 2
end

-- update inserter and chest filters
local function update_filters(combinator, entities)
  entities = entities or {}
  local loader = entities.loader
    or combinator.surface.find_entities_filtered({
      type = "loader-1x1",
      position = combinator.position,
    })[1]
  local inserters = entities.inserters
    or combinator.surface.find_entities_filtered({
      name = "ee-infinity-loader-inserter",
      position = combinator.position,
    })
  local chest = entities.chest
    or combinator.surface.find_entities_filtered({
      name = "ee-infinity-loader-chest",
      position = combinator.position,
    })[1]
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
    local inserter = inserters[i]
    local orthogonal = i > (#inserters / 2) and 1 or 2
    inserter.held_stack.clear()
    inserter.set_filter(1, filters[orthogonal].signal.name or nil)
    inserter.inserter_filter_mode = inserter_filter_mode
    inserter.active = enabled
    -- if orthogonal == 1 then
    --   rendering.draw_circle{
    --     target = inserter.pickup_position,
    --     color = {r = 0, g = 1, b = 0, a = 0.5},
    --     surface = inserter.surface,
    --     radius = 0.03,
    --     filled = true,
    --     time_to_live = 180
    --   }
    --   rendering.draw_circle{
    --     target = inserter.drop_position,
    --     color = {r = 0, g = 1, b = 1, a = 0.5},
    --     surface = inserter.surface,
    --     radius = 0.03,
    --     filled = true,
    --     time_to_live = 180
    --   }
    -- end
  end
  -- update chest filters
  local i = 0
  local new_filters = {}
  for j = 1, 2 do
    local name = filters[j].signal.name
    if name then
      i = i + 1
      new_filters[i] = { name = name, count = game.item_prototypes[name].stack_size, mode = "exactly", index = i }
    end
  end
  chest.infinity_container_filters = new_filters
  chest.remove_unfiltered_items = true
end

-- update inserter pickup/drop positions
local function update_inserters(loader, entities)
  entities = entities or {}
  local surface = loader.surface
  local inserters = entities.inserters
    or surface.find_entities_filtered({
      name = "ee-infinity-loader-inserter",
      position = loader.position,
    })
  local chest = entities.chest
    or surface.find_entities_filtered({
      name = "ee-infinity-loader-chest",
      position = loader.position,
    })[1]
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
      inserters[i] = surface.create_entity({
        name = "ee-infinity-loader-inserter",
        position = loader.position,
        force = loader.force,
        direction = loader.direction,
        create_build_effect_smoke = false,
      })
      inserters[i].inserter_stack_size_override = 1
    end
    update_filters(
      surface.find_entities_filtered({ name = "ee-infinity-loader-logic-combinator", position = e_position })[1],
      { loader = loader, inserters = inserters, chest = chest }
    )
  end
  for i = 1, #inserters do
    local orthogonal = i > (#inserters / 2) and -0.25 or 0.25
    local inserter = inserters[i]
    local mod = math.min((i % (#inserters / 2)), 3)
    if e_type == "input" then
      -- pickup on belt, drop in chest
      inserter.pickup_target = loader
      inserter.pickup_position = util.position.add(
        e_position,
        direction.to_vector_2d(e_direction, (-mod * 0.2 + 0.3), orthogonal)
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
        direction.to_vector_2d(e_direction, (mod * 0.2 - 0.3), orthogonal)
      )
    end
    -- TEMPORARY rendering
    -- rendering.draw_circle{
    --   target = inserter.pickup_position,
    --   color = {r = 0, g = 1, b = 0, a = 0.5},
    --   surface = inserter.surface,
    --   radius = 0.03,
    --   filled = true,
    --   time_to_live = 180
    -- }
    -- rendering.draw_circle{
    --   target = inserter.drop_position,
    --   color = {r = 0, g = 1, b = 1, a = 0.5},
    --   surface = inserter.surface,
    --   radius = 0.03,
    --   filled = true,
    --   time_to_live = 180
    -- }
  end
end

-- update belt type of the given loader
local function update_loader_type(loader, belt_type, overrides)
  overrides = overrides or {}
  -- save settings first
  local position = overrides.position or loader.position
  local loader_direction = overrides.direction or loader.direction
  local force = overrides.force or loader.force
  local last_user = overrides.last_user or loader.last_user
  if last_user == "" then
    last_user = nil
  end
  local loader_type = overrides.loader_type or loader.loader_type
  local surface = overrides.surface or loader.surface
  if loader then
    loader.destroy()
  end
  local new_loader = surface.create_entity({
    name = "ee-infinity-loader-loader" .. (belt_type == "" and "" or "-" .. belt_type),
    position = position,
    direction = loader_direction,
    force = force,
    player = last_user,
    type = loader_type,
    create_build_effect_smoke = false,
  })
  update_inserters(new_loader)
  return new_loader
end

-- create an infinity loader
local function create_loader(type, mode, surface, position, loader_direction, force)
  local name = "ee-infinity-loader-loader" .. (type == "" and "" or "-" .. type)
  if not game.entity_prototypes[name] then
    error("Attempted to create an infinity loader with an invalid belt type.")
  end
  local loader = surface.create_entity({
    name = name,
    position = position,
    direction = loader_direction,
    force = force,
    type = mode,
    create_build_effect_smoke = false,
  })
  -- fail-out if the loader was not successfully built
  if not loader then
    return
  end
  local inserters = {}
  for i = 1, num_inserters(loader) do
    inserters[i] = surface.create_entity({
      name = "ee-infinity-loader-inserter",
      position = position,
      force = force,
      direction = loader_direction,
      create_build_effect_smoke = false,
    })
    inserters[i].inserter_stack_size_override = 1
  end
  local chest = surface.create_entity({
    name = "ee-infinity-loader-chest",
    position = position,
    force = force,
    create_build_effect_smoke = false,
  })
  local combinator = surface.create_entity({
    name = "ee-infinity-loader-logic-combinator",
    position = position,
    force = force,
    direction = mode == "input" and direction.opposite(loader_direction) or loader_direction,
    create_build_effect_smoke = false,
  })
  return loader, inserters, chest, combinator
end

-- -----------------------------------------------------------------------------
-- GUI

-- TODO: update GUI state when any other players change something

local function create_gui(player, player_table, entity)
  local preview_entity = entity.surface.find_entities_filtered({ position = entity.position, type = "loader-1x1" })[1]
  local control = entity.get_or_create_control_behavior()
  local parameters = control.parameters
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      actions = { on_closed = { gui = "il", action = "close" } },
      ref = { "window" },
      children = {
        {
          type = "flow",
          style = "flib_titlebar_flow",
          ref = { "titlebar_flow" },
          children = {
            {
              type = "label",
              style = "frame_title",
              caption = { "entity-name.ee-infinity-loader" },
              ignored_by_interaction = true,
            },
            { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
            util.close_button({ on_click = { gui = "il", action = "close" } }),
          },
        },
        {
          type = "frame",
          style = "entity_frame",
          direction = "vertical",
          children = {
            {
              type = "frame",
              style = "deep_frame_in_shallow_frame",
              children = {
                { type = "entity-preview", style = "wide_entity_button", elem_mods = { entity = preview_entity } },
              },
            },
            {
              type = "flow",
              style_mods = { vertical_align = "center" },
              children = {
                { type = "label", caption = { "ee-gui.state" } },
                { type = "empty-widget", style = "flib_horizontal_pusher" },
                {
                  type = "switch",
                  left_label_caption = { "gui-constant.on" },
                  right_label_caption = { "gui-constant.off" },
                  switch_state = control.enabled and "left" or "right",
                  actions = { on_switch_state_changed = { gui = "il", action = "toggle_enabled" } },
                },
              },
            },
            { type = "line", style_mods = { horizontally_stretchable = true }, direction = "horizontal" },
            {
              type = "flow",
              style_mods = { vertical_align = "center" },
              children = {
                {
                  type = "label",
                  caption = { "", { "ee-gui.filters" }, " [img=info]" },
                  tooltip = { "ee-gui.il-filters-description" },
                },
                { type = "empty-widget", style = "flib_horizontal_pusher" },
                {
                  type = "frame",
                  style = "slot_button_deep_frame",
                  children = {
                    {
                      type = "choose-elem-button",
                      elem_type = "item",
                      item = parameters[1].signal.name,
                      actions = { on_elem_changed = { gui = "il", action = "set_filter", index = 1 } },
                    },
                    {
                      type = "choose-elem-button",
                      elem_type = "item",
                      item = parameters[2].signal.name,
                      actions = { on_elem_changed = { gui = "il", action = "set_filter", index = 2 } },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  })

  refs.window.force_auto_center()
  refs.titlebar_flow.drag_target = refs.window

  player.opened = refs.window

  player_table.gui.il = {
    entity = entity,
    refs = refs,
  }
end

local function handle_gui_action(e, msg)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.il

  local entity = gui_data.entity

  if msg.action == "close" then
    gui_data.refs.window.destroy()
    player_table.gui.il = nil
    player.play_sound({ path = "entity-close/ee-infinity-loader-loader" })
  elseif msg.action == "toggle_enabled" then
    local entity = global.players[e.player_index].gui.il.entity
    entity.get_or_create_control_behavior().enabled = e.element.switch_state == "left"
    update_filters(entity)
  elseif msg.action == "set_filter" then
    local control = entity.get_or_create_control_behavior()
    control.set_signal(
      msg.index,
      e.element.elem_value and { signal = { type = "item", name = e.element.elem_value }, count = 1 } or nil
    )
    update_filters(entity)
  end
end

-- -----------------------------------------------------------------------------
-- SNAPPING
-- "snapping" in this case usually means matching both direction and belt type

-- snaps the loader to the transport-belt-connectable entity that it's facing
-- if `target` is supplied, it will check against that entity, and will not snap if it cannot connect to it
function infinity_loader.snap(entity, target)
  if not entity or not entity.valid then
    return
  end

  -- check for a connected belt, then flip and try again, then flip back if failed
  -- this will inherently snap the direction, and then snap the belt type if they don't match
  for _ = 1, 2 do
    local loader_type = entity.loader_type

    local connection = entity.belt_neighbours[loader_type .. "s"][1]
    if connection and (not target or connection.unit_number == target.unit_number) then
      -- snap the belt type
      local belt_type = util.get_belt_type(connection)
      if util.get_belt_type(entity) ~= belt_type then
        entity = update_loader_type(entity, belt_type)
      end
      -- update internals
      update_inserters(entity)
      update_filters(
        entity.surface.find_entities_filtered({
          name = "ee-infinity-loader-logic-combinator",
          position = entity.position,
        })[1],
        { loader = entity }
      )
      break
    else
      -- flip the direction
      entity.loader_type = loader_type == "output" and "input" or "output"
    end
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
    for _, entity in pairs(e.moved_entity.surface.find_entities_filtered({
      type = { "loader-1x1", "inserter", "infinity-container" },
      position = e.start_pos,
    })) do
      if infinity_loader.check_is_loader(entity) then
        -- we need to move the loader very last, after all of the other entities are in the new position
        loader = entity
      else
        entity.teleport(moved_entity.position)
      end
    end
    loader = update_loader_type(loader, util.get_belt_type(loader), { position = moved_entity.position })
    -- snap loader
    infinity_loader.snap(loader)
  end
end

-- -----------------------------------------------------------------------------
-- FUNCTIONS

function infinity_loader.check_is_loader(entity)
  return string.find(entity.name, "infinity%-loader%-loader")
end

function infinity_loader.build_from_ghost(entity)
  -- convert to dummy combinator ghost
  local old_control = entity.get_or_create_control_behavior()
  local new_entity = entity.surface.create_entity({
    name = "entity-ghost",
    ghost_name = "ee-infinity-loader-dummy-combinator",
    position = entity.position,
    direction = entity.direction,
    force = entity.force,
    player = entity.last_user,
    create_build_effect_smoke = false,
  })
  -- transfer control behavior
  local new_control = new_entity.get_or_create_control_behavior()
  new_control.parameters = old_control.parameters
  new_control.enabled = old_control.enabled
  entity.destroy()
end

function infinity_loader.build(entity)
  -- create the loader with default belt type, we will snap it later
  local loader, _, _, combinator = create_loader(
    global.fastest_belt_type,
    "output",
    entity.surface,
    entity.position,
    entity.direction,
    entity.force
  )
  -- if the loader failed to build, skip the rest of the logic
  if not loader then
    return
  end
  -- get and set previous filters, if any
  local old_control = entity.get_or_create_control_behavior()
  local new_control = combinator.get_or_create_control_behavior()
  new_control.parameters = old_control.parameters
  new_control.enabled = old_control.enabled
  entity.destroy()
  -- snap new loader
  infinity_loader.snap(loader)
end

function infinity_loader.rotate(entity, previous_direction)
  -- rotate loader instead of combinator
  entity.direction = previous_direction
  local loader = entity.surface.find_entities_filtered({ type = "loader-1x1", position = entity.position })[1]
  loader.rotate()
  update_inserters(loader)
  update_filters(entity, { loader = loader })

  return loader
end

function infinity_loader.destroy(entity)
  -- close open GUIs
  for i, t in pairs(global.players) do
    if t.gui.il and t.gui.il.entity == entity then
      handle_gui_action({ player_index = i }, { action = "close" })
    end
  end
  -- destroy entities
  local entities = entity.surface.find_entities_filtered({ position = entity.position })
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
      if parameter.signal and parameter.signal.type == "item" and parameter.signal.name then
        items = items + 1
        parameter.index = items
        table.insert(parameters, parameter)
        if items == 2 then
          break
        end
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
  player.play_sound({ path = "entity-open/ee-infinity-loader-loader" })
end

-- check every single infinity loader on every surface to see if it no longer has a loader entity
-- called in on_configuration_changed
function infinity_loader.check_loaders()
  for _, surface in pairs(game.surfaces) do
    for _, entity in ipairs(surface.find_entities_filtered({ name = "ee-infinity-loader-logic-combinator" })) do
      -- if its loader is gone, give it a new one with default settings
      if #surface.find_entities_filtered({ type = "loader-1x1", position = entity.position }) == 0 then
        infinity_loader.snap(update_loader_type(nil, global.fastest_belt_type, {
          position = entity.position,
          direction = entity.direction,
          force = entity.force,
          last_user = entity.last_user or "",
          loader_type = "output",
          surface = entity.surface,
        }))
      end
    end
  end
end

infinity_loader.handle_gui_action = handle_gui_action

return infinity_loader
