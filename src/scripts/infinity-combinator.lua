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

local TEMP_UPDATERATE = 30

local table_deepcopy = table.deepcopy
local table_sort = table.sort
local table_insert = table.insert
local greater_than_func = function(a, b) return a > b end

local state_to_circuit_type = {left='red', right='green'}
local circuit_type_to_state = {red='left', green='right'}

local function update_circuit_values(e)
  local players = global.players
  for _,i in pairs(e.player_index and {e.player_index} or global.combinators) do
    local gui_data = players[i].gui.ic
    local entity = gui_data.entity
    local network = entity.get_circuit_network(defines.wire_type[gui_data.network_color])
    if network then
      -- SORT SIGNALS
      local signals = network.signals
      if signals then
        local sorted_signals = {}
        if gui_data.sort_mode == 'numerical' then
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
          table_sort(counts, gui_data.sort_direction == 'descending' and greater_than_func or nil)
          local prev_count = -0.1 -- gauranteed to not match initially, since you can't use decimals in circuits!
          for _,c in ipairs(counts) do
            if c ~= prev_count then
              for _,n in ipairs(names_by_count[c]) do
                table_insert(sorted_signals, {count=c, name=n})
              end
              prev_count = c
            end
          end
        else
          local names = {}
          local amounts_by_name = {}
          for _,t in ipairs(signals) do
            local signal = t.signal
            local name = signal.type:gsub('virtual', 'virtual-signal')..'/'..signal.name
            table_insert(names, name)
            amounts_by_name[name] = t.count
          end
          table_sort(names, gui_data.sort_direction == 'descending' and greater_than_func or nil)
          for _,n in ipairs(names) do
            table_insert(sorted_signals, {count=amounts_by_name[n], name=n})
          end
        end
        -- UPDATE TABLE
        local signals_table = gui_data.elems.signals_table
        if e.clear_all then signals_table.clear() end
        local children = table_deepcopy(signals_table.children)
        local selected_name = gui_data.selected_name
        local updated_selected = false
        for i,signal in ipairs(sorted_signals) do
          local elem = children[i]
          if not elem then -- create button
            local style = selected_name == signal.name and 'ee_active_filter_slot_button' or 'filter_slot_button'
            signals_table.add{type='sprite-button', name='ee_ic_signal_icon_'..i, style=style, number=signal.count, sprite=signal.name}
          else -- update button
            elem.sprite = signal.name
            elem.number = signal.count
            -- update selected value
            if signal.name == selected_name then
              gui_data.elems.value_textfield.text = signal.count
              updated_selected = true
            end
            children[i] = nil
          end
        end
        -- if we selected something that is not on the list, set it to zero
        if selected_name and updated_selected == false then
          gui_data.elems.value_textfield.text = 0
        end
        -- delete remaining elements
        for _,elem in pairs(children) do
          elem.destroy()
        end
      end
    end
  end
end

local function create_sort_button(parent, mode, direction)
  return parent.add{type='sprite-button', name='ee_ic_sort_'..mode..'_'..direction..'_button', style='tool_button',
                    sprite='ee-sort-'..mode..'-'..direction, tooltip={'gui-infinity-combinator.sort-'..mode..'-'..direction..'-button-tooltip'}}
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
  -- get network color from switch state
  gui_data.network_color = state_to_circuit_type[e.element.switch_state]
  -- reset bottom pane to blank
  gui_data.selected_name = nil
  gui_data.elems.selected_button.elem_value = nil
  gui_data.elems.value_textfield.text = ''
  gui_data.elems.active_button = nil
  -- update signals table
  update_circuit_values{clear_all=true, player_index=e.player_index}
end

local function sort_menu_button_clicked(e)
  e.element.parent.visible = false
  e.element.parent.parent.children[2].visible = true
end

local function sort_back_button_clicked(e)
  e.element.parent.visible = false
  e.element.parent.parent.children[1].visible = true
end

local function sort_button_clicked(e)
  -- update button styles
  for i,elem in ipairs(e.element.parent.children) do
    if i > 2 then
      if elem == e.element then
        e.element.style = 'ee_active_tool_button'
        e.element.ignored_by_interaction = true
      else
        elem.style = 'tool_button'
        elem.ignored_by_interaction = false
      end
    end
  end
  -- update GUI data
  local mode, direction = e.element.name:gsub('ee_ic_sort_', ''):gsub('_button', ''):match('(.+)_(.+)')
  local gui_data = util.player_table(e).gui.ic
  gui_data.sort_mode = mode
  gui_data.sort_direction = direction
  update_circuit_values{clear_all=true, player_index=e.player_index}
end

local function signal_button_clicked(e)
  local player, player_table = util.get_player(e)
  local gui_data = player_table.gui.ic
  -- update selected icon and value textfield
  local type, name = e.element.sprite:match('(.+)/(.+)')
  type = type:gsub('%-signal', '')
  gui_data.elems.selected_button.elem_value = {type=type, name=name}
  gui_data.elems.value_textfield.text = e.element.number
  -- update button styles
  if gui_data.elems.active_button then
    gui_data.elems.active_button.style = 'filter_slot_button'
  end
  e.element.style = 'ee_active_filter_slot_button'
  -- update global table
  gui_data.selected_name = e.element.sprite
  gui_data.elems.active_button = e.element
end

