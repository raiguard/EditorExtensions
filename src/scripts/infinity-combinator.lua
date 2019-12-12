-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INFINITY COMBINATOR

local event = require('lualib/event')
local util = require('lualib/util')

-- GUI ELEMENTS
local entity_camera = require('lualib/gui-elems/entity-camera')
local titlebar = require('lualib/gui-elems/titlebar')

local gui = {}

-- --------------------------------------------------------------------------------
-- LOCAL UTILITIES

local TEMP_UPDATERATE = 1

local state_to_circuit_type = {left='red', right='green'}

local function update_circuit_values(e)
  local players = global.players
  for i,_ in pairs(global.combinators) do
    local gui_data = players[i].gui.ic
    local entity = gui_data.entity
    local control = entity.get_or_create_control_behavior()
    local network = entity.get_circuit_network(defines.wire_type[state_to_circuit_type[gui_data.elems.color_switch.switch_state]])
    local signals_table = gui_data.elems.signals_table
    if e.clear_all then signals_table.clear() end
    if network then
      if #signals_table.children == 0 then
        -- create initial table
        for _,signal in ipairs(network.signals or {}) do
          if signal.signal.type == 'virtual' then signal.signal.type = 'virtual-signal' end
          signals_table.add{type='sprite-button', name='ee_ic_signal_icon_'..signal.signal.name, style='quick_bar_slot_button', number=signal.count,
                            sprite=signal.signal.type..'/'..signal.signal.name}
        end
      else
        -- update existing table
        local elems_by_name = {}
        for _,elem in pairs(signals_table.children) do
          elems_by_name[elem.name:gsub('ee_ic_signal_icon_', '')] = elem
        end
        for _,signal in ipairs(network.signals or {}) do
          if signal.signal.type == 'virtual' then signal.signal.type = 'virtual-signal' end
          local e = elems_by_name[signal.signal.name]
          if e then
            elems_by_name[signal.signal.name] = nil
            if e.number ~= signal.count then
              -- update number
              e.number = signal.count
            end
          elseif not e then
            -- add to table
            signals_table.add{type='sprite-button', name='ee_ic_signal_icon_'..signal.signal.name, style='quick_bar_slot_button', number=signal.count,
                              sprite=signal.signal.type..'/'..signal.signal.name}
          end
        end
        -- remove outdated elements
        for name,elem in pairs(elems_by_name) do
          elem.destroy()
        end
      end
    end
  end
end

-- --------------------------------------------------------------------------------
-- GUI

-- ----------------------------------------
-- GUI HANDLERS

local function close_button_clicked(e)
  -- invoke GUI closed event
  event.raise(defines.events.on_gui_closed, {element=e.element.parent.parent, gui_type=16, player_index=e.player_index, tick=game.tick})
end

local function color_switch_state_changed(e)
  update_circuit_values{tick=game.tick, clear_all=true}
end

local handlers = {
  ic_close_button_clicked = close_button_clicked,
  ic_color_switch_state_changed = color_switch_state_changed
}

event.on_load(function()
  event.load_conditional_handlers(handlers)
  .load_conditional_handlers{ic_update_circuit_values = update_circuit_values}
end)

-- ----------------------------------------
-- GUI MANAGEMENT

function gui.create(parent, entity, player)
  local window = parent.add{type='frame', name='ee_ic_window', style='dialog_frame', direction='vertical'}
  local titlebar = titlebar.create(window, 'ee_ic_titlebar', {
    draggable = true,
    label = {'entity-name.infinity-combinator'},
    buttons = {util.constants.close_button_def}
  })
  event.gui.on_click(titlebar.children[3], close_button_clicked, 'ic_close_button_clicked', player.index)
  local content_pane = window.add{type='frame', name='ee_ic_content_pane', style='inside_deep_frame', direction='vertical'}
  local toolbar = content_pane.add{type='frame', name='ee_ic_toolbar_frame', style='ee_toolbar_frame_for_switch'}
  local color_switch = toolbar.add{type='switch', name='ee_ic_color_switch', left_label_caption='Red', right_label_caption='Green'}
  event.gui.on_switch_state_changed(color_switch, color_switch_state_changed, 'ic_color_switch_state_changed', player.index)
  util.gui.add_pusher(toolbar, 'ee_ic_toolbar_pusher')
  local update_rate_button = toolbar.add{type='sprite-button', name='ee_ic_updaterate_button', style='tool_button', sprite='ee-time'}
  update_rate_button.enabled = false
  local sort_button = toolbar.add{type='sprite-button', name='ee_ic_sort_button', style='tool_button', sprite='ee-sort'}
  sort_button.enabled = false
  local signals_scroll = content_pane.add{type='scroll-pane', name='ic_signals_scrollpane', style='signal_scroll_pane', vertical_scroll_policy='always'}
  local signals_table = signals_scroll.add{type='table', name='slot_table', style='signal_slot_table', column_count=6}
  local bottom_flow = content_pane.add{type='frame', name='ee_ic_lower_flow', style='ee_current_signal_frame', direction='horizontal'}
  bottom_flow.style.top_margin = 2
  bottom_flow.add{type='choose-elem-button', name='ee_ic_selected_icon', style='filter_slot_button_smaller', sprite='item/iron-ore', elem_type='signal'}
  local value_textfield = bottom_flow.add{type='textfield', name='ee_ic_input_textfield', numeric=true,
                                          clear_and_focus_on_right_click=true, lose_focus_on_confirm=true}
  value_textfield.style.natural_width = 50
  value_textfield.style.minimal_width = 50
  value_textfield.style.horizontally_stretchable = true
  window.force_auto_center()
  return {window=window, color_switch=color_switch, signals_table=signals_table, value_textfield=value_textfield}
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

-- when a player opens a GUI
event.register(defines.events.on_gui_opened, function(e)
  if e.entity and e.entity.name == 'infinity-combinator' then
    local player, player_table = util.get_player(e)
    local elems = gui.create(player.gui.screen, e.entity, player)
    player.opened = elems.window
    player_table.gui.ic = {elems=elems, entity=e.entity}
    -- register function for updating values
    event.on_nth_tick(TEMP_UPDATERATE, update_circuit_values, 'ic_update_circuit_values', player.index)
    -- update values now
    update_circuit_values{tick=game.tick}
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
    event.deregister(-TEMP_UPDATERATE, update_circuit_values, 'ic_update_circuit_values', e.player_index)
    -- remove from open combinators table
    global.combinators[e.player_index] = nil
  end
end)