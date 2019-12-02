-- ----------------------------------------------------------------------------------------------------
-- INFINITY LOADER

local event = require('scripts/lib/event')
local util = require('scripts/lib/util')

-- GUI ELEMENTS
local entity_camera = require('scripts/lib/gui-elems/entity-camera')
local titlebar = require('scripts/lib/gui-elems/titlebar')

local gui = {}

-- --------------------------------------------------
-- LOCAL UTILITIES

-- pattern -> replacement
-- iterate through all of these to result in the belt type
local belt_type_patterns = {
    -- editor extensions :D
    ['infinity%-'] = '',
    ['loader%-loader%-?'] = '',
    -- beltlayer: https://mods.factorio.com/mod/beltlayer
    ['layer%-connector'] = '',
    -- ultimate belts: https://mods.factorio.com/mod/UltimateBelts
    ['ultimate%-belt'] = 'original-ultimate',
    -- krastorio: https://mods.factorio.com/mod/Krastorio
    ['%-?kr%-01'] = '',
    ['%-?kr%-02'] = 'fast',
    ['%-?kr%-03'] = 'express',
    ['%-?kr%-04'] = 'k',
    ['%-?kr'] = '',
    -- replicating belts: https://mods.factorio.com/mod/replicating-belts
    ['replicating%-?'] = '',
    -- subterranean: https://mods.factorio.com/mod/Subterranean
    ['subterranean'] = '',
    -- vanilla
    ['%-?belt'] = '',
    ['%-?transport'] = '',
    ['%-?underground'] = '',
    ['%-?splitter'] = '',
    ['%-?loader'] = ''
}

local function get_belt_type(entity)
    local type = entity.name
    for pattern,replacement in pairs(belt_type_patterns) do
        type = type:gsub(pattern, replacement)
    end
    -- check to see if the loader prototype exists
    if type ~= '' and not game.entity_prototypes['infinity-loader-loader-'..type] then
        -- print warning message
        game.print{'', 'EDIITOR EXTENSIONS: ', {'chat-message.unable-to-identify-belt-warning'}}
        game.print('belt_name=\''..entity.name..'\', parse_result=\''..type..'\'')
        -- set to default type
        type = 'express'
    end
	return type
end

local function check_is_loader(entity)
    if entity.name:find('infinity%-loader%-loader') then return true end
    return false
end

local function to_vector_2d(direction, longitudinal, orthogonal)
    if direction == defines.direction.north then
        return {x=orthogonal, y=-longitudinal}
    elseif direction == defines.direction.south then
        return {x=-orthogonal, y=longitudinal}
    elseif direction == defines.direction.east then
        return {x=longitudinal, y=orthogonal}
    elseif direction == defines.direction.west then
        return {x=-longitudinal, y=-orthogonal}
    end
end

-- get the direction that the mouth of the loader is facing
local function get_loader_direction(loader)
    if loader.loader_type == 'input' then
        return util.oppositedirection(loader.direction)
    end
    return loader.direction
end

-- 60 items/second / 60 ticks/second / 8 items/tile = X tiles/tick
local BELT_SPEED_FOR_60_PER_SECOND = 60/60/8
local function num_inserters(entity)
  return math.ceil(entity.prototype.belt_speed / BELT_SPEED_FOR_60_PER_SECOND) * 2
end

