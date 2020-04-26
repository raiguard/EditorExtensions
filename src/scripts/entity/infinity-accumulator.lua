local infinity_accumulator = {}

local gui = require("__flib__.control.gui")
local util = require("scripts.util")

local string_gsub = string.gsub
local string_sub = string.sub

local ia_gui = {}

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

local function check_is_accumulator(entity)
  return string_sub(entity.name, 1, 23) == "ee-infinity-accumulator"
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

gui.add_templates{
  titlebar_drag_handle = {type="empty-widget", style="draggable_space_header", style_mods={right_margin=5, height=24, horizontally_stretchable=true},
    save_as="drag_handle"},
  close_button = {type="sprite-button", style="close_button", style_mods={top_margin=2, width=20, height=20}, sprite="utility/close_white",
    hovered_sprite="utility/close_black", clicked_sprite="utility/close_black"},
  entity_camera = function(entity, size, zoom, camera_offset, player_display_scale)
    return
      {type="frame", style="inside_deep_frame", children={
        {type="camera", style_mods={width=size, height=size}, position=util.position.add(entity.position, camera_offset), zoom=(zoom * player_display_scale)}
      }}
  end,
  vertically_centered_flow = {type="flow", style_mods={vertical_align="center"}},
  pushers = {
    horizontal = {type="empty-widget", style_mods={horizontally_stretchable=true}},
    vertical = {type="empty-widget", style_mods={vertically_stretchable=true}}
  }
}

function ia_gui.create(player, player_table, entity)
  local priority, mode = get_settings_from_name(entity.name)
  local is_buffer = mode == "buffer"
  local slider_value, dropdown_index = rev_parse_energy(entity.electric_buffer_size)
  local elems, filters = gui.build(player.gui.screen, {
    {type="frame", style="dialog_frame", direction="vertical", save_as="window", children={
      {type="flow", children={
        {type="label", style="frame_title", caption={"entity-name.ee-infinity-accumulator"}},
        {template="titlebar_drag_handle"},
        {template="close_button"}
      }},
      {type="flow", style="ee_entity_window_content_flow", children={
        gui.templates.entity_camera(entity, 110, 1, {0,-0.5}, player.display_scale),
        {type="frame", style="ee_ia_page_frame", direction="vertical", children={
          {template="vertically_centered_flow", children={
            {type="label", caption={"", {"ee-gui.mode"}, " [img=info]"}, tooltip={"ee-gui.ia-mode-description"}},
            {template="pushers.horizontal"},
            {type="drop-down", items=constants.localised_modes, selected_index=constants.priority_to_index[priority]}
          }},
          {template="pushers.vertical"},
          {template="vertically_centered_flow", children={
            {type="label", caption={"", {"ee-gui.priority"}, " [img=info]"}, tooltip={"ee-gui.ia-priority-description"}},
            {template="pushers.horizontal"},
            {type="drop-down", items=constants.localised_priorities, selected_index=constants.mode_to_index[mode], mods={visible=not is_buffer},
              save_as="mode_dropdown"},
            {type="button", style="ee_disabled_dropdown_button", caption={"ee-gui.buffer"}, mods={enabled=false, visible=is_buffer},
              save_as="mode_dropdown_dummy"}
          }},
          {template="pushers.vertical"},
          {template="vertically_centered_flow", children={
            {type="slider", minimum_value=0, maximum_value=999, value=slider_value, save_as="slider"},
            {type="textfield", style="ee_slider_textfield", text=slider_value, numeric=true, lose_focus_on_confirm=true, clear_and_focus_on_right_click=true,
              save_as="slider_textfield"},
            {type="drop-down", style_mods={width=63}, selected_index=dropdown_index,
              items=constants["localised_si_suffixes_"..constants.power_suffixes_by_mode[mode]], save_as="slider_dropdown"}
          }}
        }}
      }}
    }}
  })

  elems.window.force_auto_center()
  elems.drag_handle.drag_target = elems.window

  player.opened = elems.window

  elems.filters = filters

  player_table.gui.ia = elems
end

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

function infinity_accumulator.on_gui_opened(e)
  if e.entity and check_is_accumulator(e.entity) then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    ia_gui.create(player, player_table, e.entity)
    -- create GUI
    -- local elems, last_textfield_value = gui.create(player.gui.screen, e.entity, player)
    -- player.opened = elems.window
    -- player_table.gui.ia = {elems=elems, last_textfield_value=last_textfield_value, entity=e.entity}
  end
end

-- function infinity_accumulator.on_gui_closed(e)
--   if e.gui_type == 16 and e.element and e.element.name == "ee_ia_window" then
--     gui.destroy(e.element, e.player_index)
--   end
-- end

function infinity_accumulator.on_entity_settings_pasted(e)
  if check_is_accumulator(e.source) and check_is_accumulator(e.destination) and e.source.name ~= e.destination.name then
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
      -- gui.update_settings(player_table.gui.ia)
    end
  end
end

function infinity_accumulator.on_destroyed(e)
  if check_is_accumulator(e.entity) then
    -- close open GUIs
    -- if global.__lualib.event.ia_close_button_clicked then
    --   for _, i in ipairs(global.__lualib.event.ia_close_button_clicked.players) do
    --     local player_table = global.players[i]
    --     -- check if they're viewing this one
    --     if player_table.gui.ia.entity == e.entity then
    --       -- gui.destroy(player_table.gui.ia.elems.window, e.player_index)
    --       player_table.gui.ia = nil
    --     end
    --   end
    -- end
  end
end

return infinity_accumulator