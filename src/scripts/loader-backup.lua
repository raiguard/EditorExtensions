-- ----------------------------------------------------------------------------------------------------
-- INFINITY LOADER CONTROL SCRIPTING

local conditional_event = require('scripts/util/conditional-event')
local event = require('__stdlib__/stdlib/event/event')
local direction = require('__stdlib__/stdlib/area/direction')
local gui = require('__stdlib__/stdlib/event/gui')
local position = require('__stdlib__/stdlib/area/position')
local table = require('__stdlib__/stdlib/utils/table')
local tile = require('__stdlib__/stdlib/area/tile')
local on_event = event.register
local util = require('scripts/util/util')
local version = require('__stdlib__/stdlib/vendor/version')

-- gui elements
local entity_camera = require('scripts/util/gui-elems/entity-camera')
local titlebar = require('scripts/util/gui-elems/titlebar')

-- ----------------------------------------------------------------------------------------------------
-- UTILITIES

-- pattern -> replacement
-- iterate through all of these to result in the belt type
local belt_type_patterns = {
    -- infinity mode :D
    ['infinity%-loader%-loader%-?'] = '',
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
    -- subterranean: 
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
        game.print{'', 'INFINITY MODE: ', {'chat-message.unable-to-identify-belt-warning'}}
        game.print('belt_name=\''..entity.name..'\', parse_result=\''..type..'\'')
        -- set to default type
        type = 'express'
    end
	return type
end

local function check_is_loader(e)
    if e.name:find('infinity%-loader%-loader') then return true end
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

-- 60 items/second / 60 ticks/second / 8 items/tile = X tiles/tick
local BELT_SPEED_FOR_60_PER_SECOND = 60/60/8
local function num_inserters(entity)
  return math.ceil(entity.prototype.belt_speed / BELT_SPEED_FOR_60_PER_SECOND) * 2
end

-- update inserter pickup/drop positions
local function update_inserters(entity)
    local inserters = entity.surface.find_entities_filtered{name='infinity-loader-inserter', position=entity.position}
    local chest = entity.surface.find_entities_filtered{name='infinity-loader-chest', position=entity.position}[1]
    local e_type = entity.loader_type
    local e_position = entity.position
    local e_direction = entity.direction
    for i=1,#inserters do
        local side = i > (#inserters/2) and -0.25 or 0.25
        local inserter = inserters[i]
        local mod = math.min((i % (#inserters/2)),3)
        if e_type == 'input' then
            -- pickup on belt, drop in chest
            inserter.pickup_target = entity
            inserter.pickup_position = position.add(e_position, to_vector_2d(e_direction,(-mod*0.2 + 0.3),side))
            inserter.drop_target = chest
            inserter.drop_position = e_position
        elseif e_type == 'output' then
            -- pickup from chest, drop on belt
            inserter.pickup_target = chest
            inserter.pickup_position = chest.position
            inserter.drop_target = entity
            inserter.drop_position = position.add(e_position, to_vector_2d(e_direction,(mod*0.2 - 0.3),side))
        end
        -- TEMPORARY rendering
        -- rendering.draw_circle{target=inserter.pickup_position, color={r=0,g=1,b=0,a=0.5}, surface=entity.surface, radius=0.03, filled=true, time_to_live=180}
        -- rendering.draw_circle{target=inserter.drop_position, color={r=0,g=1,b=1,a=0.5}, surface=entity.surface, radius=0.03, filled=true, time_to_live=180}
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

-- offsets based on direction
local facing_lib = {
    [defines.direction.north] = {0,-1},
    [defines.direction.east] = {1,0},
    [defines.direction.south] = {0,1},
    [defines.direction.west] = {-1,0}
}

-- check if the given loader is facing the given belt
local function loader_facing_belt(loader, belt)
    local op = loader.loader_type == 'output' and 'add' or 'subtract'
    if position.equals(position[op](loader.position, facing_lib[loader.direction]), belt.position) then
        return true
    end
    return false
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
            direction = direction,
            create_build_effect_smoke = false
        }
    end
    return loader, inserters, chest, combinator
end

-- ----------------------------------------------------------------------------------------------------
-- SNAPPING
-- loader_unit_number is an optional argument for all functions that have it.
-- When supplied, only the loader with that unit number will be snapped/updated.
-- This is included in order to avoid rotating any other loaders that may have been
-- intentionally rotated the 'wrong' direction by a player. Currently only used
-- when placing a new loader.

-- snap adjacent loaders to a belt entity
local function snap_to_belt(entity, loader_unit_number)
    for _,pos in pairs(tile.adjacent(entity.surface, position.floor(entity.position))) do
        local entities = entity.surface.find_entities_filtered{area=position.to_tile_area(pos), type='loader'} or {}
        for _,e in pairs(entities) do
            if check_is_loader(e) and (loader_unit_number == nil or (e.unit_number == loader_unit_number)) then
                if loader_facing_belt(e, entity) then
					if e.direction ~= entity.direction and e.loader_type == 'input' then
                        e.rotate()
                        update_inserters(e)
                        update_filters(e.surface.find_entities_filtered{name='infinity-loader-logic-combinator', position=e.position}[1])
                    elseif util.oppositedirection(e.direction) == entity.direction then
                        e.rotate()
                        update_inserters(e)
                        update_filters(e.surface.find_entities_filtered{name='infinity-loader-logic-combinator', position=e.position}[1])
                    end
                end
            end
        end
    end
end

-- snap adjacent loaders to a splitter entity
local function snap_to_splitter(entity, loader_unit_number)
	entity.rotate()
	-- deepcopy the table to get around the read-only restriction
    local neighbours = table.deepcopy(entity.belt_neighbours)
	for i,neighbour_type in ipairs({"inputs", "outputs"}) do
		for j,neighbour in ipairs(neighbours[neighbour_type]) do
            if check_is_loader(neighbour) and (loader_unit_number == nil or (neighbour.unit_number == loader_unit_number)) then
                neighbour.rotate()
				update_inserters(neighbour)
				update_filters(neighbour.surface.find_entities_filtered{name='infinity-loader-logic-combinator', position=neighbour.position}[1])
			end
		end
	end
	entity.rotate()
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
end

-- update adjacent loader types, if necessary
local function belt_update_loader_types(entity, loader_unit_number)
    local belt_type = get_belt_type(entity)
    for _,pos in pairs(tile.adjacent(entity.surface, position.floor(entity.position))) do
        -- find any underneathies
        local entities = entity.surface.find_entities_filtered{area=position.to_tile_area(pos), type='loader'} or {}
        for _,e in pairs(entities) do
            -- if the underneathy is an infinity loader
            if check_is_loader(e) and (loader_unit_number == nil or (e.unit_number == loader_unit_number)) and loader_facing_belt(e, entity) then
                local loader_type = get_belt_type(e)
                -- if belt types do not match
                if belt_type ~= loader_type then
                    update_loader_type(belt_type, e)
                end
            end
        end
    end
end

-- update adjacent loader types, if necessary
local function splitter_update_loader_types(entity, loader_unit_number)
    local belt_type = get_belt_type(entity)
    for i=1,2 do
        -- deepcopy the table to get around the read-only restriction
		local neighbours = table.deepcopy(entity.belt_neighbours)
		for j,neighbour_type in ipairs({"inputs", "outputs"}) do
			for k,neighbour in ipairs(neighbours[neighbour_type]) do
				if check_is_loader(neighbour) and (loader_unit_number == nil or (neighbour.unit_number == loader_unit_number)) then
					local loader_type = get_belt_type(neighbour)
					if belt_type ~= loader_type then
						update_loader_type(belt_type, neighbour)
					end
				end
			end
		end
		entity.rotate()
	end
end

-- update a placed loader
local function snap_update_placed_loader(entity)
	local entities = entity.surface.find_entities_filtered{type={'transport-belt','underground-belt','splitter','loader'}, area=position.to_tile_area(position.add(entity.position, to_vector_2d(entity.direction,flip and -1 or 1, 0)))}
    if entities[1] ~= nil then
		local connected_entity = entities[1]
		if connected_entity.type == 'splitter' then
			if connected_entity.direction == entity.direction or connected_entity.direction == util.oppositedirection(entity.direction) then
				snap_to_splitter(connected_entity, entity.unit_number)
				splitter_update_loader_types(connected_entity, entity.unit_number)
			end
		elseif connected_entity.type == 'loader' then
			local final_mode
			-- I couldn't think of a better way of checking loaders. Only having a belt on half of it is kind of weird.
			for i=1,2 do
				local neighbours = connected_entity.belt_neighbours
				for j,neighbour_type in ipairs({"inputs", "outputs"}) do
					for k,neighbour in ipairs(neighbours[neighbour_type]) do
						if check_is_loader(neighbour) and (neighbour.unit_number == entity.unit_number) then
							final_mode = entity.loader_type
						end
					end
				end
				entity.rotate()
			end
			if entity.loader_type ~= final_mode then
				entity.rotate()
			end
			snap_to_splitter(connected_entity, entity.unit_number)
			splitter_update_loader_types(connected_entity, entity.unit_number)
		else
			snap_to_belt(connected_entity, entity.unit_number)
			belt_update_loader_types(connected_entity, entity.unit_number)
		end
	end
    return nil
end

-- ----------------------------------------------------------------------------------------------------
-- BLUEPRINTING

-- convert loaders in a blueprint to dummy combinators
local function convert_blueprint_loaders(bp)
    local entities = bp.get_blueprint_entities()
    if not entities then return end
    for i=1,#entities do
        if entities[i].name == 'infinity-loader-logic-combinator' then
            entities[i].name = 'infinity-loader-dummy-combinator'
            entities[i].direction = entities[i].direction or defines.direction.north
        end
    end
    bp.set_blueprint_entities(entities)
end

-- ----------------------------------------------------------------------------------------------------
-- COMPATIBILITY

-- picker dollies
local function picker_dollies_move(e)
    local entity = e.moved_entity
    if entity.name == 'infinity-loader-logic-combinator' then
        -- destroy all entities in the previous position
        for _,e in pairs(e.moved_entity.surface.find_entities_filtered{position=e.start_pos}) do
            e.destroy()
        end
        local type, mode = 'express', 'output'
        local loader, inserters, chest = create_loader(type, mode, entity.surface, entity.position, entity.direction, entity.force, true)
        -- update entitiy
        update_inserters(loader)
        update_filters(entity)
        snap_update_placed_loader(loader)
    end
end

-- ----------------------------------------------------------------------------------------------------
-- GUI

-- create the GUI
local function create_gui(player, combinator)
    local control = combinator.get_or_create_control_behavior()
    local parameters = control.parameters.parameters
    local window = player.gui.screen.add{type='frame', name='im_loader_window', style='dialog_frame', direction='vertical'}
    local titlebar = titlebar.create(window, 'im_loader_titlebar', {
        label=combinator.localised_name,
        draggable = true,
        buttons={
            {
                name = 'close',
                sprite = 'utility/close_white',
                hovered_sprite = 'utility/close_black',
                clicked_sprite = 'utility/close_black'
            }
    }})
    local lower_flow = window.add{type='flow', name='im_loader_lower_flow', direction='horizontal'}
    lower_flow.style.horizontal_spacing = 12
    entity_camera.create(lower_flow, 'im_loader_camera', 90, {player=player, entity=combinator, camera_zoom=1})
    local page = lower_flow.add{type='frame', name='im_loader_page', style='window_content_frame', direction='vertical'}
    page.style.left_padding = 8
    page.style.vertically_stretchable = true

    -- enabled/disabled
    local state_flow = page.add{type='flow', name='im_loader_state_flow', direction='horizontal'}
    state_flow.style.vertical_align = 'center'
    state_flow.style.vertically_stretchable = true
    state_flow.style.right_margin = 4
    state_flow.add{type='label', name='im_loader_state_label', caption={'gui-infinity-loader.state-label-caption'}}
    state_flow.add{type='empty-widget', name='im_loader_state_filler', style='invisible_horizontal_filler'}
    state_flow.add{type='switch', name='im_loader_state_switch', left_label_caption={'gui-constant.on'}, right_label_caption={'gui-constant.off'}, switch_state=control.enabled and 'left' or 'right'}
    -- filters
    local filters_flow = page.add{type='flow', name='im_loader_filters_flow', direction='horizontal'}
    filters_flow.style.vertical_align = 'center'
    filters_flow.style.right_margin = 4
    filters_flow.style.bottom_margin = 3
    filters_flow.add{type='label', name='im_loader_filters_label', caption={'gui-infinity-loader.filters-label-caption'}}
    filters_flow.add{type='empty-widget', name='im_loader_filters_filler', style='invisible_horizontal_filler'}.style.minimal_width = 30
    local buttons_flow = filters_flow.add{type='frame', name='im_loader_filters_frame', style='shortcut_bar_inner_panel'}.add{type='flow', name='im_loader_filters_buttons_flow', direction='horizontal'}
    buttons_flow.style.horizontal_spacing = 0
    buttons_flow.add{type='choose-elem-button', name='im_loader_filters_button_1', style='quick_bar_slot_button', elem_type='item', item=parameters[1].signal.name}
    buttons_flow.add{type='choose-elem-button', name='im_loader_filters_button_2', style='quick_bar_slot_button', elem_type='item', item=parameters[2].signal.name}
    window.force_auto_center()
    util.set_open_gui(player, window, titlebar.children[3])
    util.player_table(player).open_gui.entity = combinator
end

-- gui listeners
gui.on_elem_changed('im_loader_filters_button_', function(e)
    local index = e.element.name:gsub(e.match, '')
    local entity = util.player_table(e.player_index).open_gui.entity
    local control = entity.get_or_create_control_behavior()
    control.set_signal(index, e.element.elem_value and {signal={type='item', name=e.element.elem_value}, count=1} or nil)
    update_filters(entity)
    -- local loader = entity.surface.find_entities_filtered{type='loader', position=entity.position}[1]
    -- for i=1,loader.get_max_transport_line_index() do
    --     local line = loader.get_transport_line(i)
    --     local name = control.parameters.parameters[i].signal.name
    --     if name then line.clear() end
    -- end
end)

on_event(defines.events.on_gui_switch_state_changed, function(e)
    if e.element.name ~= 'im_loader_state_switch' then return end
    local entity = util.player_table(e.player_index).open_gui.entity
    entity.get_or_create_control_behavior().enabled = e.element.switch_state == 'left'
    update_filters(entity)
end)

-- ----------------------------------------------------------------------------------------------------
-- LISTENERS

-- interface to allow conditional on_tick to update the filters
remote.add_interface('ee_infinity_loader', {
    create_loader = create_loader,
    update_loader_filters = update_filters,
    snap_update_placed_loader = snap_update_placed_loader,
    update_loader_inserters = update_inserters,
    update_loader_filters = update_filters
})

event.on_init(function()
    global.loaders = {}
    -- picker dollies
    if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
        on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), picker_dollies_move)
    end
end)

event.on_load(function()
    -- picker dollies
    if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
        on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), picker_dollies_move)
    end
end)