-- update inserter pickup/drop positions
local function update_inserters(loader)
    local inserters = loader.surface.find_entities_filtered{name='infinity-loader-inserter', position=loader.position}
    local chest = loader.surface.find_entities_filtered{name='infinity-loader-chest', position=loader.position}[1]
    local e_type = loader.loader_type
    local e_position = loader.position
    local e_direction = loader.direction
    for i=1,#inserters do
        local side = i > (#inserters/2) and -0.25 or 0.25
        local inserter = inserters[i]
        local mod = math.min((i % (#inserters/2)),3)
        if e_type == 'input' then
            -- pickup on belt, drop in chest
            inserter.pickup_target = loader
            inserter.pickup_position = util.position.add(e_position, to_vector_2d(e_direction,(-mod*0.2 + 0.3),side))
            inserter.drop_target = chest
            inserter.drop_position = e_position
        elseif e_type == 'output' then
            -- pickup from chest, drop on belt
            inserter.pickup_target = chest
            inserter.pickup_position = chest.position
            inserter.drop_target = loader
            inserter.drop_position = util.position.add(e_position, to_vector_2d(e_direction,(mod*0.2 - 0.3),side))
        end
        -- TEMPORARY rendering
        -- rendering.draw_circle{target=inserter.pickup_position, color={r=0,g=1,b=0,a=0.5}, surface=loader.surface, radius=0.03, filled=true, time_to_live=180}
        -- rendering.draw_circle{target=inserter.drop_position, color={r=0,g=1,b=1,a=0.5}, surface=loader.surface, radius=0.03, filled=true, time_to_live=180}
    end
end

-- update inserter and chest filters
local function update_filters(entity)
    local loader = entity.surface.find_entities_filtered{type='loader', position=entity.position}[1]
    local inserters = entity.surface.find_entities_filtered{name='infinity-loader-inserter', position=entity.position}
    local chest = entity.surface.find_entities_filtered{name='infinity-loader-chest', position=entity.position}[1]
    local control = entity.get_control_behavior()
    local enabled = control.enabled
    local filters = control.parameters.parameters
    local inserter_filter_mode
    if filters[1].signal.name or filters[2].signal.name or loader.loader_type == 'output' then
        inserter_filter_mode = 'whitelist'
    elseif loader.loader_type == 'input' then
        inserter_filter_mode = 'blacklist'
    end
    -- update inserter filter based on side
    for i=1,#inserters do
        local side = i > (#inserters/2) and 1 or 2
        inserters[i].set_filter(1, filters[side].signal.name or nil)
        inserters[i].inserter_filter_mode = inserter_filter_mode
        inserters[i].active = enabled
    end
    -- update chest filters
    for i=1,2 do
        local name = filters[i].signal.name
        chest.set_infinity_container_filter(i, name and {name=name, count=game.item_prototypes[name].stack_size, mode='exactly', index=i} or nil)
    end
    chest.remove_unfiltered_items = true
end

-- create an infinity loader
local function create_loader(type, mode, surface, position, direction, force, skip_combinator)
    local loader = surface.create_entity{
        name = 'infinity-loader-loader' .. (type == '' and '' or '-'..type),
        position = position,
        direction = direction,
        force = force,
        type = mode,
        create_build_effect_smoke = false
    }
    local inserters = {}
    for i=1,num_inserters(loader) do
         inserters[i] = surface.create_entity{
            name='infinity-loader-inserter',
            position = position,
            force = force,
            direction = direction,
            create_build_effect_smoke = false
        }
        inserters[i].inserter_stack_size_override = 1
    end
    local chest = surface.create_entity{
        name = 'infinity-loader-chest',
        position = position,
        force = force,
        create_build_effect_smoke = false
    }
    local combinator
    if not skip_combinator then
        combinator = surface.create_entity{
            name = 'infinity-loader-logic-combinator',
            position = position,
            force = force,
            direction = mode == 'input' and util.oppositedirection(direction) or direction,
            create_build_effect_smoke = false
        }
    end
    return loader, inserters, chest, combinator
end

local function update_loader_type(belt_type, entity)
	-- old loader has to be destroyed first, so save its info here
	local position = entity.position
	local force = entity.force
	local direction = entity.direction
	local mode = entity.loader_type
	local surface = entity.surface
	local combinator = entity.surface.find_entities_filtered{name='infinity-loader-logic-combinator', position=position}[1]
	local control = combinator.get_control_behavior()
	local parameters = control.parameters
    local enabled = control.enabled
	-- destroy combinator and raise event, which will cause everything else to be destroyed as well
	combinator.destroy{raise_destroy=true}
	-- create new loader, sync filters
	local new_loader, new_inserters, new_chest, new_combinator = create_loader(belt_type, mode, surface, position, direction, force)
	local new_control = new_combinator.get_or_create_control_behavior()
	new_control.parameters = parameters
	new_control.enabled = enabled
	update_inserters(new_loader)
    update_filters(new_combinator)
    return new_loader
end

-- --------------------------------------------------
-- GUI

-- -------------------------
-- GUI HANDLERS

local function close_button_clicked(e)
    -- invoke GUI closed event
    event.raise(defines.events.on_gui_closed, {element=e.element.parent.parent, gui_type=16, player_index=e.player_index, tick=game.tick})
end

local function state_switch_state_changed(e)
    local entity = util.player_table(e.player_index).gui.il.entity
    entity.get_or_create_control_behavior().enabled = e.element.switch_state == 'left'
    update_filters(entity)
end

local function filter_button_elem_changed(e)
    local index = e.element.name:gsub('ee_il_filter_button_', '')
    local entity = util.player_table(e.player_index).gui.il.entity
    local control = entity.get_or_create_control_behavior()
    control.set_signal(index, e.element.elem_value and {signal={type='item', name=e.element.elem_value}, count=1} or nil)
    update_filters(entity)
end

local handlers = {
    il_close_button_clicked = close_button_clicked,
    il_state_switch_state_changed = state_switch_state_changed,
    il_filter_button_elem_changed = filter_button_elem_changed
}

event.on_load(function()
    event.load_conditional_handlers(handlers)
end)

-- -------------------------
-- GUI MANAGEMENT

function gui.create(parent, entity, player)
    local control = entity.get_or_create_control_behavior()
    local parameters = control.parameters.parameters
    local window = parent.add{type='frame', name='ee_il_window', style='dialog_frame', direction='vertical'}
    local titlebar = titlebar.create(window, 'ee_il_titlebar', {
        draggable = true,
        label = {'entity-name.infinity-loader'},
        buttons = {util.constants.close_button_def}
    })
    event.gui.on_click(titlebar.children[3], close_button_clicked, 'il_close_button_clicked', player.index)
    local content_flow = window.add{type='flow', name='ee_il_content_flow', style='ee_entity_window_content_flow', direction='horizontal'}
    local camera = entity_camera.create(content_flow, 'ee_il_camera', 90, {player=player, entity=entity, camera_zoom=1})
    local page_frame = content_flow.add{type='frame', name='ee_il_page_frame', style='ee_ia_page_frame', direction='vertical'}
    page_frame.style.width = 160
    local state_flow = page_frame.add{type='flow', name='ee_il_state_flow', style='ee_vertically_centered_flow', direction='horizontal'}
    state_flow.add{type='label', name='ee_il_state_label', caption={'', {'gui-infinity-loader.state-label-caption'}, ' [img=info]'},
                   tooltip={'gui-infinity-loader.state-label-tooltip'}}
    state_flow.add{type='empty-widget', name='ee_il_state_pusher', style='ee_invisible_horizontal_pusher'}
    local state_switch = state_flow.add{type='switch', name='ee_il_state_switch', left_label_caption={'gui-constant.on'},
                                        right_label_caption={'gui-constant.off'}, switch_state=control.enabled and 'left' or 'right'}
    event.gui.on_switch_state_changed(state_switch, state_switch_state_changed, 'il_state_switch_state_changed', player.index)
    page_frame.add{type='empty-widget', name='ee_il_page_pusher', style='ee_invisible_vertical_pusher'}
    local filters_flow = page_frame.add{type='flow', name='ee_il_filters_flow', style='ee_vertically_centered_flow', direction='horizontal'}
    filters_flow.add{type='label', name='ee_il_filters_label', caption={'', {'gui-infinity-loader.filters-label-caption'}, ' [img=info]'},
                   tooltip={'gui-infinity-loader.filters-label-tooltip'}}
    filters_flow.add{type='empty-widget', name='ee_il_filters_pusher', style='ee_invisible_horizontal_pusher', direction='horizontal'}
    filters_flow.add{type='choose-elem-button', name='ee_il_filter_button_1', style='ee_slot_button_light', elem_type='item', item=parameters[1].signal.name}
    event.gui.on_elem_changed({name_match={'ee_il_filter_button'}}, filter_button_elem_changed, 'il_filter_button_elem_changed', player.index)
    filters_flow.add{type='choose-elem-button', name='ee_il_filter_button_2', style='ee_slot_button_light', elem_type='item', item=parameters[2].signal.name}
    window.force_auto_center()
    return {window=window, camera=camera}
end

function gui.destroy(window, player_index)
    -- deregister all GUI events if needed
    local con_registry = global.conditional_event_registry
    for cn,h in pairs(handlers) do
        event.gui.deregister(con_registry[cn].id, h, cn, player_index)
    end
    window.destroy()
end

-- --------------------------------------------------
-- SNAPPING
-- 'Snapping' in this case usually means matching both direction and belt type

-- snaps the loader to the transport-belt-connectable entity that it's facing
-- if entity is supplied, it will check against that entity, and will not snap if it cannot connect to it (is not facing it)
local function snap_loader(loader, entity)
    -- if the entity was not supplied, find it
    if not entity then
        entity = loader.surface.find_entities_filtered{
            area = util.position.to_tile_area(util.position.add(loader.position, util.constants.neighbor_tile_vectors[get_loader_direction(loader)])),
            type = {'transport-belt', 'underground-belt', 'splitter', 'loader'}
        }[1]
        if not entity then
             -- could not find an entity to connect to, so don't do any snapping
             -- update internals
            update_inserters(loader)
            update_filters(loader.surface.find_entities_filtered{name='infinity-loader-logic-combinator', position=loader.position}[1])
            return
        end
    end
    -- snap direction
    local belt_neighbors = loader.belt_neighbours
    if #belt_neighbors.inputs == 0 and #belt_neighbors.outputs == 0 then
        -- we are facing something, but cannot connect to it, so rotate and try again
        loader.rotate()
        belt_neighbors = loader.belt_neighbours
        if #belt_neighbors.inputs == 0 and #belt_neighbors.outputs == 0 then
            -- cannot connect to whatever it is, so don't snap
            loader.rotate()
            return
        end
    end
    -- snap belt type
    if get_belt_type(loader) ~= get_belt_type(entity) then
        loader = update_loader_type(get_belt_type(entity), loader)
    end
    -- update internals
    update_inserters(loader)
    update_filters(loader.surface.find_entities_filtered{name='infinity-loader-logic-combinator', position=loader.position}[1])
end

-- checks adjacent tiles for infinity loaders, and calls the snapping function on any it finds
local function snap_neighboring_loaders(entity)
    for _,e in pairs(util.entity.check_tile_neighbors(entity, check_is_loader, false, true)) do
        snap_loader(e, entity)
    end
end

-- checks belt neighbors for both rotations of the source entity for infinity loaders, and calls the snapping function on them
local function snap_belt_neighbors(entity)
    local belt_neighbors = util.entity.check_belt_neighbors(entity, check_is_loader, true)
    entity.rotate()
    local rev_belt_neighbors = util.entity.check_belt_neighbors(entity, check_is_loader, true)
    entity.rotate()
    for _,e in ipairs(belt_neighbors) do
        snap_loader(e, entity)
    end
    for _,e in ipairs(rev_belt_neighbors) do
        snap_loader(e, entity)
    end
end

-- ----------------------------------------------------------------------------------------------------
-- COMPATIBILITY

--
-- PICKER DOLLIES
--

local function picker_dollies_move(e)
    local entity = e.moved_entity
    if entity.name == 'infinity-loader-logic-combinator' then
        -- destroy all entities in the previous position
        for _,e in pairs(e.moved_entity.surface.find_entities_filtered{position=e.start_pos}) do
            e.destroy()
        end
        local loader, inserters, chest = create_loader('express', 'output', entity.surface, entity.position, entity.direction, entity.force, true)
        snap_loader(loader)
    end
end
event.on_init(function()
    if remote.interfaces['PickerDollies'] and remote.interfaces['PickerDollies']['dolly_moved_entity_id'] then
        event.register(remote.call('PickerDollies', 'dolly_moved_entity_id'), picker_dollies_move)
    end
end)
event.on_load(function()
    if remote.interfaces['PickerDollies'] and remote.interfaces['PickerDollies']['dolly_moved_entity_id'] then
        event.register(remote.call('PickerDollies', 'dolly_moved_entity_id'), picker_dollies_move)
    end
end)

-- --------------------------------------------------
-- STATIC HANDLERS

-- interface to allow conditional on_tick to update the filters
remote.add_interface('ee_infinity_loader', {
    create_loader = create_loader,
    update_loader_filters = update_filters,
    update_loader_inserters = update_inserters,
    snap_loader = snap_loader,
    snap_neighboring_loaders = snap_neighboring_loaders,
    snap_belt_neighbors = snap_belt_neighbors
})

event.register(util.constants.entity_built_events, function(e)
    local entity = e.created_entity or e.entity
    if entity.name == 'infinity-loader-dummy-combinator' or entity.name == 'infinity-loader-logic-combinator' then
        -- just place the loader with the default values. belt_neighbors requires both entities to exist, so type/mode get set later
        local direction = entity.direction
        local loader, inserters, chest, combinator = create_loader('express', 'output', entity.surface, entity.position, direction, entity.force)
        -- get previous filters, if any
        local old_control = entity.get_or_create_control_behavior()
        local new_control = combinator.get_or_create_control_behavior()
        new_control.parameters = old_control.parameters
        new_control.enabled = old_control.enabled
        entity.destroy()
        -- update entity
        snap_loader(loader)
    elseif entity.type == 'transport-belt' then
        snap_neighboring_loaders(entity)
    elseif entity.type == 'underground-belt' then
        snap_neighboring_loaders(entity)
        if entity.neighbours then
            snap_neighboring_loaders(entity)
        end
    elseif entity.type == 'splitter' or entity.type == 'loader' then
        snap_belt_neighbors(entity)
    end
end)

event.register(util.constants.entity_built_events, function(e)
    local entity = e.created_entity or e.entity
    if entity.name == 'entity-ghost' and entity.ghost_name == 'infinity-loader-logic-combinator' then
        -- convert to dummy combinator ghost
        local old_control = entity.get_or_create_control_behavior()
        local new_entity = entity.surface.create_entity{
            name = 'entity-ghost',
            ghost_name = 'infinity-loader-dummy-combinator',
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
    end
end)

event.register(defines.events.on_player_rotated_entity, function(e)
    local entity = e.entity
    -- just in case
    if not entity.valid then return end
    if entity.name == 'infinity-loader-logic-combinator' then
        entity.direction = e.previous_direction
        local loader = entity.surface.find_entities_filtered{type='loader', position=entity.position}[1]
        loader.rotate()
        update_inserters(loader)
        update_filters(entity)
    elseif entity.type == 'transport-belt' then
        -- snap adjacent infinity loaders
        snap_neighboring_loaders(entity)
    elseif entity.type == 'underground-belt' then
        -- snap belt neighbors
        snap_belt_neighbors(entity)
        -- snap belt neighbors for the other side of the underneathy
        if entity.neighbours then
            snap_belt_neighbors(entity.neighbours)
        end
    elseif entity.type == 'splitter' or entity.type == 'loader' then
        -- snap belt neighbors
        snap_belt_neighbors(entity)
    end
end)

-- when an entity is destroyed
event.register(util.constants.entity_destroyed_events, function(e)
    local entity = e.entity
    if entity.name == 'infinity-loader-logic-combinator' then
        -- close open GUIs
        if global.conditional_event_registry.il_close_button_clicked then
            for _,i in ipairs(global.conditional_event_registry.il_close_button_clicked.players) do
                local player_table = util.player_table(i)
                -- check if they're viewing this one
                if player_table.gui.il.entity == entity then
                    gui.destroy(player_table.gui.il.elems.window, e.player_index)
                    player_table.gui.il = nil
                end
            end
        end
        local entities = entity.surface.find_entities_filtered{position=entity.position}
        for _,e in pairs(entities) do
            if e.name:find('infinity%-loader') then
                e.destroy()
            end
        end
    end
end)

-- when a player selects an area for blueprinting
event.register(defines.events.on_player_setup_blueprint, function(e)
    local player = util.get_player(e)
    local bp = player.blueprint_to_setup
    if not bp or not bp.valid_for_read then
        bp = player.cursor_stack
    end
    local entities = bp.get_blueprint_entities()
    if not entities then return end
    for i=1,#entities do
        if entities[i].name == 'infinity-loader-logic-combinator' then
            entities[i].name = 'infinity-loader-dummy-combinator'
            entities[i].direction = entities[i].direction or defines.direction.north
        end
    end
    bp.set_blueprint_entities(entities)
end)

-- when an entity settings copy/paste occurs
event.register(defines.events.on_entity_settings_pasted, function(e)
    if e.destination.name == 'infinity-loader-logic-combinator' then
        -- sanitize filters to remove any non-ttems
        local parameters = {parameters={}}
        local items = 0
        for i,p in pairs(table.deepcopy(e.source.get_control_behavior().parameters.parameters)) do
            if p.signal and p.signal.type == 'item' and items < 2 then
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
    if e.entity and e.entity.name == 'infinity-loader-logic-combinator' then
        local player, player_table = util.get_player(e)
        local elems = gui.create(player.gui.screen, e.entity, player)
        player.opened = elems.window
        player_table.gui.il = {elems=elems, entity=e.entity}
    end
end)

-- when a GUI is closed
event.register(defines.events.on_gui_closed, function(e)
    if e.gui_type == 16 and e.element.name == 'ee_il_window' then
        gui.destroy(e.element, e.player_index)
        util.player_table(e).gui.il = nil
    end
end)