-- ----------------------------------------------------------------------------------------------------
-- INFINITY ACCUMULATOR CONTROL SCRIPTING

local event = require('__stdlib__/stdlib/event/event')
local gui = require('__stdlib__/stdlib/event/gui')
local on_event = event.register
local util = require('scripts/util/util')

-- GUI ELEMENTS
local entity_camera = require('scripts/util/gui-elems/entity-camera')
local titlebar = require('scripts/util/gui-elems//titlebar')

-- ----------------------------------------------------------------------------------------------------
-- UTILITIES

local entity_list = {
    ['infinity-accumulator-primary-input'] = true,
    ['infinity-accumulator-primary-output'] = true,
    ['infinity-accumulator-secondary-input'] = true,
    ['infinity-accumulator-secondary-output'] = true,
    ['infinity-accumulator-tertiary'] = true
}

local function check_is_accumulator(e)
    return e and entity_list[e.name] or false
end

local pti_ref = {
    input = 1,
    output = 2,
    buffer = 3,
    primary = 1,
    secondary = 2,
    tertiary = 1
}

local ia_states = {
    mode = {'input', 'output', 'buffer'},
    priority = {'primary', 'secondary'}
}

local function get_ia_options(entity)
    local name = entity.name:gsub('(%a+)-(%a+)-', '')
    if name == 'tertiary' then return {mode=3, priority=1} end
    local _,_,priority,mode = string.find(name, '(%a+)-(%a+)')
    return {mode=pti_ref[mode], priority=pti_ref[priority]}
end

local function set_ia_params(entity, mode, value, exponent)
    entity.power_usage = 0
    entity.power_production = 0
    entity.electric_buffer_size = 0

    if mode == 'input' then
        entity.power_usage = (value * 10^exponent) / 60
        entity.electric_buffer_size = (value * 10^exponent)
    elseif mode == 'output' then
        entity.power_production = (value * 10^exponent) / 60
        entity.electric_buffer_size = (value * 10^exponent)
    elseif mode == 'buffer' then
        entity.electric_buffer_size = (value * 10^exponent)
    end
end

-- arg1 can either be a table of elements, or the entity
-- if arg1 is an entity, then arg2 must be the destination entity of a copy/paste
local function change_ia_mode_or_priority(arg1, arg2)
    local data, entity, dest, mode, priority
    if not arg1.valid then
        -- changed through GUI
        data = arg1
        entity = data.entity
        mode = ia_states.mode[data.mode_dropdown.selected_index]
        priority = ia_states.priority[data.priority_dropdown.selected_index]
    else
        -- changed through copy/paste
        entity = arg2
        mode = ia_states.mode[get_ia_options(arg1).mode]
        priority = ia_states.priority[get_ia_options(arg1).priority]
    end
    if mode == 'buffer' then priority = 'tertiary' end
    local value, exponent
    if data then
        value = data.slider.slider_value
        exponent = data.slider_dropdown.selected_index * 3
    else
        value = entity.electric_buffer_size
        local len = string.len(string.format("%.0f", math.floor(value)))
        exponent = math.max(len - (len % 3 == 0 and 3 or len % 3),3)
        value = math.floor(value / 10^exponent)
    end
    local new_entity = entity.surface.create_entity{
        name = 'infinity-accumulator-' .. (mode == 'buffer' and 'tertiary' or priority) .. (mode ~= 'buffer' and ('-' .. mode) or ''),
        position = entity.position,
        force = entity.force,
        create_build_effect_smoke = false
    }
    entity.destroy()
    set_ia_params(new_entity, mode, value, exponent)
    return new_entity
end

-- ----------------------------------------------------------------------------------------------------
-- GUI

local power_prefixes = {'kilo','mega','giga','tera','peta','exa','zetta','yotta'}
local power_suffixes_by_mode = {'watt','watt','joule'}

local function create_dropdown(parent, name, caption, tooltip, items, selected_index, button_disabled)
    local flow = parent.add{type='flow', name=name..'_flow', style='vertically_centered_flow', direction='horizontal'}
    flow.add{type='label', name=name..'_label', caption=caption, tooltip=tooltip}
    flow.add {type='empty-widget', name=name..'_filler', style='invisible_horizontal_filler'}

    return flow.add{type='drop-down', name=name..'_dropdown', items=items, selected_index=selected_index}
