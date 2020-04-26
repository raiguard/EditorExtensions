local infinity_accumulator = {}

local gui = require("__flib__.control.gui")
local util = require("scripts.util")

local string_gsub = string.gsub
local string_sub = string.sub

-- -----------------------------------------------------------------------------
-- LOCAL UTILITIES

local constants = {
  localised_priorities = {{"ee-gui.primary"}, {"ee-gui.secondary"}},
  localised_modes = {{"ee-gui.output"}, {"ee-gui.input"}, {"ee-gui.buffer"}},
  mode_to_index = {output=1, input=2, buffer=3},
  priority_to_index = {primary=1, secondary=2, tertiary=1},
  index_to_mode = {"output", "input", "buffer"},
  index_to_priority = {"primary", "secondary"},
  power_prefixes = {"kilo","mega","giga","tera","peta","exa","zetta","yotta"},
  power_suffixes_by_mode = {output="watt", input="watt", buffer="joule"},
  localised_si_suffixes_watt = {},
  localised_si_suffixes_joule = {},
  si_suffixes_joule = {"kJ", "MJ", "GJ", "TJ", "PJ", "EJ", "ZJ", "YJ"},
  si_suffixes_watt = {"kW", "MW", "GW", "TW", "PW", "EW", "ZW", "YW"}
}
for i, v in pairs(constants.power_prefixes) do
  constants.localised_si_suffixes_watt[i] = {"", {"si-prefix-symbol-"..v}, {"si-unit-symbol-watt"}}
  constants.localised_si_suffixes_joule[i] = {"", {"si-prefix-symbol-"..v}, {"si-unit-symbol-joule"}}
end

local function get_settings_from_name(name)
  name = string_gsub(name, "(%a+)-(%a+)-(%a+)-", "")
  if name == "tertiary" then return "tertiary", "buffer" end
  local _,_,priority,mode = string.find(name, "(%a+)-(%a+)")
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
  gui_data.slider_dropdown.items = constants["localised_si_suffixes_"..constants.power_suffixes_by_mode[mode]]
end

