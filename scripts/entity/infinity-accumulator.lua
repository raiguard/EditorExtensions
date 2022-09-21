local infinity_accumulator = {}

local gui = require("__flib__.gui")
local math = require("__flib__.math")
local util = require("scripts.util")

local constants = require("scripts.constants")

-- -----------------------------------------------------------------------------
-- LOCAL UTILITIES

--- @param name string
local function get_settings_from_name(name)
  local _, _, priority, mode = string.find(name, "^ee%-infinity%-accumulator%-(%a+)%-(%a+)$")
  return priority, mode
end

--- @param entity LuaEntity
--- @param mode string
--- @param buffer_size double?
local function set_entity_settings(entity, mode, buffer_size)
  local watts = util.parse_energy((buffer_size * 60) .. "W")

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

--- @param entity LuaEntity
--- @param priority string
--- @param mode string
--- @return LuaEntity?
local function change_entity(entity, priority, mode)
  local new_entity = entity.surface.create_entity({
    name = "ee-infinity-accumulator-" .. priority .. "-" .. mode,
    position = entity.position,
    force = entity.force,
    last_user = entity.last_user,
    create_build_effect_smoke = false,
  })
  if not new_entity then
    return
  end

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
  return math.floored(buffer_size / 10 ^ (power * 3), 0.001), math.max(power, 1)
end

-- returns the entity buffer size based on the slider value and dropdown selected index
local function calc_buffer_size(slider_value, dropdown_index)
  return util.parse_energy(slider_value .. constants.ia.si_suffixes_joule[dropdown_index]) / 60
end

-- -----------------------------------------------------------------------------
-- GUI

-- TODO: when changing settings, update GUI for everyone to avoid crashes

--- @param player LuaPlayer
--- @param player_table PlayerTable
--- @param entity LuaEntity
local function create_gui(player, player_table, entity)
  local priority, mode = get_settings_from_name(entity.name)
  local slider_value, dropdown_index = calc_gui_values(entity.electric_buffer_size, mode)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      actions = { on_closed = { gui = "ia", action = "close" } },
      ref = { "window" },
      children = {
        {
          type = "flow",
          style = "flib_titlebar_flow",
          ref = { "titlebar_flow" },
          children = {
            {
              type = "label",
              style = "frame_title",
              caption = { "entity-name.ee-infinity-accumulator" },
              ignored_by_interaction = true,
            },
            { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
            util.close_button({ on_click = { gui = "ia", action = "close" } }),
          },
        },
        {
          type = "frame",
          style = "entity_frame",
          direction = "vertical",
          children = {
            {
              type = "frame",
              style = "deep_frame_in_shallow_frame",
              children = {
                {
                  type = "entity-preview",
                  style = "wide_entity_button",
                  elem_mods = { entity = entity },
                  ref = { "preview" },
                },
              },
            },
            {
              type = "flow",
              style_mods = { top_margin = 4, vertical_align = "center" },
              children = {
                { type = "label", caption = { "ee-gui.mode" } },
                { type = "empty-widget", style = "flib_horizontal_pusher" },
                {
                  type = "drop-down",
                  items = constants.ia.localised_modes,
                  selected_index = constants.ia.mode_to_index[mode],
                  actions = { on_selection_state_changed = { gui = "ia", action = "update_mode" } },
                  ref = { "mode_dropdown" },
                },
              },
            },
            { type = "line", direction = "horizontal" },
            {
              type = "flow",
              style_mods = { vertical_align = "center" },
              children = {
                {
                  type = "label",
                  caption = { "", { "ee-gui.priority" }, " [img=info]" },
                  tooltip = { "ee-gui.ia-priority-description" },
                },
                { type = "empty-widget", style = "flib_horizontal_pusher" },
                {
                  type = "drop-down",
                  items = constants.ia.localised_priorities,
                  selected_index = constants.ia.priority_to_index[priority],
                  elem_mods = { enabled = mode ~= "buffer" },
                  actions = { on_selection_state_changed = { gui = "ia", action = "update_priority" } },
                  ref = { "priority_dropdown" },
                },
              },
            },
            { type = "line", direction = "horizontal" },
            {
              type = "flow",
              style_mods = { vertical_align = "center" },
              children = {
                {
                  type = "label",
                  style_mods = { right_margin = 6 },
                  caption = { "ee-gui.power" },
                },
                {
                  type = "slider",
                  style_mods = { horizontally_stretchable = true },
                  minimum_value = 0,
                  maximum_value = 999,
                  value = slider_value,
                  actions = { on_value_changed = { gui = "ia", action = "update_power_from_slider" } },
                  ref = { "slider" },
                },
                {
                  type = "textfield",
                  style = "ee_slider_textfield",
                  text = slider_value,
                  numeric = true,
                  allow_decimal = true,
                  lose_focus_on_confirm = true,
                  clear_and_focus_on_right_click = true,
                  actions = {
                    on_confirmed = { gui = "ia", action = "confirm_textfield" },
                    on_text_changed = { gui = "ia", action = "update_power_from_textfield" },
                  },
                  ref = { "slider_textfield" },
                },
                {
                  type = "drop-down",
                  style_mods = { width = 69 },
                  selected_index = dropdown_index,
                  items = constants.ia["localised_si_suffixes_" .. constants.ia.power_suffixes_by_mode[mode]],
                  actions = { on_selection_state_changed = { gui = "ia", action = "update_units_of_measure" } },
                  ref = { "slider_dropdown" },
                },
              },
            },
          },
        },
      },
    },
  })

  refs.window.force_auto_center()
  refs.titlebar_flow.drag_target = refs.window

  player.opened = refs.window

  --- @class InfinityAccumulatorGuiData
  player_table.gui.ia = {
    state = {
      entity = entity,
      power = tonumber(refs.slider_textfield.text),
    },
    refs = refs,
  }
