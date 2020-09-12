local infinity_accumulator = {}

local gui = require("__flib__.gui")
local util = require("scripts.util")

local constants = require("scripts.constants")

-- -----------------------------------------------------------------------------
-- LOCAL UTILITIES

local function get_settings_from_name(name)
  name = string.gsub(name, "(%a+)-(%a+)-(%a+)-", "")
  if name == "tertiary" then return "tertiary", "buffer" end
  local _, _, priority, mode = string.find(name, "(%a+)-(%a+)")
  return priority, mode
end

local function set_entity_settings(entity, mode, buffer_size)
  -- reset everything
  entity.power_production = 0
  entity.power_usage = 0
  entity.electric_buffer_size = buffer_size
  local watts = util.parse_energy(buffer_size.."W")
  if mode == "output" then
    entity.power_production = watts
    entity.energy = buffer_size
  elseif mode == "input" then
    entity.power_usage = watts
  end
end

local function change_entity(entity, priority, mode)
  priority = "-"..priority
  local n_mode = mode and "-"..mode or ""
  local new_name = "ee-infinity-accumulator"..priority..n_mode
  local new_entity = entity.surface.create_entity{
    name = new_name,
    position = entity.position,
    force = entity.force,
    last_user = entity.last_user,
    create_build_effect_smoke = false
  }
  set_entity_settings(new_entity, mode or "buffer", entity.electric_buffer_size)
  entity.destroy()
  return new_entity
end

-- returns the slider value and dropdown selected index based on the entity's buffer size
local function rev_parse_energy(value)
  local len = string.len(string.format("%.0f", math.floor(value)))
  local exponent = math.max(len - (len % 3 == 0 and 3 or len % 3),3)
  value = math.floor(value / 10^exponent)
  return value, exponent / 3
end

-- -----------------------------------------------------------------------------
-- GUI

local function update_gui_mode(gui_data, mode)
  if mode == "buffer" then
    gui_data.priority_dropdown.visible = false
    gui_data.priority_dropdown_dummy.visible = true
  else
    gui_data.priority_dropdown.visible = true
    gui_data.priority_dropdown_dummy.visible = false
  end
  gui_data.slider_dropdown.items = constants.ia["localised_si_suffixes_"..constants.ia.power_suffixes_by_mode[mode]]

  gui_data.preview.entity = gui_data.entity
end

local function update_gui_settings(gui_data)
  local entity = gui_data.entity
  local priority, mode = get_settings_from_name(entity.name)
  local slider_value, dropdown_index = rev_parse_energy(entity.electric_buffer_size)
  gui_data.mode_dropdown.selected_index = constants.ia.mode_to_index[mode]
  gui_data.priority_dropdown.selected_index = constants.ia.priority_to_index[priority]
  gui_data.slider.slider_value = slider_value
  gui_data.slider_textfield.text = slider_value
  gui_data.slider_textfield.style = "ee_slider_textfield"
  gui_data.slider_dropdown.selected_index = dropdown_index
  gui_data.last_textfield_value = slider_value
  update_gui_mode(gui_data, mode)
end

gui.add_handlers{
  ia = {
    close_button = {
      on_gui_click = function(e)
        gui.handlers.ia.window.on_gui_closed(e)
      end
    },
    mode_dropdown = {
      on_gui_selection_state_changed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.ia
        local mode = constants.ia.index_to_mode[e.element.selected_index]
        if mode == "buffer" then
          gui_data.entity = change_entity(gui_data.entity, "tertiary")
        else
          local priority = constants.ia.index_to_priority[gui_data.priority_dropdown.selected_index]
          gui_data.entity = change_entity(gui_data.entity, priority, mode)
        end
        update_gui_mode(gui_data, mode)
      end
    },
    priority_dropdown = {
      on_gui_selection_state_changed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.ia
        local mode = constants.ia.index_to_mode[gui_data.mode_dropdown.selected_index]
        local priority = constants.ia.index_to_priority[e.element.selected_index]
        gui_data.entity = change_entity(gui_data.entity, priority, mode)
        gui_data.preview.entity = gui_data.entity
      end
    },
    slider = {
      on_gui_value_changed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.ia
        local buffer_size = util.parse_energy(
          e.element.slider_value..constants.ia.si_suffixes_joule[gui_data.slider_dropdown.selected_index]
        )
        set_entity_settings(
          gui_data.entity,
          constants.ia.index_to_mode[gui_data.mode_dropdown.selected_index],
          buffer_size
        )
        gui_data.slider_textfield.text = e.element.slider_value
      end
    },
    slider_textfield = {
      on_gui_text_changed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.ia
        local new_value = util.textfield.clamp_number_input(e.element, {0,999}, gui_data.last_textfield_value)
        if new_value ~= gui_data.last_textfield_value then
          gui_data.last_textfield_value = new_value
          gui_data.slider.slider_value = new_value
        end
      end,
      on_gui_confirmed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.ia
        util.textfield.set_last_valid_value(e.element, player_table.gui.ia.last_textfield_value)
        local buffer_size = util.parse_energy(
          e.element.text..constants.ia.si_suffixes_joule[gui_data.slider_dropdown.selected_index]
        )
        set_entity_settings(
          gui_data.entity,
          constants.ia.index_to_mode[gui_data.mode_dropdown.selected_index],
          buffer_size
        )
      end
    },
    slider_dropdown = {
      on_gui_selection_state_changed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.ia
        local buffer_size = util.parse_energy(
          gui_data.slider.slider_value..constants.ia.si_suffixes_joule[e.element.selected_index]
        )
        set_entity_settings(
          gui_data.entity,
          constants.ia.index_to_mode[gui_data.mode_dropdown.selected_index],
          buffer_size
        )
      end
    },
    window = {
      on_gui_closed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.ia
        gui.update_filters("ia", e.player_index, nil, "remove")
        gui_data.window.destroy()
        player_table.gui.ia = nil
      end
    }
  }
}

