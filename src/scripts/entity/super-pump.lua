local super_pump = {}

local gui = require("__flib__.gui-beta")
local math = require("__flib__.math")

local constants = require("scripts.constants")

local util = require("scripts.util")

-- -----------------------------------------------------------------------------
-- ENTITY FUNCTIONS

-- TODO keep disabled until both connections are made, to avoid WATER HAMMER

local function set_speed(entity, speed)
  entity.fluidbox[2] = {
    name = "ee-super-pump-speed-fluid",
    amount = 100000000000,
    temperature = speed + 0.01 -- avoid floating point imprecision
  }
end

local function get_speed(entity)
  return math.floor(entity.fluidbox[2].temperature)
end

-- -----------------------------------------------------------------------------
-- GUI

local function to_slider_value(speed)
  local index
  if speed == 0 then
    index = 0
  elseif speed < 1000 then
    index = math.floor(speed / 100) * 100
  elseif speed < 10000 then
    index = math.floor(speed / 1000) * 1000
  elseif speed < 30000 then
    index = math.floor(speed / 5000) * 5000
  else
    index = 30000
  end
  return constants.sp_temperature_to_slider[index]
end

local function from_slider_value(value)
  return constants.sp_slider_to_temperature[value]
end

local function update_gui(gui_data)
  local entity = gui_data.state.entity
  local refs = gui_data.refs

  local speed = get_speed(entity)

  refs.preview.entity = entity
  refs.state_switch.switch_state = entity.active and "left" or "right"
  refs.speed_slider.slider_value = to_slider_value(speed)
  refs.speed_textfield.text = tostring(speed)
end

local function close_gui(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.sp

  gui_data.refs.window.destroy()
  player_table.gui.sp = nil

  if not player_table.flags.opening_default_gui then
    if player.opened == gui_data.state.entity then
      player.opened = nil
    end
    player.play_sound{path = "entity-close/ee-super-pump"}
  end
end

local function open_default_gui(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  player_table.flags.opening_default_gui = true
  player.opened = player_table.gui.sp.state.entity
  player_table.flags.opening_default_gui = false
end

local function update_speed_from_slider(e)
  local value = e.element.slider_value
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.sp
  set_speed(gui_data.state.entity, from_slider_value(value))
  update_gui(gui_data)
end

local function confirm_textfield(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.sp
  local state = gui_data.state
  local refs = gui_data.refs

  refs.speed_textfield.text = tostring(state.speed)
  refs.speed_textfield.style = "ee_slider_textfield"
end

local function update_speed_from_textfield(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.sp
  local state = gui_data.state
  local refs = gui_data.refs

  local lowest = 0
  local highest = 600000

  local new_value = tonumber(e.element.text) or -1
  local out_of_bounds = new_value < lowest or new_value > highest

  if out_of_bounds then
    refs.speed_textfield.style = "ee_invalid_slider_textfield"
  else
    refs.speed_textfield.style = "ee_slider_textfield"

    local clamped_value = math.clamp(new_value, lowest, highest)
    state.speed = clamped_value
    refs.speed_slider.slider_value = clamped_value

    set_speed(state.entity, tonumber(clamped_value))
  end
end

local function update_active(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.sp
  gui_data.state.entity.active = e.element.switch_state == "left"
end

gui.add_handlers{
  sp_close = close_gui,
  sp_open_default_gui = open_default_gui,
  sp_update_speed_from_slider = update_speed_from_slider,
  sp_confirm_textfield = confirm_textfield,
  sp_update_speed_from_textfield = update_speed_from_textfield,
  sp_update_active = update_active
}

local function create_gui(player, player_table, entity)
  local refs = gui.build(player.gui.screen, {
    {type = "frame", direction = "vertical", handlers = {on_closed = "sp_close"}, ref = {"window"}, children = {
      {type = "flow", ref = {"titlebar_flow"}, children = {
        {type = "label", style = "frame_title", caption = {"entity-name.ee-super-pump"}, ignored_by_interaction = true},
        {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
        {
          type = "sprite-button",
          style = "frame_action_button",
          sprite = "utility/logistic_network_panel_white",
          hovered_sprite = "utility/logistic_network_panel_black",
          clicked_sprite = "utility/logistic_network_panel_black",
          tooltip = {"ee-gui.open-default-gui"},
          handlers = {on_click = "sp_open_default_gui"}
        },
        util.close_button{on_click = "sp_close"}
      }},
      {type = "frame", style = "entity_frame", direction = "vertical", children = {
        {type = "frame", style = "deep_frame_in_shallow_frame", children = {
          {type = "entity-preview", style = "wide_entity_button", elem_mods = {entity = entity}, ref = {"preview"}}
        }},
        {type = "flow", style_mods = {vertical_align = "center"}, children = {
          {type = "label", caption = {"ee-gui.state"}},
          {type = "empty-widget", style = "flib_horizontal_pusher"},
          {
            type = "switch",
            left_label_caption = {"gui-constant.on"},
            right_label_caption = {"gui-constant.off"},
            switch_state = "left",
            handlers = {on_switch_state_changed = "sp_update_active"},
            ref = {"state_switch"}
          }
        }},
        {type = "line", style_mods = {horizontally_stretchable = true}, direction = "horizontal"},
        {type = "flow", style_mods = {vertical_align = "center"}, children = {
          {
            type = "label",
            style_mods = {right_margin = 6},
            caption = {"ee-gui.speed"},
            tooltip = {"ee-gui.speed-tooltip"}
          },
          {
            type = "slider",
            style_mods = {horizontally_stretchable = true},
            minimum_value = 0,
            maximum_value = 23,
            handlers = {on_value_changed = "sp_update_speed_from_slider"},
            ref = {"speed_slider"}
          },
          {
            type = "textfield",
            style = "ee_slider_textfield",
            style_mods = {width = 80},
            numeric = true,
            lose_focus_on_confirm = true,
            clear_and_focus_on_right_click = true,
            handlers = {
              on_confirmed = "sp_confirm_textfield",
              on_text_changed = "sp_update_speed_from_textfield"
            },
            ref = {"speed_textfield"}
          },
          {type = "label", style = "ee_super_pump_per_second_label", caption = {"ee-gui.per-second"}}
        }}
      }}
    }}
  })

  refs.titlebar_flow.drag_target = refs.window
  refs.window.force_auto_center()

  player_table.gui.sp = {
    state = {
      entity = entity,
      speed = get_speed(entity)
    },
    refs = refs
  }

  player.opened = refs.window

  player.play_sound{path = "entity-open/ee-super-pump"}

  update_gui(player_table.gui.sp)
end

-- -----------------------------------------------------------------------------
-- PUBLIC FUNCTIONS

function super_pump.setup(entity, tags)
  local speed = 1000
  if tags and tags.EditorExtensions then
    entity.active = tags.EditorExtensions.active
    speed = tags.EditorExtensions.speed
  end
  set_speed(entity, speed)
end

function super_pump.setup_blueprint(blueprint_entity, entity)
  if not blueprint_entity.tags then
    blueprint_entity.tags = {}
  end
  blueprint_entity.tags.EditorExtensions = {active = entity.active, speed = get_speed(entity)}
  return blueprint_entity
end

function super_pump.paste_settings(source, destination)
  set_speed(destination, get_speed(source))
end

function super_pump.open(player_index, entity)
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]
  if not player_table.flags.opening_default_gui then
    create_gui(player, player_table, entity)
  end
end

return super_pump