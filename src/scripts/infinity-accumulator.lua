-- ----------------------------------------------------------------------------------------------------
-- INFINITY ACCUMULATOR

local event = require('scripts/lib/event-handler')
local util = require('scripts/lib/util')

-- GUI ELEMENTS
local entity_camera = require('scripts/lib/gui-elems/entity-camera')
local titlebar = require('scripts/lib/gui-elems/titlebar')

-- --------------------------------------------------
-- LOCAL UTILITIES

local constants = {
    localized_priorities = {
        {'gui-infinity-accumulator.priority-dropdown-primary'},
        {'gui-infinity-accumulator.priority-dropdown-secondary'}
    },
    localized_modes = {
        {'gui-infinity-accumulator.mode-dropdown-input'},
        {'gui-infinity-accumulator.mode-dropdown-output'},
        {'gui-infinity-accumulator.mode-dropdown-buffer'}
    },
    mode_to_index = {output=1, input=2, buffer=3},
    priority_to_index = {primary=1, secondary=2, tertiary=1},
    power_prefixes = {'kilo','mega','giga','tera','peta','exa','zetta','yotta'},
    power_suffixes_by_mode = {output='watt', input='watt', buffer='joule'}
}

local function check_is_accumulator(entity)
    return entity.name:find('infinity%-accumulator')
end

local function get_settings_from_name(name)
    name = name:gsub('(%a+)-(%a+)-', '')
    if name == 'tertiary' then return {'tertiary', 'buffer'} end
    local _,_,priority,mode = string.find(name, '(%a+)-(%a+)')
    return {priority, mode}
end

-- --------------------------------------------------
-- GUI

-- -------------------------
-- GUI HANDLERS



-- -------------------------
-- GUI MANAGEMENT

local gui = {}

function gui.create(parent, entity, player)
    local window = parent.add{type='frame', name='ee_ia_window', style='dialog_frame', direction='vertical'}
    local titlebar = titlebar.create(window, 'ee_ia_titlebar', {
        draggable = true,
        label = {'gui-infinity-accumulator.titlebar-label-caption'},
        buttons = {util.constants.close_button_def}
    })
    local content_flow = window.add{type='flow', name='ee_ia_content_flow', style='ee_entity_window_content_flow', direction='horizontal'}
    local camera = entity_camera.create(content_flow, 'ee_ia_camera', 110, {player=player, entity=entity, camera_zoom=1, camera_offset={0,-0.5}})
    local page_frame = content_flow.add{type='frame', name='ee_ia_page_frame', style='ee_ia_page_frame', direction='vertical'}
    local settings = get_settings_from_name(entity.name)
    local mode_flow = page_frame.add{type='flow', name='ee_ia_mode_flow', style='ee_vertically_centered_flow', direction='horizontal'}
    mode_flow.add{type='label', name='ee_ia_mode_label', caption={'', {'gui-infinity-accumulator.mode-label-caption'}, ' [img=info]'},
                      tooltip={'gui-infinity-accumulator.mode-label-tooltip'}}
    mode_flow.add{type='empty-widget', name='ee_ia_mode_pusher', style='ee_invisible_horizontal_pusher'}
    local mode_dropdown = mode_flow.add{type='drop-down', name='ee_ia_mode_dropdown', items=constants.localized_modes,
                                        selected_index=constants.mode_to_index[settings[2]]}
    local priority_flow = page_frame.add{type='flow', name='ee_ia_priority_flow', style='ee_vertically_centered_flow', direction='horizontal'}
    priority_flow.style.vertically_stretchable = true
    priority_flow.add{type='label', name='ee_ia_priority_label', caption={'', {'gui-infinity-accumulator.priority-label-caption'}, ' [img=info]'},
                      tooltip={'gui-infinity-accumulator.priority-label-tooltip'}}
    priority_flow.add{type='empty-widget', name='ee_ia_priority_pusher', style='ee_invisible_horizontal_pusher'}
    local priority_dropdown = priority_flow.add{type='drop-down', name='ee_ia_priority_dropdown', items=constants.localized_priorities,
                                                selected_index=constants.priority_to_index[settings[1]]}
    local priority_dropdown_dummy = priority_flow.add{type='button', name='ee_ia_priority_dropdown_dummy', style='ee_disabled_dropdown_button',
                                                      caption={'gui-infinity-accumulator.priority-dropdown-tertiary'}}
    priority_dropdown_dummy.enabled = false
    if settings[2] == 'buffer' then
        priority_dropdown.visible = false
    else
        priority_dropdown_dummy.visible = false
    end
    local slider_flow = page_frame.add{type='flow', name='ee_ia_slider_flow', style='ee_vertically_centered_flow', direction='horizontal'}
    local slider = slider_flow.add{type='slider', name='ee_ia_slider', minimum_value=0, maximum_value=999, value=500}
    local slider_textfield = slider_flow.add{type='textfield', name='ee_ia_slider_textfield', style='ee_slider_textfield', text=500, numeric=true,
                                             lose_focus_on_confirm=true, clear_and_focus_on_right_click=true}
    local items = {}
    for i,v in pairs(constants.power_prefixes) do
        items[i] = {'', {'si-prefix-symbol-' .. v}, {'si-unit-symbol-' .. constants.power_suffixes_by_mode[settings[2]]}}
    end
    local slider_dropdown = slider_flow.add{type='drop-down', name='ee_ia_slider_dropdown', items=items, selected_index=3}
    slider_dropdown.style.width = 63
    window.force_auto_center()
    return {window=window, camera=camera, mode_dropdown=mode_dropdown, priority_dropdown=priority_dropdown, priority_dropdown_dummy=priority_dropdown_dummy}
end

-- --------------------------------------------------
-- STATIC HANDLERS

-- when a GUI is opened
event.register(defines.events.on_gui_opened, function(e)
    if e.entity and check_is_accumulator(e.entity) then
        local player, player_table = util.get_player(e)
        -- create GUI
        local elems = gui.create(player.gui.screen, e.entity, player)
        player.opened = elems.window
    end
end)