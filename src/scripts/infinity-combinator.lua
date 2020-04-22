-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INFINITY COMBINATOR

local event = require("__RaiLuaLib__.lualib.event")
local util = require("scripts.util")

-- GUI ELEMENTS
local titlebar = require("scripts.gui-elems.titlebar")

local gui = {}

-- -----------------------------------------------------------------------------
-- LOCAL UTILITIES

local table_deepcopy = table.deepcopy
local table_sort = table.sort
local table_insert = table.insert
local greater_than_func = function(a, b) return a > b end

local state_to_circuit_type = {left="red", right="green"}
local circuit_type_to_state = {red="left", green="right"}

local function update_circuit_values(e)
  local players = global.players
  local tick = game.tick
  for _,pi in pairs(e.player_index and {e.player_index} or e.registered_players) do
    local gui_data = players[pi].gui.ic
    if e.override_update_rate or tick % gui_data.update_divider == 0 then
      local entity = gui_data.entity
      local network = entity.get_circuit_network(defines.wire_type[gui_data.network_color])
      if network then
        -- SORT SIGNALS
        local signals = network.signals
        if signals then
          local sorted_signals = {}
          if gui_data.sort_mode == "numerical" then
            local counts = {}
            local names_by_count = {}
            for _,t in ipairs(signals) do
              local signal = t.signal
              local name = signal.type:gsub("virtual", "virtual-signal").."/"..signal.name
              local count = t.count
              table_insert(counts, count)
              if names_by_count[count] then
                table_insert(names_by_count[count], name)
              else
                names_by_count[count] = {name}
              end
            end
            table_sort(counts, gui_data.sort_direction == "descending" and greater_than_func or nil)
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
              local name = signal.type:gsub("virtual", "virtual-signal").."/"..signal.name
              table_insert(names, name)
              amounts_by_name[name] = t.count
            end
            table_sort(names, gui_data.sort_direction == "descending" and greater_than_func or nil)
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
              local style = selected_name == signal.name and "ee_active_filter_slot_button" or "filter_slot_button"
              signals_table.add{type="sprite-button", name="ee_ic_signal_icon_"..i, style=style, number=signal.count, sprite=signal.name}
            else -- update button
              elem.sprite = signal.name
              elem.number = signal.count
              -- update selected value
              if signal.name == selected_name then
                gui_data.elems.value_textfield.text = signal.count
                updated_selected = true
                elem.style = "ee_active_filter_slot_button"
                gui_data.elems.active_button = elem
              else
                elem.style = "filter_slot_button"
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
end

local function create_sort_button(parent, mode, direction)
  return parent.add{type="sprite-button", name="ee_ic_sort_"..mode.."_"..direction.."_button", style="tool_button", sprite="ee-sort-"..mode.."-"..direction,
    tooltip={"gui-infinity-combinator.sort-"..mode.."-"..direction.."-button-tooltip"}}
end

-- -----------------------------------------------------------------------------
-- GUI

-- ----------------------------------------
-- GUI HANDLERS

local function close_button_clicked(e)
  gui.destroy(e.player_index, global.players[e.player_index])
end

local function color_switch_state_changed(e)
  local gui_data = global.players[e.player_index].gui.ic
  -- get network color from switch state
  gui_data.network_color = state_to_circuit_type[e.element.switch_state]
  -- reset bottom pane to blank
  gui_data.selected_name = nil
  gui_data.elems.selected_button.elem_value = nil
  gui_data.elems.value_textfield.text = ""
  gui_data.elems.active_button = nil
  -- update signals table
  update_circuit_values{clear_all=true, player_index=e.player_index, override_update_rate=true}
end

local function update_rate_menu_button_clicked(e)
  e.element.parent.visible = false
  e.element.parent.parent.children[2].visible = true
end

local function update_rate_back_button_clicked(e)
  e.element.parent.visible = false
  e.element.parent.parent.children[1].visible = true
end

