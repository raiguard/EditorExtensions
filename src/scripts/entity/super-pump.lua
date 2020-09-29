local super_pump = {}

local gui = require("__flib__.gui")

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
  local entity = gui_data.entity
  local gui_elems = gui_data.elems

  local speed = get_speed(entity)

  gui_elems.preview.entity = entity
  gui_elems.speed_slider.slider_value = to_slider_value(speed)
  gui_elems.speed_textfield.text = tostring(speed)
end

local function create_gui(player, player_table, entity)
  local elems = gui.build(player.gui.screen, {
    {type = "frame", direction = "vertical", handlers = "sp.window", save_as = "window", children = {
      {type = "flow", save_as = "titlebar_flow", children = {
        {type = "label", style = "frame_title", caption = {"entity-name.ee-super-pump"}, ignored_by_interaction = true},
        {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
        {
          type = "sprite-button",
          style = "frame_action_button",
          sprite = "utility/logistic_network_panel_white",
          hovered_sprite = "utility/logistic_network_panel_black",
          clicked_sprite = "utility/logistic_network_panel_black",
          tooltip = {"ee-gui.open-default-gui"},
          handlers = "sp.open_default_gui_button"
        },
        {template = "close_button", handlers = "sp.close_button"}
      }},
      {type = "frame", style = "ee_inside_shallow_frame_for_entity", children = {
        {type = "frame", style = "deep_frame_in_shallow_frame", children = {
          {
            type = "entity-preview",
            style_mods = {width = 100, height = 100},
            elem_mods = {entity = entity},
            save_as = "preview"
          }
        }},
        {type = "flow", direction = "vertical", children = {
          {template = "vertically_centered_flow", children = {
            {
              type = "label",
              style_mods = {right_margin = 12},
              caption = {"ee-gui.speed"},
              tooltip = {"ee-gui.speed-tooltip"}
            },
            {
              type = "slider",
              minimum_value = 0,
              maximum_value = 23,
              handlers = "sp.speed_slider",
              save_as = "speed_slider"
            },
            {
              type = "textfield",
              style = "ee_slider_textfield",
              style_mods = {width = 80},
              numeric = true,
              lose_focus_on_confirm = true,
              clear_and_focus_on_right_click = true,
              handlers = "sp.speed_textfield",
              save_as = "speed_textfield"
            },
            {type = "label", style = "ee_super_pump_per_second_label", caption = {"ee-gui.per-second"}}
          }}
        }}
      }}
    }}
  })

  elems.titlebar_flow.drag_target = elems.window
  elems.window.force_auto_center()

  player_table.gui.sp = {
    entity = entity,
    elems = elems,
    last_textfield_value = tostring(get_speed(entity))
  }

  player.opened = elems.window

  player.play_sound{path = "entity-open/ee-super-pump"}

  update_gui(player_table.gui.sp)
end

local function destroy_gui(player, player_table)
  local gui_data = player_table.gui.sp
  gui_data.elems.window.destroy()
  player_table.gui.sp = nil

  if not player_table.flags.opening_default_gui then
    if player.opened == gui_data.entity then
      player.opened = nil
    end
    player.play_sound{path = "entity-close/ee-super-pump"}
  end
end

gui.add_handlers{
  sp = {
    close_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        destroy_gui(player, player_table)
      end
    },
    open_default_gui_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        player_table.flags.opening_default_gui = true
        player.opened = player_table.gui.sp.entity
        player_table.flags.opening_default_gui = false
      end
    },
    speed_slider = {
      on_gui_value_changed = function(e)
        local value = e.element.slider_value
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.sp
        set_speed(gui_data.entity, from_slider_value(value))
        update_gui(gui_data)
      end
    },
    speed_textfield = {
      on_gui_confirmed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.sp
        local last_value = gui_data.last_textfield_value
        util.textfield.set_last_valid_value(e.element, last_value)
        set_speed(gui_data.entity, tonumber(last_value))
        gui_data.elems.speed_slider.slider_value = to_slider_value(tonumber(last_value))
      end,
      on_gui_text_changed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.sp
        local new_value = util.textfield.clamp_number_input(e.element, {0, 600000}, gui_data.last_textfield_value)
        if new_value ~= gui_data.last_textfield_value then
          gui_data.last_textfield_value = new_value
          gui_data.elems.speed_slider.slider_value = to_slider_value(tonumber(new_value))
        end
      end
    },
    window = {
      on_gui_closed = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        destroy_gui(player, player_table)
      end
    }
  }
}

-- -----------------------------------------------------------------------------
-- PUBLIC FUNCTIONS

function super_pump.setup(entity, tags)
  local speed = 1000
  if tags and tags.EditorExtensions then
    speed = tags.EditorExtensions.speed
  end
  set_speed(entity, speed)
end

function super_pump.save_speed(blueprint_entity, entity)
  if not blueprint_entity.tags then
    blueprint_entity.tags = {}
  end
  blueprint_entity.tags.EditorExtensions = {speed = get_speed(entity)}
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