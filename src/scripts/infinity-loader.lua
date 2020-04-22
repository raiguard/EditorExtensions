-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INFINITY LOADER

local event = require("__RaiLuaLib__.lualib.event")
local util = require("scripts.util")

-- GUI ELEMENTS
local entity_camera = require("scripts.gui-elems.entity-camera")
local titlebar = require("scripts.gui-elems.titlebar")

local gui = {}

-- -----------------------------------------------------------------------------
-- LOCAL UTILITIES

-- pattern -> replacement
-- iterate through all of these to result in the belt type
local belt_type_patterns = {
  -- editor extensions :D
  ["ee%-infinity%-loader%-loader%-?"] = "",
  -- beltlayer: https://mods.factorio.com/mod/beltlayer
  ["layer%-connector"] = "",
  -- ultimate belts: https://mods.factorio.com/mod/UltimateBelts
  ["ultimate%-belt"] = "original-ultimate",
  -- krastorio legacy: https://mods.factorio.com/mod/Krastorio
  ["%-?kr%-01"] = "",
  ["%-?kr%-02"] = "fast",
  ["%-?kr%-03"] = "express",
  ["%-?kr%-04"] = "k",
  -- replicating belts: https://mods.factorio.com/mod/replicating-belts
  ["replicating%-?"] = "",
  -- subterranean: https://mods.factorio.com/mod/Subterranean
  ["subterranean"] = "",
  -- factorioextended plus transport: https://mods.factorio.com/mod/FactorioExtended-Plus-Transport
  ["%-to%-ground"] = "",
  -- vanilla
  ["%-?belt"] = "",
  ["%-?transport"] = "",
  ["%-?underground"] = "",
  ["%-?splitter"] = "",
  ["%-?loader"] = ""
}

local function get_belt_type(entity)
  local type = entity.name
  for pattern,replacement in pairs(belt_type_patterns) do
    type = type:gsub(pattern, replacement)
  end
  -- check to see if the loader prototype exists
  if type ~= "" and not game.entity_prototypes["ee-infinity-loader-loader-"..type] then
    -- print warning message
    game.print{"", "EDIITOR EXTENSIONS: ", {"ee-message.unable-to-identify-belt"}}
    game.print("entity_name=\""..entity.name.."\", parse_result=\""..type.."\"")
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

-- 60 items/second / 60 ticks/second / 8 items/tile = X tiles/tick
local BELT_SPEED_FOR_60_PER_SECOND = 60/60/8
local function num_inserters(entity)
  return math.ceil(entity.prototype.belt_speed / BELT_SPEED_FOR_60_PER_SECOND) * 2
end

