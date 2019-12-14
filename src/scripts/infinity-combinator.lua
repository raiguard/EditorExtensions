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

local table_deepcopy = table.deepcopy
local table_sort = table.sort
local table_insert = table.insert
local greater_than = function(a, b) return a > b end

local TEMP_UPDATERATE = 60

local state_to_circuit_type = {left='red', right='green'}
local circuit_type_to_state = {red='left', green='right'}

local function update_circuit_values(e)
  local players = global.players
  for _,i in pairs(e.player_index and {e.player_index} or global.combinators) do
    local gui_data = players[i].gui.ic
    local entity = gui_data.entity
    local network = entity.get_circuit_network(defines.wire_type[gui_data.cur_network_color])
    if network then
      -- SORT SIGNALS
      local signals = network.signals
      local sorted_signals = {}
      if gui_data.sort_mode == 1 then -- numerical
        local counts = {}
        local names_by_count = {}
        for _,t in ipairs(signals) do
          local signal = t.signal
          local name = signal.type:gsub('virtual', 'virtual-signal')..'/'..signal.name
          local count = t.count
          table_insert(counts, count)
          if names_by_count[count] then
            table_insert(names_by_count[count], name)
          else
            names_by_count[count] = {name}
          end
        end
        table_sort(counts, gui_data.rev_sort and greater_than)
        -- util.log(counts)
        local prev_count = -0.1 -- gauranteed to not be matching, since you can't use decimals in circuits!
        for _,c in ipairs(counts) do
          if c ~= prev_count then
            for _,n in ipairs(names_by_count[c]) do
              table_insert(sorted_signals, {count=c, name=n})
            end
            prev_count = c
          end
        end
      else -- alphabetical
        local names = {}
        local amounts_by_name = {}
        for _,t in ipairs(signals) do
          local signal = t.signal
          local name = signal.type:gsub('virtual', 'virtual-signal')..'/'..signal.name
          table_insert(names, name)
          amounts_by_name[name] = t.count
        end
        table_sort(names, gui_data.rev_sort and greater_than)
        for _,n in ipairs(names) do
          table_insert(sorted_signals, {count=amounts_by_name[n], name=n})
        end
      end
      -- UPDATE TABLE
      local signals_table = gui_data.elems.signals_table
      if e.clear_all then signals_table.clear() end
      local children = table_deepcopy(signals_table.children)
      local selected = gui_data.selected
      local updated_selected = false
      for i,signal in ipairs(sorted_signals) do
        if not children[i] then -- create button
          signals_table.add{type='sprite-button', name='ee_ic_signal_icon_'..i, style='quick_bar_slot_button', number=signal.count, sprite=signal.name}
        else -- update button
          children[i].sprite = signal.name
          children[i].number = signal.count
          -- update selected value
          if signal.name == selected then
            gui_data.elems.value_textfield.text = signal.count
            updated_selected = true
          end
          children[i] = nil
        end
      end
      -- if we selected something that is not on the list, set it to zero
      if selected and updated_selected == false then
        gui_data.elems.value_textfield.text = 0
      end
      -- delete remaining elements
      for _,elem in pairs(children) do
        elem.destroy()
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
  local gui_data = global.players[e.player_index].gui.ic
  gui_data.cur_network_color = state_to_circuit_type[e.element.switch_state]
  gui_data.selected = nil
  gui_data.elems.selected_button.elem_value = nil
  gui_data.elems.value_textfield.text = ''
  update_circuit_values{tick=game.tick, clear_all=true, player_index=e.player_index}
end

local function signal_button_clicked(e)
  local player, player_table = util.get_player(e)
  local gui_data = player_table.gui.ic
  local type, name = e.element.sprite:match('(.+)/(.+)')
  type = type:gsub('%-signal', '')
  gui_data.elems.selected_button.elem_value = {type=type, name=name}
  gui_data.elems.value_textfield.text = e.element.number
  gui_data.selected = e.element.sprite
end

local function selected_button_elem_changed(e)
  local player, player_table = util.get_player(e)
  local gui_data = player_table.gui.ic
  if e.element.elem_value then
    local elem = e.element.elem_value
    gui_data.selected = elem.type:gsub('virtual', 'virtual-signal')..'/'..elem.name
  else
    gui_data.selected = nil
    gui_data.elems.value_textfield.text = ''
  end
  update_circuit_values{tick=game.tick, player_index=e.player_index}
end

