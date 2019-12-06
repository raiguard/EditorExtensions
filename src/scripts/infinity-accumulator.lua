-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INFINITY ACCUMULATOR

local event = require('lualib/event')
local util = require('lualib/util')

-- GUI ELEMENTS
local entity_camera = require('lualib/gui-elems/entity-camera')
local titlebar = require('lualib/gui-elems/titlebar')

local gui = {}

-- --------------------------------------------------------------------------------
-- LOCAL UTILITIES

local constants = {
    localized_priorities = {
        {'gui-infinity-accumulator.priority-dropdown-primary'},
        {'gui-infinity-accumulator.priority-dropdown-secondary'}
    },
    localized_modes = {
        {'gui-infinity-accumulator.mode-dropdown-output'},
        {'gui-infinity-accumulator.mode-dropdown-input'},
        {'gui-infinity-accumulator.mode-dropdown-buffer'}
    },
    mode_to_index = {output=1, input=2, buffer=3},
    priority_to_index = {primary=1, secondary=2, tertiary=1},
    index_to_mode = {'output', 'input', 'buffer'},
    index_to_priority = {'primary', 'secondary'},
    power_prefixes = {'kilo','mega','giga','tera','peta','exa','zetta','yotta'},
    power_suffixes_by_mode = {output='watt', input='watt', buffer='joule'},
    localized_si_suffixes_watt = {},
    localized_si_suffixes_joule = {},
    si_suffixes_joule = {'kJ', 'MJ', 'GJ', 'TJ', 'PJ', 'EJ', 'ZJ', 'YJ'},
    si_suffixes_watt = {'kW', 'MW', 'GW', 'TW', 'PW', 'EW', 'ZW', 'YW'}
}
for i,v in pairs(constants.power_prefixes) do
    constants.localized_si_suffixes_watt[i] = {'', {'si-prefix-symbol-' .. v}, {'si-unit-symbol-watt'}}
    constants.localized_si_suffixes_joule[i] = {'', {'si-prefix-symbol-' .. v}, {'si-unit-symbol-joule'}}
end

local function check_is_accumulator(entity)
    return entity.name:find('infinity%-accumulator')
end

local function get_settings_from_name(name)
    name = name:gsub('(%a+)-(%a+)-', '')
    if name == 'tertiary' then return 'tertiary', 'buffer' end
    local _,_,priority,mode = string.find(name, '(%a+)-(%a+)')
    return priority, mode
end

local function set_entity_settings(entity, mode, buffer_size)
    -- reset everything
    entity.power_production = 0
    entity.power_usage = 0
    entity.electric_buffer_size = buffer_size
    local watts = util.parse_energy(buffer_size..'W')
    if mode == 'output' then
        entity.power_production = watts
        entity.energy = buffer_size
    elseif mode == 'input' then
        entity.power_usage = watts
    end
end

local function change_entity(entity, priority, mode)
    priority = '-'..priority
    local n_mode = mode and '-'..mode or ''
    local new_name = 'infinity-accumulator'..priority..n_mode
    local new_entity = entity.surface.create_entity{
        name = new_name,
        position = entity.position,
        force = entity.force,
        last_user = entity.last_user,
        create_build_effect_smoke = false
    }
    set_entity_settings(new_entity, mode or 'buffer', entity.electric_buffer_size)
    entity.destroy()
    return new_entity
end

-- returns the slider value and dropdown selected index based on the entity's buffer size
local function rev_parse_energy(value)
    local len = string.len(string.format("%.0f", math.floor(value)))
    local exponent = math.max(len - (len % 3 == 0 and 3 or len % 3),3)
    value = math.floor(value / 10^exponent)
    return value, exponent/3
end

-- --------------------------------------------------------------------------------
-- GUI

-- ----------------------------------------
-- GUI HANDLERS

local function close_button_clicked(e)
    -- invoke GUI closed event
    event.raise(defines.events.on_gui_closed, {element=e.element.parent.parent, gui_type=16, player_index=e.player_index, tick=game.tick})
end