-- update inserter and chest filters
local function update_filters(combinator, entities)
  entities = entities or {}
  local loader = entities.loader or combinator.surface.find_entities_filtered{type="loader-1x1", position=combinator.position}[1]
  local inserters = entities.inserters or combinator.surface.find_entities_filtered{name="ee-infinity-loader-inserter", position=combinator.position}
  local chest = entities.chest or combinator.surface.find_entities_filtered{name="ee-infinity-loader-chest", position=combinator.position}[1]
  local control = combinator.get_control_behavior()
  local enabled = control.enabled
  local filters = control.parameters.parameters
  local inserter_filter_mode
  if filters[1].signal.name or filters[2].signal.name or loader.loader_type == "output" then
    inserter_filter_mode = "whitelist"
  elseif loader.loader_type == "input" then
    inserter_filter_mode = "blacklist"
  end
  -- update inserter filter based on orthogonal
  for i=1,#inserters do
    local orthogonal = i > (#inserters/2) and 1 or 2
    inserters[i].set_filter(1, filters[orthogonal].signal.name or nil)
    inserters[i].inserter_filter_mode = inserter_filter_mode
    inserters[i].active = enabled
  end
  -- update chest filters
  for i=1,2 do
    local name = filters[i].signal.name
    chest.set_infinity_container_filter(i, name and {name=name, count=game.item_prototypes[name].stack_size, mode="exactly", index=i} or nil)
  end
  chest.remove_unfiltered_items = true
end

-- update inserter pickup/drop positions
local function update_inserters(loader, entities)
  entities = entities or {}
  local surface = loader.surface
  local inserters = entities.inserters or surface.find_entities_filtered{name="ee-infinity-loader-inserter", position=loader.position}
  local chest = entities.chest or surface.find_entities_filtered{name="ee-infinity-loader-chest", position=loader.position}[1]
  local e_type = loader.loader_type
  local e_position = loader.position
  local e_direction = loader.direction
  -- update number of inserters if needed
  if #inserters ~= num_inserters(loader) then
    for _,e in ipairs(inserters) do
      e.destroy()
    end
    inserters = {}
    for i=1,num_inserters(loader) do
      inserters[i] = surface.create_entity{
        name="ee-infinity-loader-inserter",
        position = loader.position,
        force = loader.force,
        direction = loader.direction,
        create_build_effect_smoke = false
      }
      inserters[i].inserter_stack_size_override = 1
    end
    update_filters(
      surface.find_entities_filtered{name="ee-infinity-loader-logic-combinator", position=e_position}[1],
      {loader=loader, inserters=inserters, chest=chest}
    )
  end
  for i=1,#inserters do
    local orthogonal = i > (#inserters/2) and -0.25 or 0.25
    local inserter = inserters[i]
    local mod = math.min((i % (#inserters/2)),3)
    if e_type == "input" then
      -- pickup on belt, drop in chest
      inserter.pickup_target = loader
      inserter.pickup_position = util.position.add(e_position, util.direction.to_vector(e_direction, (-mod*0.2 + 0.3), orthogonal))
      inserter.drop_target = chest
      inserter.drop_position = e_position
    elseif e_type == "output" then
      -- pickup from chest, drop on belt
      inserter.pickup_target = chest
      inserter.pickup_position = chest.position
      inserter.drop_target = loader
      inserter.drop_position = util.position.add(e_position, util.direction.to_vector(e_direction, (mod*0.2 - 0.3), orthogonal))
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
  if not game.entity_prototypes[name] then error("Attempted to create an infinity loader with an invalid belt type.") end
  local loader = surface.create_entity{
    name = name,
    position = position,
    direction = direction,
    force = force,
    type = mode,
    create_build_effect_smoke = false
  }
  local inserters = {}
  for i=1,num_inserters(loader) do
     inserters[i] = surface.create_entity{
      name="ee-infinity-loader-inserter",
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

-- apply the function to each belt neighbor connected to this entity, and return entities for which the function returned true
local function check_belt_neighbors(entity, func, type_agnostic)
  local belt_neighbors = entity.belt_neighbours
  local matched_entities = {}
  for _,type in pairs{"inputs", "outputs"} do
    if not type_agnostic then matched_entities[type] = {} end
    for _,e in ipairs(belt_neighbors[type] or {}) do
      if func(e) then
        table.insert(type_agnostic and matched_entities or matched_entities[type], e)
      end
    end
  end
  return matched_entities
end

-- apply the function to each entity on neighboring tiles, returning entities for which the function returned true
local function check_tile_neighbors(entity, func, eight_way, dir_agnostic)
  local matched_entities = {}
  for i=0,7,eight_way and 1 or 2 do
    if not dir_agnostic then matched_entities[i] = {} end
    local entities = entity.surface.find_entities(util.position.to_tile_area(util.position.add(entity.position, util.direction.to_vector(i, 1))))
    for _,e in ipairs(entities) do
      if func(e) then
        table.insert(dir_agnostic and matched_entities or matched_entities[i], e)
      end
    end
  end
  return matched_entities
end

-- -----------------------------------------------------------------------------
-- GUI

-- ----------------------------------------
-- GUI HANDLERS

local function close_button_clicked(e)
  -- invoke GUI closed event
  event.raise(defines.events.on_gui_closed, {element=e.element.parent.parent, gui_type=16, player_index=e.player_index, tick=game.tick})
end

local function state_switch_state_changed(e)
  local entity = global.players[e.player_index].gui.il.entity
  entity.get_or_create_control_behavior().enabled = e.element.switch_state == "left"
  update_filters(entity)
end

local function filter_button_elem_changed(e)
  local index = e.element.name:gsub("ee_il_filter_button_", "")
  local entity = global.players[e.player_index].gui.il.entity
  local control = entity.get_or_create_control_behavior()
  control.set_signal(index, e.element.elem_value and {signal={type="item", name=e.element.elem_value}, count=1} or nil)
  update_filters(entity)
end

event.register_conditional{
  il_close_button_clicked = {id=defines.events.on_gui_click, handler=close_button_clicked, group="il_gui"},
  il_state_switch_state_changed = {id=defines.events.on_gui_switch_state_changed, handler=state_switch_state_changed, group="il_gui"},
  il_filter_button_elem_changed = {id=defines.events.on_gui_elem_changed, handler=filter_button_elem_changed, group="il_gui"}
}

-- ----------------------------------------
-- GUI MANAGEMENT

function gui.create(parent, entity, player)
  local control = entity.get_or_create_control_behavior()
  local parameters = control.parameters.parameters
  local window = parent.add{type="frame", name="ee_il_window", style="dialog_frame", direction="vertical"}
  local titlebar = titlebar.create(window, "ee_il_titlebar", {
    draggable = true,
    label = {"entity-name.ee-infinity-loader"},
    buttons = {util.constants.close_button_def}
  })
  event.enable("il_close_button_clicked", player.index, titlebar.children[3].index)
  local content_flow = window.add{type="flow", name="ee_il_content_flow", style="ee_entity_window_content_flow", direction="horizontal"}
  local camera = entity_camera.create(content_flow, "ee_il_camera", 90, {player=player, entity=entity, camera_zoom=1})
  local page_frame = content_flow.add{type="frame", name="ee_il_page_frame", style="ee_ia_page_frame", direction="vertical"}
  page_frame.style.width = 160
  local state_flow = page_frame.add{type="flow", name="ee_il_state_flow", style="ee_vertically_centered_flow", direction="horizontal"}
  state_flow.add{type="label", name="ee_il_state_label", caption={"", {"gui-infinity-loader.state-label-caption"}, " [img=info]"},
    tooltip={"gui-infinity-loader.state-label-tooltip"}}
  state_flow.add{type="empty-widget", name="ee_il_state_pusher", style="ee_invisible_horizontal_pusher"}
  local state_switch = state_flow.add{type="switch", name="ee_il_state_switch", left_label_caption={"gui-constant.on"},
    right_label_caption={"gui-constant.off"}, switch_state=control.enabled and "left" or "right"}
  event.enable("il_state_switch_state_changed", player.index, state_switch.index)
  page_frame.add{type="empty-widget", name="ee_il_page_pusher", style="ee_invisible_vertical_pusher"}
  local filters_flow = page_frame.add{type="flow", name="ee_il_filters_flow", style="ee_vertically_centered_flow", direction="horizontal"}
  filters_flow.add{type="label", name="ee_il_filters_label", caption={"", {"gui-infinity-loader.filters-label-caption"}, " [img=info]"},
    tooltip={"gui-infinity-loader.filters-label-tooltip"}}
  filters_flow.add{type="empty-widget", name="ee_il_filters_pusher", style="ee_invisible_horizontal_pusher", direction="horizontal"}
  event.enable("il_filter_button_elem_changed", player.index, {
    filters_flow.add{type="choose-elem-button", name="ee_il_filter_button_1", style="ee_infinity_loader_filter_button", elem_type="item",
      item=parameters[1].signal.name}.index,
    filters_flow.add{type="choose-elem-button", name="ee_il_filter_button_2", style="ee_infinity_loader_filter_button", elem_type="item",
      item=parameters[2].signal.name}.index
  })
  window.force_auto_center()
  return {window=window, camera=camera}
end

function gui.destroy(player_index, player_table)
  event.disable_group("il_gui", player_index)
  player_table.gui.il.elems.window.destroy()
  player_table.gui.il = nil
end

-- -----------------------------------------------------------------------------
-- SNAPPING
-- "Snapping" in this case usually means matching both direction and belt type

-- snapping blacklist - see remote interface documentation
local snapping_blacklist = {}

-- snaps the loader to the transport-belt-connectable entity that it's facing
-- if entity is supplied, it will check against that entity, and will not snap if it cannot connect to it (is not facing it)
local function snap_loader(loader, entity)
  -- in case the loader got snapped before in the same neighbors function, don't do anything
  if loader and not loader.valid then return end
  -- if the entity was not supplied, find it
  if not entity then
    entity = loader.surface.find_entities_filtered{
      area = util.position.to_tile_area(util.position.add(loader.position, util.direction.to_vector(get_loader_direction(loader), 1))),
      type = {"transport-belt", "underground-belt", "splitter", "loader-1x1"}
    }[1]
  end
  local snapped = false
  -- if the entity exists and is not on the blacklist
  if entity and not snapping_blacklist[entity.name] then
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
    snapped = true -- this will be skipped if the snapping did not occur, so it will be false
  end
  ::skip_belt_type::
  -- update internals
  update_inserters(loader)
  update_filters(
    loader.surface.find_entities_filtered{name="ee-infinity-loader-logic-combinator", position=loader.position}[1],
    {loader=loader}
  )
  -- raise event if snapping occured
  if snapped then
    event.raise(event.get_id("il_on_loader_snapped"), {loader=loader, snapped_to=entity})
  end
end

-- checks adjacent tiles for infinity loaders, and calls the snapping function on any it finds
local function snap_tile_neighbors(entity)
  for _,e in pairs(check_tile_neighbors(entity, check_is_loader, false, true)) do
    snap_loader(e, entity)
  end
end

-- checks belt neighbors for both rotations of the source entity for infinity loaders, and calls the snapping function on them
local function snap_belt_neighbors(entity)
  local belt_neighbors = check_belt_neighbors(entity, check_is_loader, true)
  entity.rotate()
  local rev_belt_neighbors = check_belt_neighbors(entity, check_is_loader, true)
  entity.rotate()
  for _,e in ipairs(belt_neighbors) do
    snap_loader(e, entity)
  end
  for _,e in ipairs(rev_belt_neighbors) do
    snap_loader(e, entity)
  end
end

-- -----------------------------------------------------------------------------
-- COMPATIBILITY

--
-- PICKER DOLLIES
--

local function picker_dollies_move(e)
  local entity = e.moved_entity
  if entity.name == "ee-infinity-loader-logic-combinator" then
    local loader
    -- move all entities to new position
    for _,e in pairs(e.moved_entity.surface.find_entities_filtered{type={"loader-1x1", "inserter", "infinity-container"}, position=e.start_pos}) do
      if check_is_loader(e) then
        -- loaders don't support teleportation, so destroy and recreate it
        loader = update_loader_type(e, get_belt_type(e), {position=entity.position})
      else
        e.teleport(entity.position)
      end
    end
    -- snap loader
    snap_loader(loader)
  end
end
event.on_init(function()
  if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
    event.register(remote.call("PickerDollies", "dolly_moved_entity_id"), picker_dollies_move)
  end
end)
event.on_load(function()
  if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
    event.register(remote.call("PickerDollies", "dolly_moved_entity_id"), picker_dollies_move)
  end
end)

--
-- REMOTE INTERFACES
-- docs: https://github.com/raiguard/Factorio-EditorExtensions/wiki/Remote-Interface-Documentation
--

-- get all loader entities at a certain position
local function get_loader_entities(surface, position)
  local find = surface.find_entities_filtered
  return find{type="loader-1x1", position=position}[1],
         find{type="inserter", position=position},
         find{name="ee-infinity-loader-chest", position=position}[1],
         find{name="ee-infinity-loader-logic-combinator", position=position}[1]
end

event.get_id("il_on_loader_snapped")
remote.add_interface("ee_infinity_loader", {
  -- FUNCTIONS
  get_loader_entities = get_loader_entities,
  get_belt_type = get_belt_type,
  add_to_blacklist = function(name) snapping_blacklist[name] = true end,
  remove_from_blacklist = function(name) snapping_blacklist[name] = nil end,
  get_blacklist = function() return snapping_blacklist end,
  -- EVENTS
  on_loader_snapped = function() return event.get_id("il_on_loader_snapped") end
})

-- -----------------------------------------------------------------------------
-- STATIC HANDLERS

-- when an entity is built in-game of through script, or constructed or revived through script
event.register(util.constants.entity_built_events, function(e)
  local entity = e.created_entity or e.entity
  if entity.name == "entity-ghost" and entity.ghost_name == "ee-infinity-loader-logic-combinator" then
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
    -- raise event
    event.raise(defines.events.script_raised_built, {entity=new_entity, tick=game.tick})
  elseif entity.name == "ee-infinity-loader-dummy-combinator" or entity.name == "ee-infinity-loader-logic-combinator" then
    -- create the loader with default belt type, we will snap it later
    local loader, inserters, chest, combinator = create_loader("express", "output", entity.surface, entity.position, entity.direction, entity.force)
    -- get and set previous filters, if any
    local old_control = entity.get_or_create_control_behavior()
    local new_control = combinator.get_or_create_control_behavior()
    new_control.parameters = old_control.parameters
    new_control.enabled = old_control.enabled
    entity.destroy()
    -- snap new loader
    snap_loader(loader)
  elseif entity.type == "transport-belt" then
    -- snap neighbors
    snap_tile_neighbors(entity)
  elseif entity.type == "underground-belt" then
    -- snap neighbors of both sides
    snap_tile_neighbors(entity)
    if entity.neighbours then
      snap_tile_neighbors(entity)
    end
  elseif entity.type == "splitter" or entity.type == "loader-1x1" then
    -- snap belt neighbors
    snap_belt_neighbors(entity)
  end
end)

-- when an entity is rotated
event.register(defines.events.on_player_rotated_entity, function(e)
  local entity = e.entity
  if entity.name == "ee-infinity-loader-logic-combinator" then
    -- rotate loader instead of combinator
    entity.direction = e.previous_direction
    local loader = entity.surface.find_entities_filtered{type="loader-1x1", position=entity.position}[1]
    loader.rotate()
    update_inserters(loader)
    update_filters(entity, {loader=loader})
  elseif entity.type == "transport-belt" then
    -- snap neighbors
    snap_tile_neighbors(entity)
  elseif entity.type == "underground-belt" then
    -- snap neighbors of both sides
    snap_tile_neighbors(entity)
    if entity.neighbours then
      snap_tile_neighbors(entity.neighbours)
    end
  elseif entity.type == "splitter" or entity.type == "loader-1x1" then
    -- snap belt neighbors
    snap_belt_neighbors(entity)
  end
end)

-- when an entity is destroyed
event.register(util.constants.entity_destroyed_events, function(e)
  local entity = e.entity
  if entity.name == "ee-infinity-loader-logic-combinator" then
    -- close open GUIs
    if global.__lualib.event.il_close_button_clicked then
      for _,i in ipairs(global.__lualib.event.il_close_button_clicked.players) do
        local player_table = global.players[i]
        -- check if they're viewing this one
        if player_table.gui.il.entity == entity then
          gui.destroy(player_table.gui.il.elems.window, e.player_index)
          player_table.gui.il = nil
        end
      end
    end
    local entities = entity.surface.find_entities_filtered{position=entity.position}
    for _,e in pairs(entities) do
      if e.name:find("infinity%-loader") then
        e.destroy()
      end
    end
  end
end)

-- when a player selects an area for blueprinting
event.register(defines.events.on_player_setup_blueprint, function(e)
  local player = game.get_player(e.player_index)
  local bp = player.blueprint_to_setup
  if not bp or not bp.valid_for_read then
    bp = player.cursor_stack
  end
  local entities = bp.get_blueprint_entities()
  if not entities then return end
  for i=1,#entities do
    if entities[i].name == "ee-infinity-loader-logic-combinator" then
      entities[i].name = "ee-infinity-loader-dummy-combinator"
      entities[i].direction = entities[i].direction or defines.direction.north
    end
  end
  bp.set_blueprint_entities(entities)
end)

-- when an entity settings copy/paste occurs
event.register(defines.events.on_entity_settings_pasted, function(e)
  if e.destination.name == "ee-infinity-loader-logic-combinator" then
    -- sanitize filters to remove any non-ttems
    local parameters = {parameters={}}
    local items = 0
    for i,p in pairs(table.deepcopy(e.source.get_control_behavior().parameters.parameters)) do
      if p.signal and p.signal.type == "item" and items < 2 then
        items = items + 1
        p.index = items
        table.insert(parameters.parameters, p)
      end
    end
    e.destination.get_control_behavior().parameters = parameters
    -- update filters
    update_filters(e.destination)
  end
end)

-- when a player opens a GUI
event.register(defines.events.on_gui_opened, function(e)
  if e.entity and e.entity.name == "ee-infinity-loader-logic-combinator" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    local elems = gui.create(player.gui.screen, e.entity, player)
    player.opened = elems.window
    player_table.gui.il = {elems=elems, entity=e.entity}
  end
end)

-- when a GUI is closed
event.register(defines.events.on_gui_closed, function(e)
  if e.gui_type == 16 and e.element and e.element.name == "ee_il_window" then
    gui.destroy(e.player_index, global.players[e.player_index])
  end
end)

-- when mod configuration changes
event.on_configuration_changed(function(e)
  -- check every single infinity loader on every surface to see if it no longer has a loader entity
  for _,surface in pairs(game.surfaces) do
    for _,entity in ipairs(surface.find_entities_filtered{name="ee-infinity-loader-logic-combinator"}) do
      -- if its loader is gone, give it a new one with default settings
      if #surface.find_entities_filtered{type="loader-1x1", position=entity.position} == 0 then
        snap_loader(
          update_loader_type(nil, "express", {position=entity.position, direction=entity.direction, force=entity.force, last_user=entity.last_user or "",
            loader_type="output", surface=entity.surface})
        )
      end
    end
  end
end)

-- -----------------------------------------------------------------------------
-- OBJECT

local self = {}

-- for use in migrations, takes a lonesome logic combinator and builds the internals
function self.build_loader(entity)
  -- create the loader with default belt type, we will snap it later
  local loader, inserters, chest, combinator = create_loader("express", "output", entity.surface, entity.position, entity.direction, entity.force)
  -- get and set previous filters, if any
  local old_control = entity.get_or_create_control_behavior()
  local new_control = combinator.get_or_create_control_behavior()
  new_control.parameters = old_control.parameters
  new_control.enabled = old_control.enabled
  entity.destroy()
  -- snap new loader
  snap_loader(loader)
end

return self