local function update_gui_settings(gui_data)
  local entity = gui_data.entity
  local priority, mode = get_settings_from_name(entity.name)
  local slider_value, dropdown_index = rev_parse_energy(entity.electric_buffer_size)
  gui_data.mode_dropdown.selected_index = constants.mode_to_index[mode]
  gui_data.priority_dropdown.selected_index = constants.priority_to_index[priority]
  gui_data.slider.slider_value = slider_value
  gui_data.slider_textfield.text = slider_value
  gui_data.slider_textfield.style = "ee_slider_textfield"
  gui_data.slider_dropdown.selected_index = dropdown_index
  gui_data.last_textfield_value = slider_value
  gui.update_mode(gui_data, mode)
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
        local mode = constants.index_to_mode[e.element.selected_index]
        if mode == "buffer" then
          gui_data.entity = change_entity(gui_data.entity, "tertiary")
        else
          local priority = constants.index_to_priority[gui_data.priority_dropdown.selected_index]
          gui_data.entity = change_entity(gui_data.entity, priority, mode)
        end
        update_gui_mode(gui_data, mode)
      end
    },
    priority_dropdown = {
      on_gui_selection_state_changed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.ia
        local mode = constants.index_to_mode[gui_data.mode_dropdown.selected_index]
        local priority = constants.index_to_priority[e.element.selected_index]
        gui_data.entity = change_entity(gui_data.entity, priority, mode)
      end
    },
    slider = {
      on_gui_value_changed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.ia
        local buffer_size = util.parse_energy(e.element.slider_value..constants.si_suffixes_joule[gui_data.slider_dropdown.selected_index])
        set_entity_settings(gui_data.entity, constants.index_to_mode[gui_data.mode_dropdown.selected_index], buffer_size)
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
        local buffer_size = util.parse_energy(e.element.text..constants.si_suffixes_joule[gui_data.slider_dropdown.selected_index])
        set_entity_settings(gui_data.entity, constants.index_to_mode[gui_data.mode_dropdown.selected_index], buffer_size)
      end
    },
    slider_dropdown = {
      on_gui_selection_state_changed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.ia
        local buffer_size = util.parse_energy(gui_data.slider.slider_value..constants.si_suffixes_joule[e.element.selected_index])
        set_entity_settings(gui_data.entity, constants.index_to_mode[gui_data.mode_dropdown.selected_index], buffer_size)
      end
    },
    window = {
      on_gui_closed = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.ia
        gui.remove_filters(e.player_index, gui_data.filters)
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
  local gui_data, filters = gui.build(player.gui.screen, {
    {type="frame", style="dialog_frame", direction="vertical", handlers="ia.window", save_as="window", children={
      {type="flow", children={
        {type="label", style="frame_title", caption={"entity-name.ee-infinity-accumulator"}},
        {template="titlebar_drag_handle"},
        {template="close_button", handlers="ia.close_button"}
      }},
      {type="flow", style="ee_entity_window_content_flow", children={
        gui.templates.entity_camera(entity, 112, 1, {0,-0.5}, player.display_scale),
        {type="frame", style="ee_ia_page_frame", direction="vertical", children={
          {template="vertically_centered_flow", children={
            {type="label", caption={"ee-gui.mode"}},
            {template="pushers.horizontal"},
            {type="drop-down", items=constants.localised_modes, selected_index=constants.mode_to_index[mode], handlers="ia.mode_dropdown",
              save_as="mode_dropdown"}
          }},
          {template="pushers.vertical"},
          {template="vertically_centered_flow", children={
            {type="label", caption={"", {"ee-gui.priority"}, " [img=info]"}, tooltip={"ee-gui.ia-priority-description"}},
            {template="pushers.horizontal"},
            {type="drop-down", items=constants.localised_priorities, selected_index=constants.priority_to_index[priority], mods={visible=not is_buffer},
              handlers="ia.priority_dropdown", save_as="priority_dropdown"},
            {type="button", style="ee_disabled_dropdown_button", caption={"ee-gui.tertiary"}, mods={enabled=false, visible=is_buffer},
              save_as="priority_dropdown_dummy"}
          }},
          {template="pushers.vertical"},
          {template="vertically_centered_flow", children={
            {type="slider", minimum_value=0, maximum_value=999, value=slider_value, handlers="ia.slider", save_as="slider"},
            {type="textfield", style="ee_slider_textfield", text=slider_value, numeric=true, lose_focus_on_confirm=true, clear_and_focus_on_right_click=true,
              handlers="ia.slider_textfield", save_as="slider_textfield"},
            {type="drop-down", style_mods={width=63}, selected_index=dropdown_index,
              items=constants["localised_si_suffixes_"..constants.power_suffixes_by_mode[mode]], handlers="ia.slider_dropdown", save_as="slider_dropdown"}
          }}
        }}
      }}
    }}
  })

  gui_data.window.force_auto_center()
  gui_data.drag_handle.drag_target = gui_data.window

  player.opened = gui_data.window

  gui_data.filters = filters
  gui_data.entity = entity
  gui_data.last_textfield_value = gui_data.slider_textfield.text

  player_table.gui.ia = gui_data
end

-- -----------------------------------------------------------------------------
-- FUNCTIONS

function infinity_accumulator.check_name(entity)
  return string_sub(entity.name, 1, 23) == "ee-infinity-accumulator"
end

function infinity_accumulator.open(player_index, entity)
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]
  create_gui(player, player_table, entity)
end

function infinity_accumulator.on_entity_settings_pasted(e)
  if infinity_accumulator.check_name(e.source) and infinity_accumulator.check_name(e.destination) and e.source.name ~= e.destination.name then
    -- get players viewing the destination accumulator
    local to_update = {}
    if global.__lualib.event.ia_close_button_clicked then
      for _, i in ipairs(global.__lualib.event.ia_close_button_clicked.players) do
        local player_table = global.players[i]
        -- check if they're viewing this one
        if player_table.gui.ia.entity == e.destination then
          table.insert(to_update, i)
        end
      end
    end
    -- update entity
    local priority, mode = get_settings_from_name(e.source.name)
    local new_entity
    if mode == "buffer" then
      new_entity = change_entity(e.destination, "tertiary")
    else
      new_entity = change_entity(e.destination, priority, mode)
    end
    -- update open GUIs
    for _, i in pairs(to_update) do
      local player_table = global.players[i]
      player_table.gui.ia.entity = new_entity
      update_gui_settings(player_table.gui.ia)
    end
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