local function mode_dropdown_selection_changed(e)
    local player, player_table = util.get_player(e)
    local gui_data = player_table.gui.ia
    local mode = constants.index_to_mode[e.element.selected_index]
    if mode == 'buffer' then
        gui_data.entity = change_entity(gui_data.entity, 'tertiary')
    else
        local priority = constants.index_to_priority[gui_data.elems.priority_dropdown.selected_index]
        gui_data.entity = change_entity(gui_data.entity, priority, mode)
    end
    gui.update_mode(gui_data.elems, mode)
end

local function priority_dropdown_selection_changed(e)
    local player, player_table = util.get_player(e)
    local gui_data = player_table.gui.ia
    local mode = constants.index_to_mode[gui_data.elems.mode_dropdown.selected_index]
    local priority = constants.index_to_priority[e.element.selected_index]
    gui_data.entity = change_entity(gui_data.entity, priority, mode)
end

local function slider_value_changed(e)
    local player_table = util.player_table(e)
    local gui_data = player_table.gui.ia
    local elems = gui_data.elems
    local buffer_size = util.parse_energy(e.element.slider_value..constants.si_suffixes_joule[elems.slider_dropdown.selected_index])
    set_entity_settings(gui_data.entity, constants.index_to_mode[elems.mode_dropdown.selected_index], buffer_size)
    elems.slider_textfield.text = e.element.slider_value
end

local function slider_textfield_text_changed(e)
    local player_table = util.player_table(e.player_index)
	local gui_data = player_table.gui.ia
	local new_value = util.textfield.clamp_number_input(e.element, {0,999}, gui_data.last_textfield_value)
	if new_value ~= gui_data.last_textfield_value then
		gui_data.last_textfield_value = new_value
		gui_data.elems.slider.slider_value = new_value
	end
end

local function slider_textfield_confirmed(e)
    local player_table = util.player_table(e.player_index)
    local gui_data = player_table.gui.ia
    local elems = gui_data.elems
	local final_text = util.textfield.set_last_valid_value(e.element, player_table.gui.ia.last_textfield_value)
    local buffer_size = util.parse_energy(e.element.text..constants.si_suffixes_joule[elems.slider_dropdown.selected_index])
    set_entity_settings(gui_data.entity, constants.index_to_mode[elems.mode_dropdown.selected_index], buffer_size)
end

local function slider_dropdown_selection_changed(e)
    local player_table = util.player_table(e.player_index)
    local gui_data = player_table.gui.ia
    local elems = gui_data.elems
    local buffer_size = util.parse_energy(elems.slider.slider_value..constants.si_suffixes_joule[e.element.selected_index])
    set_entity_settings(gui_data.entity, constants.index_to_mode[elems.mode_dropdown.selected_index], buffer_size)
end

local handlers = {
    ia_close_button_clicked = close_button_clicked,
    ia_mode_dropdown_selection_changed = mode_dropdown_selection_changed,
    ia_priority_dropdown_selection_changed = priority_dropdown_selection_changed,
    ia_slider_value_changed = slider_value_changed,
    ia_slider_textfield_text_changed = slider_textfield_text_changed,
    ia_slider_textfield_confirmed = slider_textfield_confirmed,
    ia_slider_dropdown_selection_changed = slider_dropdown_selection_changed
}

event.on_load(function()
    event.load_conditional_handlers(handlers)
end)

-- ----------------------------------------
-- GUI MANAGEMENT