event.on_configuration_changed(function(e)
    if e.mod_changes['EditorExtensions'] and e.mod_changes['EditorExtensions'].old_version then
        local t = e.mod_changes['EditorExtensions']
        local v = version('0.3.0')
        if version(t.old_version) < v then
            -- rebuild all loaders
            for _,s in pairs(game.surfaces) do
                for _,e in pairs(s.find_entities_filtered{name='infinity-loader-logic-combinator'}) do
                    local control = e.get_or_create_control_behavior()
                    local parameters = control.parameters
                    local enabled = control.enabled
                    local position = e.position
                    local direction = e.direction
                    local force = e.force
                    for _,en in pairs(s.find_entities_filtered{position=e.position}) do
                        en.destroy{}
                    end
                    local loader, inserters, chest, combinator = create_loader('express', 'output', s, position, direction, force)
                    local new_control = combinator.get_or_create_control_behavior()
                    new_control.parameters = parameters
                    new_control.enabled = enabled
                    update_inserters(loader)
                    update_filters(combinator)
                    snap_update_placed_loader(loader)
                end
            end
        end
    end
end)

-- when an entity is built
on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_built, defines.events.script_raised_revive}, function(e)
    local entity = e.created_entity or e.entity
    -- if the placed entity is an infinity loader
    if entity.name == 'infinity-loader-dummy-combinator' or entity.name == 'infinity-loader-logic-combinator' then
		-- Just place the loader with the default values. belt_neighbors requires both entities to exist, so type/mode get set later
		local type, mode = 'express', 'output'
		local direction = entity.direction
        local loader, inserters, chest, combinator = create_loader(type, mode, entity.surface, entity.position, direction, entity.force)
		-- get previous filters, if any
        local old_control = entity.get_or_create_control_behavior()
        local new_control = combinator.get_or_create_control_behavior()
        new_control.parameters = old_control.parameters
        new_control.enabled = old_control.enabled
        entity.destroy()
        -- update entitiy
        update_inserters(loader)
        update_filters(combinator)
		snap_update_placed_loader(loader)
    elseif entity.type == 'transport-belt' then
		snap_to_belt(entity)
        belt_update_loader_types(entity)
    elseif entity.type == 'underground-belt' then
        snap_to_belt(entity)
        belt_update_loader_types(entity)
        if entity.neighbours then
            snap_to_belt(entity.neighbours)
            belt_update_loader_types(entity.neighbours)
        end
	elseif entity.type == 'splitter' or entity.type == 'loader' then
		snap_to_splitter(entity)
		splitter_update_loader_types(entity)
    end
