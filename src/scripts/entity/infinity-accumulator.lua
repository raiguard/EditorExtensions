local infinity_accumulator = {}

local gui = require("__flib__.gui-beta")
local math = require("__flib__.math")
local util = require("scripts.util")

local constants = require("scripts.constants")

-- -----------------------------------------------------------------------------
-- LOCAL UTILITIES

local function get_settings_from_name(name)
  local _, _, priority, mode = string.find(name, "^ee%-infinity%-accumulator%-(%a+)%-(%a+)$")
  return priority, mode
end

local function set_entity_settings(entity, mode, buffer_size)
  local watts = util.parse_energy((buffer_size * 60).."W")

  if mode == "output" then
    entity.power_production = watts
    entity.power_usage = 0
    entity.electric_buffer_size = buffer_size
  elseif mode == "input" then
    entity.power_production = 0
    entity.power_usage = watts
    entity.electric_buffer_size = buffer_size
  elseif mode == "buffer" then
    entity.power_production = 0
    entity.power_usage = 0
    entity.electric_buffer_size = buffer_size * 60
  end
end

local function change_entity(entity, priority, mode)
  local new_entity = entity.surface.create_entity{
    name = "ee-infinity-accumulator-"..priority.."-"..mode,
    position = entity.position,
    force = entity.force,
    last_user = entity.last_user,
    create_build_effect_smoke = false
  }

  -- calculate new buffer size
  local buffer_size = entity.electric_buffer_size
  local _, old_mode = get_settings_from_name(entity.name)
  if old_mode ~= mode and old_mode == "buffer" then
    -- coming from buffer, divide by 60
    buffer_size = buffer_size / 60
  end

  set_entity_settings(new_entity, mode, buffer_size)
  entity.destroy()

  return new_entity
end

-- returns the slider value and dropdown selected index based on the entity's buffer size
local function calc_gui_values(buffer_size, mode)
  if mode ~= "buffer" then
    -- the slider is controlling watts, so inflate the buffer size by 60x to get that value
    buffer_size = buffer_size * 60
  end
  -- determine how many orders of magnitude there are
  local len = string.len(string.format("%.0f", math.floor(buffer_size)))
  -- `power` is the dropdown value - how many sets of three orders of magnitude there are, rounded down
  local power = math.floor((len - 1) / 3)
  -- slider value is the buffer size scaled to its base-three order of magnitude
  return math.floor_to(buffer_size / 10^(power * 3), 3), math.max(power, 1)
end

-- returns the entity buffer size based on the slider value and dropdown selected index
local function calc_buffer_size(slider_value, dropdown_index)
  return util.parse_energy(slider_value..constants.ia.si_suffixes_joule[dropdown_index]) / 60
end

-- -----------------------------------------------------------------------------
-- GUI

local function update_gui_mode(gui_data, mode)
  local refs = gui_data.refs
  if mode == "buffer" then
    gui_data.state.priority = "tertiary"
    refs.priority_dropdown.selected_index = constants.ia.priority_to_index["tertiary"]
    refs.priority_dropdown.enabled = false
  else
    refs.priority_dropdown.enabled = true
  end
  refs.slider_dropdown.items = constants.ia["localised_si_suffixes_"..constants.ia.power_suffixes_by_mode[mode]]

  refs.preview.entity = gui_data.state.entity
end

local function update_gui_settings(gui_data)
  local state = gui_data.state
  local refs = gui_data.refs

  local entity = state.entity
  local priority, mode = get_settings_from_name(entity.name)
  local slider_value, dropdown_index = calc_gui_values(entity.electric_buffer_size, mode)

  state.power = slider_value

  refs.preview.entity = entity
  refs.mode_dropdown.selected_index = constants.ia.mode_to_index[mode]
  refs.priority_dropdown.selected_index = constants.ia.priority_to_index[priority]
  refs.slider.slider_value = slider_value
  refs.slider_textfield.text = tostring(slider_value)
  refs.slider_textfield.style = "ee_slider_textfield"
  refs.slider_dropdown.selected_index = dropdown_index

  update_gui_mode(gui_data, mode)
end