-- TODO: when changing settings, update GUI for everyone to avoid crashes

local function create_gui(player, player_table, entity)
  local priority, mode = get_settings_from_name(entity.name)
  local is_buffer = mode == "buffer"
  local slider_value, dropdown_index = rev_parse_energy(entity.electric_buffer_size)
  local gui_data = gui.build(player.gui.screen, {
    {type="frame", direction="vertical", handlers="ia.window", save_as="window", children={
      {type="flow", save_as="titlebar_flow", children={
        {type="label",
          style="frame_title",
          caption={"entity-name.ee-infinity-accumulator"},
          elem_mods={ignored_by_interaction=true}
        },
        {template="titlebar_drag_handle"},
        {template="close_button", handlers="ia.close_button"}
      }},
      {type="frame", style="ee_inside_shallow_frame_for_entity", children={
        {type="frame", style="deep_frame_in_shallow_frame", children={
          {type="entity-preview", style_mods={width=100, height=100}, elem_mods={entity=entity}, save_as="preview"}
        }},
        {type="flow", direction="vertical", children={
          {template="vertically_centered_flow", children={
            {type="label", caption={"ee-gui.mode"}},
            {template="pushers.horizontal"},
            {type="drop-down",
              style="ee_ia_dropdown",
              items=constants.ia.localised_modes,
              selected_index=constants.ia.mode_to_index[mode],
              handlers="ia.mode_dropdown",
              save_as="mode_dropdown"
            }
          }},
          {template="pushers.vertical"},
          {template="vertically_centered_flow", children={
            {type="label",
              caption={"", {"ee-gui.priority"}, " [img=info]"},
              tooltip={"ee-gui.ia-priority-description"}
            },
            {template="pushers.horizontal"},
            {type="drop-down",
              style="ee_ia_dropdown",
              items=constants.ia.localised_priorities,
              selected_index=constants.ia.priority_to_index[priority],
              elem_mods={visible=(not is_buffer)},
              handlers="ia.priority_dropdown",
              save_as="priority_dropdown"
            },
            {type="button",
              style="ee_disabled_dropdown_button",
              caption={"ee-gui.tertiary"},
              elem_mods={enabled=false, visible=is_buffer},
              save_as="priority_dropdown_dummy"
            }
          }},
          {template="pushers.vertical"},
          {template="vertically_centered_flow", children={
            {type="slider",
              minimum_value=0,
              maximum_value=999,
              value=slider_value,
              handlers="ia.slider",
              save_as="slider"
            },
            {type="textfield",
              style="ee_slider_textfield",
              text=slider_value,
              numeric=true,
              lose_focus_on_confirm=true,
              clear_and_focus_on_right_click=true,
              handlers="ia.slider_textfield",
              save_as="slider_textfield"
            },
            {type="drop-down",
              style_mods={width=69},
              selected_index=dropdown_index,
              items=constants.ia["localised_si_suffixes_"..constants.ia.power_suffixes_by_mode[mode]],
              handlers="ia.slider_dropdown",
              save_as="slider_dropdown"
            }
          }}
        }}
      }}
    }}
  })

  gui_data.window.force_auto_center()
  gui_data.titlebar_flow.drag_target = gui_data.window

  player.opened = gui_data.window

  gui_data.entity = entity
  gui_data.last_textfield_value = gui_data.slider_textfield.text

  player_table.gui.ia = gui_data
end

-- -----------------------------------------------------------------------------
-- FUNCTIONS

function infinity_accumulator.open(player_index, entity)
  -- TODO play sound after opening GUI
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]
  create_gui(player, player_table, entity)
end

function infinity_accumulator.paste_settings(source, destination)
  -- get players viewing the destination accumulator
  local to_update = {}
  for i, player_table in pairs(global.players) do
    if player_table.gui.ia and player_table.gui.ia.entity == destination then
      to_update[#to_update+1] = i
    end
  end
  -- update entity
  local priority, mode = get_settings_from_name(source.name)
  local new_entity
  if mode == "buffer" then
    new_entity = change_entity(destination, "tertiary")
  else
    new_entity = change_entity(destination, priority, mode)
  end
  -- update open GUIs
  for _, i in ipairs(to_update) do
    local player_table = global.players[i]
    player_table.gui.ia.entity = new_entity
    update_gui_settings(player_table.gui.ia)
  end
end

function infinity_accumulator.close_open_guis(entity)
  for i, t in pairs(global.players) do
    if t.gui.ia and t.gui.ia.entity == entity then
      gui.handlers.ia.window.on_gui_closed{player_index=i}
    end
  end
end

return infinity_accumulator