function gui.create(parent, entity, player)
    local window = parent.add{type='frame', name='ee_ia_window', style='dialog_frame', direction='vertical'}
    local titlebar = titlebar.create(window, 'ee_ia_titlebar', {
        draggable = true,
        label = {'entity-name.infinity-accumulator-tertiary'},
        buttons = {util.constants.close_button_def}
    })
    event.gui.on_click(titlebar.children[3], close_button_clicked, 'ia_close_button_clicked', player.index)
    local content_flow = window.add{type='flow', name='ee_ia_content_flow', style='ee_entity_window_content_flow', direction='horizontal'}
    local camera = entity_camera.create(content_flow, 'ee_ia_camera', 110, {player=player, entity=entity, camera_zoom=1, camera_offset={0,-0.5}})
    local page_frame = content_flow.add{type='frame', name='ee_ia_page_frame', style='ee_ia_page_frame', direction='vertical'}
    local priority, mode = get_settings_from_name(entity.name)
    local mode_flow = page_frame.add{type='flow', name='ee_ia_mode_flow', style='ee_vertically_centered_flow', direction='horizontal'}
    mode_flow.add{type='label', name='ee_ia_mode_label', caption={'', {'gui-infinity-accumulator.mode-label-caption'}, ' [img=info]'},
                      tooltip={'gui-infinity-accumulator.mode-label-tooltip'}}
    mode_flow.add{type='empty-widget', name='ee_ia_mode_pusher', style='ee_invisible_horizontal_pusher'}
    local mode_dropdown = mode_flow.add{type='drop-down', name='ee_ia_mode_dropdown', items=constants.localized_modes,
                                        selected_index=constants.mode_to_index[mode]}
    event.gui.on_selection_state_changed(mode_dropdown, mode_dropdown_selection_changed, 'ia_mode_dropdown_selection_changed', player.index)
    local priority_flow = page_frame.add{type='flow', name='ee_ia_priority_flow', style='ee_vertically_centered_flow', direction='horizontal'}
    priority_flow.style.vertically_stretchable = true
    priority_flow.add{type='label', name='ee_ia_priority_label', caption={'', {'gui-infinity-accumulator.priority-label-caption'}, ' [img=info]'},
                      tooltip={'gui-infinity-accumulator.priority-label-tooltip'}}
    priority_flow.add{type='empty-widget', name='ee_ia_priority_pusher', style='ee_invisible_horizontal_pusher'}
    local priority_dropdown = priority_flow.add{type='drop-down', name='ee_ia_priority_dropdown', items=constants.localized_priorities,
                                                selected_index=constants.priority_to_index[priority]}
    event.gui.on_selection_state_changed(priority_dropdown, priority_dropdown_selection_changed, 'ia_priority_dropdown_selection_changed', player.index)
    local priority_dropdown_dummy = priority_flow.add{type='button', name='ee_ia_priority_dropdown_dummy', style='ee_disabled_dropdown_button',
                                                      caption={'gui-infinity-accumulator.priority-dropdown-tertiary'}}
    priority_dropdown_dummy.enabled = false
    if mode == 'buffer' then
        priority_dropdown.visible = false
    else
        priority_dropdown_dummy.visible = false
    end
    local slider_value, dropdown_index = rev_parse_energy(entity.electric_buffer_size)
    local slider_flow = page_frame.add{type='flow', name='ee_ia_slider_flow', style='ee_vertically_centered_flow', direction='horizontal'}
    local slider = slider_flow.add{type='slider', name='ee_ia_slider', minimum_value=0, maximum_value=999, value=slider_value}
    event.gui.on_value_changed(slider, slider_value_changed, 'ia_slider_value_changed', player.index)
    local slider_textfield = slider_flow.add{type='textfield', name='ee_ia_slider_textfield', style='ee_slider_textfield', text=slider_value, numeric=true,
                                             lose_focus_on_confirm=true, clear_and_focus_on_right_click=true}
    event.gui.on_text_changed(slider_textfield, slider_textfield_text_changed, 'ia_slider_textfield_text_changed', player.index)
    event.gui.on_confirmed(slider_textfield, slider_textfield_confirmed, 'ia_slider_textfield_confirmed', player.index)
    local slider_dropdown = slider_flow.add{type='drop-down', name='ee_ia_slider_dropdown', selected_index=dropdown_index,
                                            items=constants['localized_si_suffixes_'..constants.power_suffixes_by_mode[mode]]}
    slider_dropdown.style.width = 63
    event.gui.on_selection_state_changed(slider_dropdown, slider_dropdown_selection_changed, 'ia_slider_dropdown_selection_changed', player.index)
    window.force_auto_center()
    return {window=window, camera=camera, mode_dropdown=mode_dropdown, priority_dropdown=priority_dropdown, priority_dropdown_dummy=priority_dropdown_dummy,
            slider=slider, slider_textfield=slider_textfield, slider_dropdown=slider_dropdown},
            slider_textfield.text