local function close_gui(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.ia
  gui_data.refs.window.destroy()
  player_table.gui.ia = nil
  game.get_player(e.player_index).play_sound{path = "entity-close/ee-infinity-accumulator-tertiary-buffer"}
end

local function update_mode(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.ia
  local state = gui_data.state
  local refs = gui_data.refs

  local mode = constants.ia.index_to_mode[e.element.selected_index]
  if mode == "buffer" then
    state.entity = change_entity(state.entity, "tertiary", "buffer")
  else
    local priority = constants.ia.index_to_priority[refs.priority_dropdown.selected_index]
    state.entity = change_entity(state.entity, priority, mode)
  end

  update_gui_mode(gui_data, mode)
end

local function update_priority(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.ia
  local state = gui_data.state
  local refs = gui_data.refs
  local mode = constants.ia.index_to_mode[refs.mode_dropdown.selected_index]
  local priority = constants.ia.index_to_priority[e.element.selected_index]
  state.entity = change_entity(state.entity, priority, mode)
  refs.preview.entity = state.entity
end

local function update_power_from_slider(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.ia
  local state = gui_data.state
  local refs = gui_data.refs

  set_entity_settings(
    state.entity,
    constants.ia.index_to_mode[refs.mode_dropdown.selected_index],
    calc_buffer_size(e.element.slider_value, refs.slider_dropdown.selected_index)
  )
  refs.slider_textfield.text = tostring(e.element.slider_value)
end

local function update_power_from_textfield(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.ia
  local state = gui_data.state
  local refs = gui_data.refs

  local lowest = 0
  local highest = 999.999

  local new_value = tonumber(e.element.text) or -1
  local out_of_bounds = new_value < lowest or new_value > highest

  if out_of_bounds then
    refs.slider_textfield.style = "ee_invalid_slider_textfield"
  else
    refs.slider_textfield.style = "ee_slider_textfield"

    local processed_value = math.round_to(math.clamp(new_value, 0, 999.999), 3)
    state.power = processed_value
    refs.slider.slider_value = processed_value

    set_entity_settings(
      state.entity,
      constants.ia.index_to_mode[refs.mode_dropdown.selected_index],
      calc_buffer_size(processed_value, refs.slider_dropdown.selected_index)
    )
  end
end

local function confirm_textfield(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.ia
  local state = gui_data.state
  local refs = gui_data.refs

  refs.slider_textfield.text = tostring(state.power)
  refs.slider_textfield.style = "ee_slider_textfield"
end

local function update_units_of_measure(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.ia
  local state = gui_data.state
  local refs = gui_data.refs

  set_entity_settings(
    state.entity,
    constants.ia.index_to_mode[refs.mode_dropdown.selected_index],
    calc_buffer_size(refs.slider.slider_value, refs.slider_dropdown.selected_index)
  )
end

gui.add_handlers{
  ia_close = close_gui,
  ia_update_mode = update_mode,
  ia_update_priority = update_priority,
  ia_update_power_from_slider = update_power_from_slider,
  ia_update_power_from_textfield = update_power_from_textfield,
  ia_confirm_textfield = confirm_textfield,
  ia_update_units_of_measure = update_units_of_measure
}

-- TODO: when changing settings, update GUI for everyone to avoid crashes

local function create_gui(player, player_table, entity)
  local priority, mode = get_settings_from_name(entity.name)
  local slider_value, dropdown_index = calc_gui_values(entity.electric_buffer_size, mode)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      handlers = {on_closed = "ia_close"},
      ref = {"window"},
      children = {
        {type = "flow", ref = {"titlebar_flow"}, children = {
          {
            type = "label",
            style = "frame_title",
            caption = {"entity-name.ee-infinity-accumulator"},
            ignored_by_interaction = true
          },
          {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
          util.close_button{on_click = "ia_close"}
        }},
        {type = "frame", style = "entity_frame", direction = "vertical", children = {
          {type = "frame", style = "deep_frame_in_shallow_frame", children = {
            {
              type = "entity-preview",
              style = "wide_entity_button",
              elem_mods = {entity = entity},
              ref = {"preview"}
            }
          }},
          {type = "flow", style_mods = {top_margin = 4, vertical_align = "center"}, children = {
            {type = "label", caption = {"ee-gui.mode"}},
            {type = "empty-widget", style = "flib_horizontal_pusher"},
            {
              type = "drop-down",
              items = constants.ia.localised_modes,
              selected_index = constants.ia.mode_to_index[mode],
              handlers = {on_selection_state_changed = "ia_update_mode"},
              ref = {"mode_dropdown"}
            }
          }},
          {type = "line", style_mods = {horizontally_stretchable = true}, direction = "horizontal"},
          {type = "flow", style_mods = {vertical_align = "center"}, children = {
            {
              type = "label",
              caption = {"", {"ee-gui.priority"}, " [img=info]"},
              tooltip = {"ee-gui.ia-priority-description"}
            },
            {type = "empty-widget", style = "flib_horizontal_pusher"},
            {
              type = "drop-down",
              items = constants.ia.localised_priorities,
              selected_index = constants.ia.priority_to_index[priority],
              elem_mods = {enabled = mode ~= "buffer"},
              handlers = {on_selection_state_changed = "ia_update_priority"},
              ref = {"priority_dropdown"}
            }
          }},
          {type = "line", style_mods = {horizontally_stretchable = true}, direction = "horizontal"},
          {type = "flow", style_mods = {vertical_align = "center"}, children = {
            {
              type = "label",
              style_mods = {right_margin = 6},
              caption = {"ee-gui.power"}
            },
            {
              type = "slider",
              style_mods = {horizontally_stretchable = true},
              minimum_value = 0,
              maximum_value = 999,
              value = slider_value,
              handlers = {on_value_changed = "ia_update_power_from_slider"},
              ref = {"slider"}
            },
            {
              type = "textfield",
              style = "ee_slider_textfield",
              text = slider_value,
              numeric = true,
              allow_decimal = true,
              lose_focus_on_confirm = true,
              clear_and_focus_on_right_click = true,
              handlers = {
                on_confirmed = "ia_confirm_textfield",
                on_text_changed = "ia_update_power_from_textfield"
              },
              ref = {"slider_textfield"}
            },
            {
              type = "drop-down",
              style_mods = {width = 69},
              selected_index = dropdown_index,
              items = constants.ia["localised_si_suffixes_"..constants.ia.power_suffixes_by_mode[mode]],
              handlers = {on_selection_state_changed = "ia_update_units_of_measure"},
              ref = {"slider_dropdown"}
            }
          }}
        }
      }
    }}
  })

  refs.window.force_auto_center()
  refs.titlebar_flow.drag_target = refs.window

  player.opened = refs.window

  player_table.gui.ia = {
    state = {
      entity = entity,
      power = tonumber(refs.slider_textfield.text)
    },
    refs = refs
  }
end

-- -----------------------------------------------------------------------------
-- FUNCTIONS

function infinity_accumulator.open(player_index, entity)
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]
  create_gui(player, player_table, entity)
  player.play_sound{path = "entity-open/ee-infinity-accumulator-tertiary-buffer"}
end

function infinity_accumulator.paste_settings(source, destination)
  -- get players viewing the destination accumulator
  local to_update = {}
  for i, player_table in pairs(global.players) do
    if player_table.gui.ia and player_table.gui.ia.state.entity == destination then
      to_update[#to_update+1] = i
    end
  end
  -- update entity
  local priority, mode = get_settings_from_name(source.name)
  local new_entity
  if mode == "buffer" then
    new_entity = change_entity(destination, "tertiary", "buffer")
  else
    new_entity = change_entity(destination, priority, mode)
  end
  -- update open GUIs
  for _, i in ipairs(to_update) do
    local player_table = global.players[i]
    player_table.gui.ia.state.entity = new_entity
    update_gui_settings(player_table.gui.ia)
  end
end

function infinity_accumulator.close_open_guis(entity)
  for i, t in pairs(global.players) do
    if t.gui.ia and t.gui.ia.state.entity == entity then
      close_gui{player_index = i}
    end
  end
end

return infinity_accumulator