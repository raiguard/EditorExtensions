-- ----------------------------------------------------------------------------------------------------
-- INFINITY ACCUMULATOR

local event = require('lualib/event')
local util = require('lualib/util')

-- GUI ELEMENTS
local entity_camera = require('lualib/gui-elems/entity-camera')
local titlebar = require('lualib/gui-elems/titlebar')

local gui = {}

-- --------------------------------------------------
-- LOCAL UTILITIES

-- creates a toolbar
local function create_toolbar(parent, color)
    local prefix = 'ee_ic_'..color..'_toolbar_'
    local frame = parent.add{type='frame', name=prefix..'frame', style='subheader_frame', direction='horizontal'}
    frame.add{type='label', name=prefix..'label', style='subheader_caption_label', caption={'gui-infinity-combinator.'..color..'-toolbar-label-caption'}}
    frame.add{type='empty-widget', name=prefix..'pusher', style='ee_invisible_horizontal_pusher'}
    frame.add{type='sprite-button', name=prefix..'search_button', style='tool_button', sprite='utility/search_icon'}
    frame.add{type='sprite-button', name=prefix..'reset_button', style='tool_button', sprite='utility/reset'}.enabled = false
    return frame
end

-- --------------------------------------------------
-- GUI

-- -------------------------
-- GUI HANDLERS

local function close_button_clicked(e)
    -- invoke GUI closed event
    event.raise(defines.events.on_gui_closed, {element=e.element.parent.parent, gui_type=16, player_index=e.player_index, tick=game.tick})
end

local function update_circuit_values(e)
    local players = global.players
    for i,_ in pairs(global.combinators) do
        local gui_data = players[i].gui.ic
        local entity = gui_data.entity
        local control = entity.get_or_create_control_behavior()
        for _,type in ipairs{'red', 'green'} do
            local network = entity.get_circuit_network(defines.wire_type[type])
            if network then
                local scroll = gui_data.elems[type..'_scroll']
                scroll.clear()
                for i,signal in ipairs(network.signals or {}) do
                    if signal.signal.type == 'virtual' then signal.signal.type = 'virtual-signal' end
                    -- create frame
                    local frame = scroll.add{type='frame', name='ee_ic_red_signal_frame_'..i, style='train_schedule_condition_frame', direction='horizontal'}
                    frame.add{type='sprite-button', name='ee_ic_red_signal_icon_'..i, style='ee_'..type..'_circuit_signal_slot_button', sprite=signal.signal.type..'/'..signal.signal.name}
                    frame.add{type='label', name='ee_ic_red_signal_label_'..i, caption=signal.count}
                end
            end
        end
    end
end

local handlers = {
    ic_close_button_clicked = close_button_clicked
}

event.on_load(function()
    event.load_conditional_handlers(handlers)
    .load_conditional_handlers{ic_update_circuit_values = update_circuit_values}
end)

-- -------------------------
-- GUI MANAGEMENT

function gui.create(parent, entity, player)
    local control = entity.get_or_create_control_behavior()
    local parameters = control.parameters.parameters
    local window = parent.add{type='frame', name='ee_ic_window', style='dialog_frame', direction='vertical'}
    local titlebar = titlebar.create(window, 'ee_ic_titlebar', {
        draggable = true,
        label = {'entity-name.infinity-combinator'},
        buttons = {util.constants.close_button_def}
    })
    event.gui.on_click(titlebar.children[3], close_button_clicked, 'ic_close_button_clicked', player.index)
    local scrolls_flow = window.add{type='flow', name='ee_ic_scrolls_flow', style='ee_circuit_signals_flow', direction='horizontal'}
    local red_frame = scrolls_flow.add{type='frame', name='ee_ic_red_frame', style='inside_deep_frame', direction='vertical'}
    local red_toolbar = create_toolbar(red_frame, 'red')
    local red_signals_scroll = red_frame.add{type='scroll-pane', name='ee_ic_red_signals_scrollpane', style='ee_circuit_signals_scroll_pane',
                                             direction='vertical', vertical_scroll_policy='always'}
    local green_frame = scrolls_flow.add{type='frame', name='ee_ic_green_frame', style='inside_deep_frame', direction='vertical'}
    local green_toolbar = create_toolbar(green_frame, 'green')
    local green_signals_scroll = green_frame.add{type='scroll-pane', name='ee_ic_green_signals_scrollpane', style='ee_circuit_signals_scroll_pane',
                                                 direction='vertical', vertical_scroll_policy='always'}
    window.force_auto_center()
    return {window=window, red_scroll=red_signals_scroll, green_scroll=green_signals_scroll}
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
-- STATIC HANDLERS

-- when a player opens a GUI
event.register(defines.events.on_gui_opened, function(e)
    if e.entity and e.entity.name == 'infinity-combinator' then
        local player, player_table = util.get_player(e)
        local elems = gui.create(player.gui.screen, e.entity, player)
        player.opened = elems.window
        player_table.gui.ic = {elems=elems, entity=e.entity}
        -- register on_tick for updating values
        event.register(defines.events.on_tick, update_circuit_values, 'ic_update_circuit_values', player.index)
        -- add to open combinators table
        global.combinators[player.index] = true
    end
end)

-- when a GUI is closed
event.register(defines.events.on_gui_closed, function(e)
    if e.gui_type == 16 and e.element.name == 'ee_ic_window' then
        gui.destroy(e.element, e.player_index)
        util.player_table(e).gui.ic = nil
        -- deregister on_tick
        event.deregister(defines.events.on_tick, update_circuit_values, 'ic_update_circuit_values', e.player_index)
        -- remove from open combinators table
        global.combinators[e.player_index] = nil
    end
end)