local function selected_button_elem_changed(e)
  local player, player_table = util.get_player(e)
  local gui_data = player_table.gui.ic
  if e.element.elem_value then
    local elem = e.element.elem_value
    -- get sprite name from chosen element data
    gui_data.selected_name = elem.type:gsub('virtual', 'virtual-signal')..'/'..elem.name
    -- find matching button in the table and set it to the active style
    for _,elem in ipairs(gui_data.elems.signals_table.children) do
      if elem.sprite == gui_data.selected_name then
        elem.style = 'ee_active_filter_slot_button'
        gui_data.elems.active_button = elem
      end
    end
  else
    -- remove selected sprite name, reset styles and text
    gui_data.selected_name = nil
    gui_data.elems.value_textfield.text = ''
    gui_data.elems.active_button.style = 'filter_slot_button'
  end
  -- refresh the signals table
  update_circuit_values{player_index=e.player_index}
end

local handlers = {
  ic_close_button_clicked = close_button_clicked,
  ic_color_switch_state_changed = color_switch_state_changed,
  ic_sort_menu_button_clicked = sort_menu_button_clicked,
  ic_sort_back_button_clicked = sort_back_button_clicked,
  ic_sort_button_clicked = sort_button_clicked,
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
  local toolbar = content_pane.add{type='frame', name='ee_ic_toolbar_frame', style='subheader_frame'}
  -- main flow
  local main_toolbar_flow = toolbar.add{type='flow', name='ee_ic_toolbar_main_flow', style='ee_toolbar_flow_for_switch', direction='horizontal'}
  local color_switch = main_toolbar_flow.add{type='switch', name='ee_ic_color_switch', left_label_caption={'color.red'}, right_label_caption={'color.green'}}
  event.gui.on_switch_state_changed(color_switch, color_switch_state_changed, 'ic_color_switch_state_changed', player.index)
  util.gui.add_pusher(main_toolbar_flow, 'ee_ic_toolbar_main_pusher')
  local update_rate_button = main_toolbar_flow.add{type='sprite-button', name='ee_ic_updaterate_button', style='tool_button', sprite='ee-time'}
  update_rate_button.enabled = false
  event.gui.on_click(
    main_toolbar_flow.add{type='sprite-button', name='ee_ic_sort_menu_button', style='tool_button', sprite='ee-sort',
                          tooltip={'gui-infinity-combinator.sort-menu-button-tooltip'}},
    sort_menu_button_clicked, 'ic_sort_menu_button_clicked', player.index
  )
  -- sort flow
  local sort_toolbar_flow = toolbar.add{type='flow', name='ee_ic_toolbar_sort_flow', style='ee_toolbar_flow', direction='horizontal'}
  event.gui.on_click(
    sort_toolbar_flow.add{type='sprite-button', name='ee_ic_toolbar_sort_back_button', style='tool_button', sprite='utility/reset', tooltip={'gui.cancel'}},
    sort_back_button_clicked, 'ic_sort_back_button_clicked', player.index
  )
  util.gui.add_pusher(sort_toolbar_flow, 'ee_ic_toolbar_sort_pusher')
  event.gui.on_click({
    element = {
      create_sort_button(sort_toolbar_flow, 'alphabetical', 'ascending'),
      create_sort_button(sort_toolbar_flow, 'alphabetical', 'descending'),
      create_sort_button(sort_toolbar_flow, 'numerical', 'ascending'),
      create_sort_button(sort_toolbar_flow, 'numerical', 'descending')
    }}, sort_button_clicked, 'ic_sort_button_clicked', player.index
  )
  sort_toolbar_flow.visible = false
  -- SIGNALS TABLE
  local signals_scroll = content_pane.add{type='scroll-pane', name='ic_signals_scrollpane', style='signal_scroll_pane', vertical_scroll_policy='always'}
  local signals_table = signals_scroll.add{type='table', name='slot_table', style='signal_slot_table', column_count=6}
  event.gui.on_click({name_match={'ee_ic_signal_icon_'}}, signal_button_clicked, 'ic_signal_button_clicked', player.index)
  -- SELECTED SIGNAL
  local selected_flow = content_pane.add{type='frame', name='ee_ic_lower_flow', style='ee_current_signal_frame', direction='horizontal'}
  selected_flow.style.top_margin = 2
  local selected_button = selected_flow.add{type='choose-elem-button', name='ee_ic_selected_icon', style='filter_slot_button', elem_type='signal'}
  event.gui.on_elem_changed(selected_button, selected_button_elem_changed, 'ic_selected_button_elem_changed', player.index)
  local value_textfield = selected_flow.add{type='textfield', name='ee_ic_input_textfield', style='ee_ic_value_textfield', numeric=true,
                                            clear_and_focus_on_right_click=true, lose_focus_on_confirm=true}
  value_textfield.ignored_by_interaction = true
  window.force_auto_center()
  return {window=window, color_switch=color_switch, sort_toolbar_flow=sort_toolbar_flow, signals_table=signals_table, selected_button=selected_button,
          value_textfield=value_textfield}
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
    -- create gui, set it as opened
    local elems = gui.create(player.gui.screen, e.entity, player)
    player.opened = elems.window
    -- add to player table
    local gui_data = player_table.gui.ic
    gui_data.elems = elems
    gui_data.entity = e.entity
    -- set initial element states
    elems.color_switch.switch_state = circuit_type_to_state[player_table.gui.ic.network_color]
    for _,elem in ipairs(elems.sort_toolbar_flow.children) do
      if elem.name:match(gui_data.sort_mode) and elem.name:match(gui_data.sort_direction) then
        elem.style = 'ee_active_tool_button'
        elem.ignored_by_interaction = true
      end
    end
    -- register function for updating values
    event.on_nth_tick(TEMP_UPDATERATE, update_circuit_values, 'ic_update_circuit_values', player.index)
    -- add to open combinators table
    table.insert(global.combinators, player.index)
    -- update values now
    update_circuit_values{clear_all=true, player_index=player.index}
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