end)

-- when an entity is rotated
on_event(defines.events.on_player_rotated_entity, function(e)
    local entity = e.entity
    local surface = entity.surface
    if entity.name == 'infinity-loader-logic-combinator' then
        entity.direction = e.previous_direction
        local loader = entity.surface.find_entities_filtered{type='loader', position=entity.position}[1]
        loader.rotate()
        update_inserters(loader)
        update_filters(entity)
    elseif entity.type == 'transport-belt' then
        snap_to_belt(entity)
    elseif entity.type == 'underground-belt' then
        snap_to_belt(entity)
        if entity.neighbours then snap_to_belt(entity.neighbours) end
	elseif entity.type == 'splitter' or entity.type == 'loader' then
		snap_to_splitter(entity)
    end
end)

-- when an entity is destroyed
on_event({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity, defines.events.on_entity_died, defines.events.script_raised_destroy}, function(e)
    local entity = e.entity
    if entity.name == 'infinity-loader-logic-combinator' then
        if e.player_index then
            local t = util.player_table(e.player_index)
            if t.open_gui and t.open_gui.entity == entity then
                event.dispatch{name=defines.events.on_gui_click, element=t.open_gui.close_button, player_index=e.player_index, button=defines.mouse_button_type.left, alt=false, control=false, shift=false}
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
on_event(defines.events.on_player_setup_blueprint, function(e)
    local player = util.get_player(e)
    local bp = player.blueprint_to_setup
    if not bp or not bp.valid_for_read then
        bp = player.cursor_stack
    end
    convert_blueprint_loaders(bp)
end)

-- when a player opens a GUI
on_event(defines.events.on_gui_opened, function(e)
    local entity = e.entity
    if entity and entity.name == 'infinity-loader-logic-combinator' then
        create_gui(util.get_player(e), entity)
    end
end)

-- when an entity settings copy/paste occurs
on_event(defines.events.on_entity_settings_pasted, function(e)
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