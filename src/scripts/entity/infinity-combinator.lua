local infinity_combinator = {}

local gui = require("__flib__.control.gui")
local util = require("scripts.util")

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
  for _, pi in pairs(e.player_index and {e.player_index} or e.registered_players) do
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
            for _, t in ipairs(signals) do
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
            for _, c in ipairs(counts) do
              if c ~= prev_count then
                for _, n in ipairs(names_by_count[c]) do
                  table_insert(sorted_signals, {count=c, name=n})
                end
                prev_count = c
              end
            end
          else
            local names = {}
            local amounts_by_name = {}
            for _, t in ipairs(signals) do
              local signal = t.signal
              local name = signal.type:gsub("virtual", "virtual-signal").."/"..signal.name
              table_insert(names, name)
              amounts_by_name[name] = t.count
            end
            table_sort(names, gui_data.sort_direction == "descending" and greater_than_func or nil)
            for _, n in ipairs(names) do
              table_insert(sorted_signals, {count=amounts_by_name[n], name=n})
            end
          end
          -- UPDATE TABLE
          local signals_table = gui_data.elems.signals_table
          if e.clear_all then signals_table.clear() end
          local children = table_deepcopy(signals_table.children)
          local selected_name = gui_data.selected_name
          local updated_selected = false
          for i, signal in ipairs(sorted_signals) do
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
          for _, elem in pairs(children) do
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

gui.add_templates{
  tool_button = {type="sprite-button", style="tool_button", mouse_button_filter={"left"}},
  ic = {
    back_button = {type="sprite-button", style="tool_button", tooltip={"gui.cancel"}, sprite="utility/reset", mouse_button_filter={"left"}},
    sort_button = function(mode, direction)
      return {type="sprite-button", name="ee_ic_sort__"..mode.."_"..direction, style="tool_button", sprite="ee_sort_"..mode.."_"..direction,
        tooltip={"", {"ee-gui."..mode}, ", ", {"ee-gui."..direction}}, mouse_button_filter={"left"}}
    end
  }
}

gui.add_handlers{
  ic = {
    close_button = {
      on_gui_click = function(e)
        gui.handlers.ic.window.on_gui_closed(e)
      end
    },
    toolbar = {
      main = {
        color_switch = {
          on_gui_switch_state_changed = function(e)

          end
        },
        rate_button = {
          on_gui_click = function(e)

          end
        },
        sort_button = {
          on_gui_click = function(e)

          end
        }
      },
      rate = {
        back_button = {
          on_gui_click = function(e)

          end
        },
        slider = {
          on_gui_value_changed = function(e)

          end
        },
        textfield = {
          on_gui_text_changed = function(e)

          end,
          on_gui_confirmed = function(e)

          end
        }
      },
      sort = {
        back_button = {
          on_gui_click = function(e)

          end
        },
        sort_button = {
          on_gui_click = function(e)

          end
        }
      }
    },
    window = {
      on_gui_closed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.ic
        gui.remove_filters(e.player_index, gui_data.filters)
        gui_data.window.destroy()
        player_table.gui.ic = nil
      end
    }
  }
}

-- TODO: hook up GUI handlers

local function create_gui(player, player_table, entity)
  local gui_data, filters = gui.build(player.gui.screen, {
    {type="frame", style="dialog_frame", direction="vertical", handlers="ic.window", save_as="window", children={
      {type="flow", children={
        {type="label", style="frame_title", caption={"entity-name.ee-infinity-combinator"}},
        {template="titlebar_drag_handle"},
        {template="close_button", handlers="ic.close_button"}
      }},
      {type="frame", style="inside_deep_frame", direction="vertical", children={
        -- toolbar
        {type="frame", style="subheader_frame", children={
          {type="flow", style="ee_toolbar_flow_for_switch", children={
            {type="switch", left_label_caption={"color.red"}, right_label_caption={"color.green"}, handlers="ic.toolbar.main.color_switch",
              save_as="toolbar.main.color_switch"},
            {template="pushers.horizontal"},
            {template="tool_button", tooltip={"ee-gui.update-rate"}, sprite="ee_time", handlers="ic.toolbar.main.rate_button"},
            {template="tool_button", tooltip={"ee-gui.sort"}, sprite="ee_sort", handlers="ic.toolbar.main.sort_button"},
          }},
          {type="flow", style="ee_toolbar_flow", mods={visible=false}, children={
            {template="ic.back_button", handlers="ic.toolbar.rate.back_button"},
            {type="slider", style="ee_update_rate_slider", minimum_value=1, maximum_value=60, handlers="ic.toolbar.rate.slider", save_as="toolbar.rate.slider"},
            {type="textfield", style="ee_slider_textfield", numeric=true, lose_focus_on_confirm=true, clear_and_focus_on_right_click=true,
              handlers="ic.toolbar.rate.textfield", save_as="toolbar.rate.textfield"}
          }},
          {type="flow", style="ee_toolbar_flow", mods={visible=false}, children={
            {template="ic.back_button", handlers="ic.toolbar.sort.back_button"},
            {template="pushers.horizontal"},
            gui.templates.ic.sort_button("alphabetical", "ascending"),
            gui.templates.ic.sort_button("alphabetical", "descending"),
            gui.templates.ic.sort_button("numerical", "ascending"),
            gui.templates.ic.sort_button("numerical", "descending")
          }}
        }},
        -- signals table
        {type="scroll-pane", style="ee_ic_signals_scroll_pane", vertical_scroll_policy="always", save_as="signals_scroll_pane", children={
          {type="table", style="filter_slot_table", column_count=6}
        }},
        -- selected signal
        {type="frame", style="ee_ic_current_signal_frame", children={
          {type="choose-elem-button", style="ee_filter_slot_button_inset", elem_type="signal"},
          {type="textfield", style="ee_ic_value_textfield", numeric=true, clear_and_focus_on_right_click=true, lose_focus_on_confirm=true,
            mods={ignored_by_interaction=true}}
        }}
      }}
    }}
  })

  gui_data.window.force_auto_center()
  gui_data.drag_handle.drag_target = gui_data.window

  player.opened = gui_data.window

  gui_data.filters = filters
  gui_data.entity = entity

  player_table.gui.ic = gui_data
end

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

function infinity_combinator.on_gui_opened(e)
  if e.entity and e.entity.name == "ee-infinity-combinator" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    create_gui(player, player_table, e.entity)
    -- -- create gui, set it as opened
    -- local elems = gui.create(player.gui.screen, player)
    -- player.opened = elems.window
    -- -- add to player table
    -- local gui_data = player_table.gui.ic
    -- gui_data.elems = elems
    -- gui_data.entity = e.entity
    -- gui_data.last_textfield_value = gui_data.update_divider
    -- elems.update_rate_slider.slider_value = gui_data.update_divider
    -- elems.update_rate_textfield.text = gui_data.update_divider
    -- -- set initial element states
    -- elems.color_switch.switch_state = circuit_type_to_state[player_table.gui.ic.network_color]
    -- for _, elem in ipairs(elems.sort_toolbar_flow.children) do
    --   if elem.name:match(gui_data.sort_mode) and elem.name:match(gui_data.sort_direction) then
    --     elem.style = "ee_active_tool_button"
    --     elem.ignored_by_interaction = true
    --   end
    -- end
    -- -- register function for updating values
    -- event.enable("ic_update_circuit_values", player.index)
    -- -- update values now
    -- update_circuit_values{clear_all=true, player_index=player.index, override_update_rate=true}
  end
end

return infinity_combinator