end

function gui.update_mode(elems, mode)
    if mode == 'buffer' then
        elems.priority_dropdown.visible = false
        elems.priority_dropdown_dummy.visible = true
    else
        elems.priority_dropdown.visible = true
        elems.priority_dropdown_dummy.visible = false
    end
    elems.slider_dropdown.items = constants['localized_si_suffixes_'..constants.power_suffixes_by_mode[mode]]
end

function gui.update_settings(gui_data)
    local elems = gui_data.elems
    local entity = gui_data.entity
    local priority, mode = get_settings_from_name(entity.name)
    local slider_value, dropdown_index = rev_parse_energy(entity.electric_buffer_size)
    elems.mode_dropdown.selected_index = constants.mode_to_index[mode]
    elems.priority_dropdown.selected_index = constants.priority_to_index[priority]
    elems.slider.slider_value = slider_value
    elems.slider_textfield.text = slider_value
    elems.slider_textfield.style = 'ee_slider_textfield'
    elems.slider_dropdown.selected_index = dropdown_index
    gui_data.last_textfield_value = slider_value
    gui.update_mode(elems, mode)
end

function gui.destroy(window, player_index)
    -- deregister all GUI events if needed
    local con_registry = global.conditional_event_registry
    for cn,h in pairs(handlers) do
        event.gui.deregister(con_registry[cn].id, h, cn, player_index)
    end
    window.destroy()
end

-- --------------------------------------------------------------------------------
-- STATIC HANDLERS

-- when a GUI is opened
event.register(defines.events.on_gui_opened, function(e)
    if e.entity and check_is_accumulator(e.entity) then
        local player, player_table = util.get_player(e)
        -- create GUI
        local elems, last_textfield_value = gui.create(player.gui.screen, e.entity, player)
        player.opened = elems.window
        player_table.gui.ia = {elems=elems, last_textfield_value=last_textfield_value, entity=e.entity}
    end
end)

-- when a GUI is closed
event.register(defines.events.on_gui_closed, function(e)
    if e.gui_type == 16 and e.element.name == 'ee_ia_window' then
        gui.destroy(e.element, e.player_index)
        util.player_table(e).gui.ia = nil
    end
end)

-- when an entity copy/paste occurs
event.register(defines.events.on_entity_settings_pasted, function(e)
    if check_is_accumulator(e.source) and check_is_accumulator(e.destination) and e.source.name ~= e.destination.name then
        -- get players viewing the destination accumulator
        local to_update = {}
        if global.conditional_event_registry.ia_close_button_clicked then
            for _,i in ipairs(global.conditional_event_registry.ia_close_button_clicked.players) do
                local player_table = util.player_table(i)
                -- check if they're viewing this one
                if player_table.gui.ia.entity == e.destination then
                    table.insert(to_update, i)
                end
            end
        end
        -- update entity
        local priority, mode = get_settings_from_name(e.source.name)
        local new_entity
        if mode == 'buffer' then
            new_entity = change_entity(e.destination, 'tertiary')
        else
            new_entity = change_entity(e.destination, priority, mode)
        end
        -- update open GUIs
        for _,i in pairs(to_update) do
            local player_table = util.player_table(i)
            player_table.gui.ia.entity = new_entity
            gui.update_settings(player_table.gui.ia)
        end
    end
end)

event.register(util.constants.entity_destroyed_events, function(e)
    if check_is_accumulator(e.entity) then
        -- close open GUIs
        if global.conditional_event_registry.ia_close_button_clicked then
            for _,i in ipairs(global.conditional_event_registry.ia_close_button_clicked.players) do
                local player_table = util.player_table(i)
                -- check if they're viewing this one
                if player_table.gui.ia.entity == e.entity then
                    gui.destroy(player_table.gui.ia.elems.window, e.player_index)
                    player_table.gui.ia = nil
                end
            end
        end
    end
end)