end

-- create the ia settings page and add it to global
local function create_ia_pane(parent, entity)
    local ia_gui = {}
    local mode = get_ia_options(entity).mode
    local priority = get_ia_options(entity).priority
    local page_frame = parent.add{type='frame', name='im_ia_page_frame', style='entity_dialog_page_frame', direction='vertical'}
    -- mode dropdown
    ia_gui.mode_dropdown = create_dropdown(page_frame, 'im_ia_mode',
        {'', {'gui-infinity-accumulator.mode-label-caption'}, ' [img=info]'}, {'gui-infinity-accumulator.mode-label-tooltip'}, {{'gui-infinity-accumulator.mode-dropdown-input'}, {'gui-infinity-accumulator.mode-dropdown-output'}, {'gui-infinity-accumulator.mode-dropdown-buffer'}}, mode)
    -- priority dropdown
    ia_gui.priority_dropdown = create_dropdown(page_frame, 'im_ia_priority',
    {'', {'gui-infinity-accumulator.priority-label-caption'}, ' [img=info]'}, {'gui-infinity-accumulator.priority-label-tooltip'}, {{'gui-infinity-accumulator.priority-dropdown-primary'}, {'gui-infinity-accumulator.priority-dropdown-secondary'}}, priority)
    page_frame.im_ia_priority_flow.style.vertically_stretchable = true
    if mode == 3 then
        -- disabled button
        ia_gui.priority_dropdown.visible = false
        local disabled = ia_gui.priority_dropdown.parent.add{type='button', name='im_ia_priority_disabled_button', caption={'gui-infinity-accumulator.priority-dropdown-tertiary'}}
        disabled.enabled = false
        disabled.style.horizontal_align = 'left'
        disabled.style.minimal_width = 116
    end
    -- slider
    local slider_flow = page_frame.add{type='flow', name='im_ia_slider_flow', direction='horizontal'}
    slider_flow.style.vertical_align = 'center'
    local value = entity.electric_buffer_size
    local len = string.len(string.format("%.0f", math.floor(value)))
    local exponent = math.max(len - (len % 3 == 0 and 3 or len % 3),3)
    value = math.floor(value / 10^exponent)
    ia_gui.slider = slider_flow.add{type='slider', name='im_ia_slider', minimum_value=0, maximum_value=999, value=value}
    ia_gui.slider.style.horizontally_stretchable = true
    ia_gui.slider_textfield = slider_flow.add{type='textfield', name='im_ia_slider_textfield', text=value, numeric=true, lose_focus_on_confirm=true}
    ia_gui.slider_textfield.style.width = 48
    ia_gui.slider_textfield.style.horizontal_align = 'center'
    ia_gui.prev_textfield_value = value
    local items = {}
    for i,v in pairs(power_prefixes) do
        items[i] = {'', {'si-prefix-symbol-' .. v}, {'si-unit-symbol-' .. power_suffixes_by_mode[mode]}}
    end
    ia_gui.slider_dropdown = slider_flow.add{type='drop-down', name='im_ia_slider_dropdown', items=items, selected_index=(exponent/3)}
    ia_gui.slider_dropdown.style.width = 65
    -- add to global
    ia_gui.entity = entity
    return ia_gui
end

-- creates the main dialog frame
local function create_ia_gui(player, entity)
    local window = player.gui.screen.add{type='frame', name='im_ia_window', style='dialog_frame', direction='vertical'}
    local titlebar = titlebar.create(window, 'im_ia_titlebar', {
        label = {'gui-infinity-accumulator.titlebar-label-caption'},
        draggable = true,
        buttons = {
            {
                name = 'close',
                sprite = 'utility/close_white',
                hovered_sprite = 'utility/close_black',
                clicked_sprite = 'utility/close_black'
            }
        }
    })
    local content_flow = window.add {type='flow', name='im_ia_content_flow', direction='horizontal'}
    content_flow.style.horizontal_spacing = 10
    local camera = entity_camera.create(content_flow, 'im_camera', 110, {player=player, entity=entity, camera_zoom=1, camera_offset={0,-0.5}})
    util.set_open_gui(player, window, titlebar.children[3], 'ia_gui')
    util.player_table(player).ia_gui = create_ia_pane(content_flow, entity)
    return window