local function update_rate_slider_value_changed(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.ic
  local elems = gui_data.elems
  elems.update_rate_textfield.text = e.element.slider_value
  gui_data.update_divider = e.element.slider_value
end

local function update_rate_textfield_text_changed(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.ic
  local new_value = util.textfield.clamp_number_input(e.element, {0}, gui_data.last_textfield_value)
  if new_value ~= gui_data.last_textfield_value then
    gui_data.last_textfield_value = new_value
    gui_data.elems.update_rate_slider.slider_value = new_value
  end
end

local function update_rate_textfield_confirmed(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.ic
  gui_data.update_divider = util.textfield.set_last_valid_value(e.element, player_table.gui.ic.last_textfield_value)
end

local function sort_menu_button_clicked(e)
  e.element.parent.visible = false
  e.element.parent.parent.children[3].visible = true
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
        e.element.style = "ee_active_tool_button"
        e.element.ignored_by_interaction = true
      else
        elem.style = "tool_button"
        elem.ignored_by_interaction = false
      end
    end
  end
  -- update GUI data
  local mode, direction = e.element.name:gsub("ee_ic_sort_", ""):gsub("_button", ""):match("(.+)_(.+)")
  local gui_data = global.players[e.player_index].gui.ic
  gui_data.sort_mode = mode
  gui_data.sort_direction = direction
  update_circuit_values{clear_all=true, player_index=e.player_index, override_update_rate=true}
end

local function signal_button_clicked(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.ic
  -- update selected icon and value textfield
  local type, name = e.element.sprite:match("(.+)/(.+)")
  type = type:gsub("%-signal", "")
  gui_data.elems.selected_button.elem_value = {type=type, name=name}
  gui_data.elems.value_textfield.text = e.element.number
  -- update button styles
  if gui_data.elems.active_button then
    gui_data.elems.active_button.style = "filter_slot_button"
  end
  e.element.style = "ee_active_filter_slot_button"
  -- update global table
  gui_data.selected_name = e.element.sprite
  gui_data.elems.active_button = e.element
end

local function selected_button_elem_changed(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.ic
  if e.element.elem_value then
    local elem = e.element.elem_value
    -- get sprite name from chosen element data
    gui_data.selected_name = elem.type:gsub("virtual", "virtual-signal").."/"..elem.name
    -- find matching button in the table and set it to the active style
    for _,elem in ipairs(gui_data.elems.signals_table.children) do
      if elem.sprite == gui_data.selected_name then
        elem.style = "ee_active_filter_slot_button"
        gui_data.elems.active_button = elem
      end
    end
  else
    -- remove selected sprite name, reset styles and text
    gui_data.selected_name = nil
    gui_data.elems.value_textfield.text = ""
    if gui_data.elems.active_button then
      gui_data.elems.active_button.style = "filter_slot_button"
    end
  end
  -- refresh the signals table
  update_circuit_values{player_index=e.player_index, override_update_rate=true}
end

event.register_conditional{
  ic_close_button_clicked = {id=defines.events.on_gui_click, handler=close_button_clicked, group="ic_gui"},
  ic_color_switch_state_changed = {id=defines.events.on_gui_switch_state_changed, handler=color_switch_state_changed, group="ic_gui"},
  ic_update_rate_menu_button_clicked = {id=defines.events.on_gui_click, handler=update_rate_menu_button_clicked, group="ic_gui"},
  ic_update_rate_back_button_clicked = {id=defines.events.on_gui_click, handler=update_rate_back_button_clicked, group="ic_gui"},
  ic_update_rate_slider_value_changed = {id=defines.events.on_gui_value_changed, handler=update_rate_slider_value_changed, group="ic_gui"},
  ic_update_rate_textfield_text_changed = {id=defines.events.on_gui_text_changed, handler=update_rate_textfield_text_changed, group="ic_gui"},
  ic_update_rate_textfield_confirmed = {id=defines.events.on_gui_confirmed, handler=update_rate_textfield_confirmed, group="ic_gui"},
  ic_sort_menu_button_clicked = {id=defines.events.on_gui_click, handler=sort_menu_button_clicked, group="ic_gui"},
  ic_sort_back_button_clicked = {id=defines.events.on_gui_click, handler=sort_back_button_clicked, group="ic_gui"},
  ic_sort_button_clicked = {id=defines.events.on_gui_click, handler=sort_button_clicked, group="ic_gui"},
  ic_signal_button_clicked = {id=defines.events.on_gui_click, handler=signal_button_clicked, group="ic_gui", options={match_filter_strings=true}},
  ic_selected_button_elem_changed = {id=defines.events.on_gui_elem_changed, handler=selected_button_elem_changed, group="ic_gui"},
  ic_update_circuit_values = {id=defines.events.on_tick, handler=update_circuit_values, group="ic_gui", options={skip_validation=true}}
}

-- ----------------------------------------
-- GUI MANAGEMENT

function gui.create(parent, player)
  -- BASE
  local window = parent.add{type="frame", name="ee_ic_window", style="dialog_frame", direction="vertical"}
  local titlebar = titlebar.create(window, "ee_ic_titlebar", {
    draggable = true,
    label = {"entity-name.ee-infinity-combinator"},
    buttons = {util.constants.close_button_def}
  })
  event.enable("ic_close_button_clicked", player.index, titlebar.children[3].index)
  local content_pane = window.add{type="frame", name="ee_ic_content_pane", style="inside_deep_frame", direction="vertical"}
  -- TOOLBAR
  local toolbar = content_pane.add{type="frame", name="ee_ic_toolbar_frame", style="subheader_frame"}
  -- main flow
  local main_toolbar_flow = toolbar.add{type="flow", name="ee_ic_toolbar_main_flow", style="ee_toolbar_flow_for_switch", direction="horizontal"}
  local color_switch = main_toolbar_flow.add{type="switch", name="ee_ic_color_switch", left_label_caption={"color.red"}, right_label_caption={"color.green"}}
  event.enable("ic_color_switch_state_changed", player.index, color_switch.index)
  util.gui.add_pusher(main_toolbar_flow, "ee_ic_toolbar_main_pusher")
  event.enable("ic_update_rate_menu_button_clicked", player.index,
    main_toolbar_flow.add{type="sprite-button", name="ee_ic_update_rate_button", style="tool_button", sprite="ee-time",
      tooltip={"gui-infinity-combinator.update-rate-menu-button-tooltip"}}.index
  )
  event.enable("ic_sort_menu_button_clicked", player.index,
    main_toolbar_flow.add{type="sprite-button", name="ee_ic_sort_menu_button", style="tool_button", sprite="ee-sort",
      tooltip={"gui-infinity-combinator.sort-menu-button-tooltip"}}.index
  )
  -- update rate flow
  local update_rate_toolbar_flow = toolbar.add{type="flow", name="ee_ic_toolbar_update_rate_flow", style="ee_toolbar_flow", direction="horizontal"}
  event.enable("ic_update_rate_back_button_clicked", player.index,
    update_rate_toolbar_flow.add{type="sprite-button", name="ee_ic_toolbar_update_rate_back_button", style="tool_button", sprite="utility/reset",
      tooltip={"gui.cancel"}}.index
  )
  local update_rate_slider = update_rate_toolbar_flow.add{type="slider", name="ee_ic_toolbar_update_rate_slider", style="ee_update_rate_slider",
    minimum_value=1, maximum_value=60}
  event.enable("ic_update_rate_slider_value_changed", player.index, update_rate_slider.index)
  local update_rate_textfield = update_rate_toolbar_flow.add{type="textfield", name="ee_ic_toolbar_update_rate_textfield", style="ee_slider_textfield",
    numeric=true, lose_focus_on_confirm=true}
  event.enable("ic_update_rate_textfield_text_changed", player.index, update_rate_textfield.index)
  event.enable("ic_update_rate_textfield_confirmed", player.index, update_rate_textfield.index)
  update_rate_toolbar_flow.visible = false
  -- sort flow
  local sort_toolbar_flow = toolbar.add{type="flow", name="ee_ic_toolbar_sort_flow", style="ee_toolbar_flow", direction="horizontal"}
  event.enable("ic_sort_back_button_clicked", player.index,
    sort_toolbar_flow.add{type="sprite-button", name="ee_ic_toolbar_sort_back_button", style="tool_button", sprite="utility/reset", tooltip={"gui.cancel"}}.index
  )
  util.gui.add_pusher(sort_toolbar_flow, "ee_ic_toolbar_sort_pusher")
  event.enable("ic_sort_button_clicked", player.index, {
    create_sort_button(sort_toolbar_flow, "alphabetical", "ascending").index,
    create_sort_button(sort_toolbar_flow, "alphabetical", "descending").index,
    create_sort_button(sort_toolbar_flow, "numerical", "ascending").index,
    create_sort_button(sort_toolbar_flow, "numerical", "descending").index
  })
  sort_toolbar_flow.visible = false
  -- SIGNALS TABLE
  local signals_scroll = content_pane.add{type="scroll-pane", name="ic_signals_scrollpane", style="signal_scroll_pane", vertical_scroll_policy="always"}
  local signals_table = signals_scroll.add{type="table", name="slot_table", style="signal_slot_table", column_count=6}
  event.enable("ic_signal_button_clicked", player.index, "ee_ic_signal_icon_")
  -- SELECTED SIGNAL
  local selected_flow = content_pane.add{type="frame", name="ee_ic_lower_flow", style="ee_current_signal_frame", direction="horizontal"}
  selected_flow.style.top_margin = 2
  local selected_button = selected_flow.add{type="choose-elem-button", name="ee_ic_selected_icon", style="ee_filter_slot_button_inset", elem_type="signal"}
  event.enable("ic_selected_button_elem_changed", player.index, selected_button.index)
  local value_textfield = selected_flow.add{type="textfield", name="ee_ic_input_textfield", style="ee_ic_value_textfield", numeric=true,
    clear_and_focus_on_right_click=true, lose_focus_on_confirm=true}
  value_textfield.ignored_by_interaction = true
  window.force_auto_center()
  return {window=window, color_switch=color_switch, update_rate_slider=update_rate_slider, update_rate_textfield=update_rate_textfield,
          sort_toolbar_flow=sort_toolbar_flow, signals_table=signals_table, selected_button=selected_button, value_textfield=value_textfield}
end

function gui.destroy(player_index, player_table)
  event.disable_group("ic_gui", player_index)
  player_table.gui.ic.elems.window.destroy()
  player_table.gui.ic = nil
end

-- -----------------------------------------------------------------------------
-- STATIC HANDLERS

-- when a player opens a GUI
event.register(defines.events.on_gui_opened, function(e)
  if e.entity and e.entity.name == "ee-infinity-combinator" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    -- create gui, set it as opened
    local elems = gui.create(player.gui.screen, player)
    player.opened = elems.window
    -- add to player table
    local gui_data = player_table.gui.ic
    gui_data.elems = elems
    gui_data.entity = e.entity
    gui_data.last_textfield_value = gui_data.update_divider
    elems.update_rate_slider.slider_value = gui_data.update_divider
    elems.update_rate_textfield.text = gui_data.update_divider
    -- set initial element states
    elems.color_switch.switch_state = circuit_type_to_state[player_table.gui.ic.network_color]
    for _,elem in ipairs(elems.sort_toolbar_flow.children) do
      if elem.name:match(gui_data.sort_mode) and elem.name:match(gui_data.sort_direction) then
        elem.style = "ee_active_tool_button"
        elem.ignored_by_interaction = true
      end
    end
    -- register function for updating values
    event.enable("ic_update_circuit_values", player.index)
    -- update values now
    update_circuit_values{clear_all=true, player_index=player.index, override_update_rate=true}
  end
end)

-- when a GUI is closed
event.register(defines.events.on_gui_closed, function(e)
  if e.gui_type == 16 and e.element and e.element.name == "ee_ic_window" then
    gui.destroy(e.player_index, global.players[e.player_index])
  end
end)