end

--- @param player LuaPlayer
--- @param player_table PlayerTable
local function destroy_gui(player, player_table)
  player_table.gui.ia.refs.window.destroy()
  player_table.gui.ia = nil
  player.play_sound({ path = "entity-close/ee-infinity-accumulator-tertiary-buffer" })
end

--- @param gui_data InfinityAccumulatorGuiData
--- @param mode string
local function update_gui_mode(gui_data, mode)
  local refs = gui_data.refs
  if mode == "buffer" then
    gui_data.state.priority = "tertiary"
    refs.priority_dropdown.selected_index = constants.ia.priority_to_index["tertiary"]
    refs.priority_dropdown.enabled = false
  else
    refs.priority_dropdown.enabled = true
  end
  refs.slider_dropdown.items = constants.ia["localised_si_suffixes_" .. constants.ia.power_suffixes_by_mode[mode]]

  refs.preview.entity = gui_data.state.entity
end

--- @param gui_data InfinityAccumulatorGuiData
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

local function handle_gui_action(e, msg)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.ia
  -- See https://todo.sr.ht/~raiguard/factorio-mods/34
  if not gui_data then
    -- We foolishly did not name the window, so walk backwards until we find it
    local elem = e.element
    local parent = e.element.parent
    while parent.name ~= "screen" do
      elem = parent
      parent = elem.parent
    end
    elem.destroy()
    return
  end
  local state = gui_data.state
  local refs = gui_data.refs

  if msg.action == "close" then
    destroy_gui(player, player_table)
  elseif msg.action == "update_mode" then
    local mode = constants.ia.index_to_mode[e.element.selected_index]
    if mode == "buffer" then
      state.entity = change_entity(state.entity, "tertiary", "buffer")
    else
      local priority = constants.ia.index_to_priority[refs.priority_dropdown.selected_index]
      state.entity = change_entity(state.entity, priority, mode)
    end
    update_gui_mode(gui_data, mode)
  elseif msg.action == "update_priority" then
    local mode = constants.ia.index_to_mode[refs.mode_dropdown.selected_index]
    local priority = constants.ia.index_to_priority[e.element.selected_index]
    state.entity = change_entity(state.entity, priority, mode)
    refs.preview.entity = state.entity
  elseif msg.action == "update_power_from_slider" then
    set_entity_settings(
      state.entity,
      constants.ia.index_to_mode[refs.mode_dropdown.selected_index],
      calc_buffer_size(e.element.slider_value, refs.slider_dropdown.selected_index)
    )
    refs.slider_textfield.text = tostring(e.element.slider_value)
  elseif msg.action == "update_power_from_textfield" then
    local lowest = 0
    local highest = 999.999

    local new_value = tonumber(e.element.text) or -1
    local out_of_bounds = new_value < lowest or new_value > highest

    if out_of_bounds then
      refs.slider_textfield.style = "ee_invalid_slider_textfield"
    else
      refs.slider_textfield.style = "ee_slider_textfield"

      local processed_value = math.round(math.clamp(new_value, 0, 999.999), 0.001)
      state.power = processed_value
      refs.slider.slider_value = processed_value

      set_entity_settings(
        state.entity,
        constants.ia.index_to_mode[refs.mode_dropdown.selected_index],
        calc_buffer_size(processed_value, refs.slider_dropdown.selected_index)
      )
    end
  elseif msg.action == "confirm_textfield" then
    refs.slider_textfield.text = tostring(state.power)
    refs.slider_textfield.style = "ee_slider_textfield"
  elseif msg.action == "update_units_of_measure" then
    set_entity_settings(
      state.entity,
      constants.ia.index_to_mode[refs.mode_dropdown.selected_index],
      calc_buffer_size(refs.slider.slider_value, refs.slider_dropdown.selected_index)
    )
  end
end

-- -----------------------------------------------------------------------------
-- FUNCTIONS

--- @param player_index uint
--- @param entity LuaEntity
function infinity_accumulator.open(player_index, entity)
  local player = game.get_player(player_index) --[[@as LuaPlayer]]
  local player_table = global.players[player_index]
  create_gui(player, player_table, entity)
  player.play_sound({ path = "entity-open/ee-infinity-accumulator-tertiary-buffer" })
end

--- @param source LuaEntity
--- @param destination LuaEntity
function infinity_accumulator.paste_settings(source, destination)
  -- get players viewing the destination accumulator
  local to_update = {}
  for i, player_table in pairs(global.players) do
    if player_table.gui.ia and player_table.gui.ia.state.entity == destination then
      to_update[#to_update + 1] = i
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
  for player_index, player_table in pairs(global.players) do
    if player_table.gui.ia and player_table.gui.ia.state.entity == entity then
      local player = game.get_player(player_index) --[[@as LuaPlayer]]
      destroy_gui(player, player_table)
    end
  end
end

infinity_accumulator.handle_gui_action = handle_gui_action

return infinity_accumulator