end

-- destroy and recreate the dialog with the new parameters
local function refresh_ia_gui(player, entity)
    local entity_frame = player.gui.screen.im_ia_window
    if entity_frame then
        entity_frame.im_ia_content_flow.im_ia_page_frame.destroy()
        util.player_table(player).ia_gui = create_ia_pane(entity_frame.im_ia_content_flow, entity)
    end
end

-- ----------------------------------------------------------------------------------------------------
-- LISTENERS

-- GUI MANAGEMENT

on_event(defines.events.on_gui_opened, function(e)
    if check_is_accumulator(e.entity) then
        create_ia_gui(util.get_player(e), e.entity, ia_page).force_auto_center()
    end
end)

gui.on_selection_state_changed('im_ia_mode_dropdown', function(e)
    refresh_ia_gui(util.get_player(e), change_ia_mode_or_priority(util.player_table(e.player_index).ia_gui))
end)

gui.on_selection_state_changed('im_ia_priority_dropdown', function(e)
    refresh_ia_gui(util.get_player(e), change_ia_mode_or_priority(util.player_table(e.player_index).ia_gui))
end)

gui.on_value_changed('im_ia_slider', function(e)
    local data = util.player_table(e.player_index).ia_gui
    local entity = data.entity
    local mode = ia_states.mode[data.mode_dropdown.selected_index]

    local exponent = data.slider_dropdown.selected_index * 3
    
    data.slider_textfield.text = tostring(math.floor(e.element.slider_value))
    
    set_ia_params(entity, mode, e.element.slider_value, exponent)
end)

gui.on_text_changed('im_ia_slider_textfield', function(e)
    local data = util.player_table(e.player_index).ia_gui
    local entity = data.entity
    local mode = ia_states.mode[data.mode_dropdown.selected_index]

    local exponent = data.slider_dropdown.selected_index * 3
    local text = data.slider_textfield.text

    if text == '' or tonumber(text) < 0 or tonumber(text) > 999 then
        e.element.tooltip = 'Must be an integer from 0-999'
        e.element.style = 'invalid_short_number_textfield'
        return nil
    else
        e.element.tooltip = ''
        e.element.style = 'short_number_textfield'
    end

    data.prev_textfield_value = text
    data.slider.slider_value = tonumber(text)
    set_ia_params(entity, mode, tonumber(text), exponent)
end)

gui.on_confirmed('im_ia_slider_textfield', function(e)
    local player_table = util.player_table(e.player_index)
    local data = player_table.ia_gui
    local entity = data.entity
    local mode = ia_states.mode[data.mode_dropdown.selected_index]
    local exponent = data.slider_dropdown.selected_index * 3
    if data.prev_textfield_value ~= data.slider_textfield.text then
        data.slider_textfield.text = data.prev_textfield_value
        e.element.tooltip = ''
        e.element.style = 'short_number_textfield'
        data.slider.slider_value = tonumber(data.prev_textfield_value)
        set_ia_params(entity, mode, tonumber(data.prev_textfield_value), exponent)
    end
end)

gui.on_selection_state_changed('im_ia_slider_dropdown', function(e)
    local data = util.player_table(e.player_index).ia_gui
    local entity = data.entity
    local mode = ia_states.mode[data.mode_dropdown.selected_index]

    local exponent = e.element.selected_index * 3

    set_ia_params(entity, mode, data.slider.slider_value, exponent)
end)


-- OTHER LISTENERS

-- -- when an entity settings copy/paste occurs
on_event(defines.events.on_entity_settings_pasted, function(e)
    if check_is_accumulator(e.source) and check_is_accumulator(e.destination) and e.source.name ~= e.destination.name then
        change_ia_mode_or_priority(e.source, e.destination)
    end
end)

-- when an entity is destroyed
on_event({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity, defines.events.on_entity_died, defines.events.script_raised_destroy}, function(e)
    local entity = e.entity
    if check_is_accumulator(entity) then
        -- check if any players have the accumulator open
        for i,t in pairs(global.players) do
            if t.ia_gui and t.ia_gui.entity == entity then
                event.dispatch{name=defines.events.on_gui_click, element=t.open_gui.close_button, player_index=i, button=defines.mouse_button_type.left, alt=false, control=false, shift=false}
            end
        end
    end
end)