local handlers = {
  ic_close_button_clicked = close_button_clicked,
  ic_color_switch_state_changed = color_switch_state_changed,
  ic_signal_button_clicked = signal_button_clicked,
  ic_selected_button_elem_changed = selected_button_elem_changed
}

event.on_load(function()
  event.load_conditional_handlers(handlers)
  .load_conditional_handlers{ic_update_circuit_values = update_circuit_values}
end)

-- ----------------------------------------
-- GUI MANAGEMENT

function gui.create(parent, entity, player)
  -- BASE
  local window = parent.add{type='frame', name='ee_ic_window', style='dialog_frame', direction='vertical'}
  local titlebar = titlebar.create(window, 'ee_ic_titlebar', {
    draggable = true,
    label = {'entity-name.infinity-combinator'},
    buttons = {util.constants.close_button_def}
  })
  event.gui.on_click(titlebar.children[3], close_button_clicked, 'ic_close_button_clicked', player.index)
  local content_pane = window.add{type='frame', name='ee_ic_content_pane', style='inside_deep_frame', direction='vertical'}
  -- TOOLBAR
  local toolbar = content_pane.add{type='frame', name='ee_ic_toolbar_frame', style='ee_toolbar_frame_for_switch'}
  local color_switch = toolbar.add{type='switch', name='ee_ic_color_switch', left_label_caption='Red', right_label_caption='Green'}
  event.gui.on_switch_state_changed(color_switch, color_switch_state_changed, 'ic_color_switch_state_changed', player.index)
  util.gui.add_pusher(toolbar, 'ee_ic_toolbar_pusher')
  local update_rate_button = toolbar.add{type='sprite-button', name='ee_ic_updaterate_button', style='tool_button', sprite='ee-time'}
  update_rate_button.enabled = false
  local sort_button = toolbar.add{type='sprite-button', name='ee_ic_sort_button', style='tool_button', sprite='ee-sort'}
  -- SIGNALS TABLE
  local signals_scroll = content_pane.add{type='scroll-pane', name='ic_signals_scrollpane', style='signal_scroll_pane', vertical_scroll_policy='always'}
  local signals_table = signals_scroll.add{type='table', name='slot_table', style='signal_slot_table', column_count=6}
  event.gui.on_click({name_match={'ee_ic_signal_icon_'}}, signal_button_clicked, 'ic_signal_button_clicked', player.index)
  -- SELECTED SIGNAL
  local selected_flow = content_pane.add{type='frame', name='ee_ic_lower_flow', style='ee_current_signal_frame', direction='horizontal'}
  selected_flow.style.top_margin = 2
  local selected_button = selected_flow.add{type='choose-elem-button', name='ee_ic_selected_icon', style='filter_slot_button_smaller', elem_type='signal'}
  event.gui.on_elem_changed(selected_button, selected_button_elem_changed, 'ic_selected_button_elem_changed', player.index)
  local value_textfield = selected_flow.add{type='textfield', name='ee_ic_input_textfield', numeric=true,
                                          clear_and_focus_on_right_click=true, lose_focus_on_confirm=true}
  value_textfield.style.natural_width = 50
  value_textfield.style.minimal_width = 50
  value_textfield.style.horizontally_stretchable = true
  window.force_auto_center()
  return {window=window, color_switch=color_switch, signals_table=signals_table, selected_button=selected_button, value_textfield=value_textfield}
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
    elems.color_switch.switch_state = circuit_type_to_state[player_table.gui.ic.cur_network_color]
    player.opened = elems.window
    player_table.gui.ic = {
      elems = elems,
      entity = e.entity,
      cur_network_color = player_table.gui.ic.cur_network_color,
      sort_mode = 2, -- 1: numerically, 2: alphabetically
      rev_sort = true
    }
    -- register function for updating values
    event.on_nth_tick(TEMP_UPDATERATE, update_circuit_values, 'ic_update_circuit_values', player.index)
    -- add to open combinators table
    table.insert(global.combinators, player.index)
    -- update values now
    update_circuit_values{tick=game.tick, clear_all=true, player_index=player.index}
  end
end)

-- when a GUI is closed
event.register(defines.events.on_gui_closed, function(e)
  if e.gui_type == 16 and e.element.name == 'ee_ic_window' then
    gui.destroy(e.element, e.player_index)
    -- deregister on_tick
    event.deregister(-TEMP_UPDATERATE, update_circuit_values, 'ic_update_circuit_values', e.player_index)
    -- remove from open combinators table
    for i,p in ipairs(global.combinators) do
      if p == e.player_index then
        table.remove(global.combinators, i)
        break
      end
    end
  end
end)