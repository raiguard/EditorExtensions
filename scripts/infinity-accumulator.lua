local gui = require("__flib__/gui-lite")
local math = require("__flib__/math")
local table = require("__flib__/table")

local util = require("__EditorExtensions__/scripts/util")

local si_suffixes_joule = { "kJ", "MJ", "GJ", "TJ", "PJ", "EJ", "ZJ", "YJ" }
local si_suffixes_watt = { "kW", "MW", "GW", "TW", "PW", "EW", "ZW", "YW" }

--- @type InfinityAccumulatorMode[]
local modes = { "output", "input", "buffer" }
--- @type InfinityAccumulatorPriority[]
local priorities = { "primary", "secondary", "tertiary" }

local entity_names = {
  ["ee-infinity-accumulator-primary-input"] = true,
  ["ee-infinity-accumulator-primary-output"] = true,
  ["ee-infinity-accumulator-secondary-input"] = true,
  ["ee-infinity-accumulator-secondary-output"] = true,
  ["ee-infinity-accumulator-tertiary-buffer"] = true,
  ["ee-infinity-accumulator-tertiary-input"] = true,
  ["ee-infinity-accumulator-tertiary-output"] = true,
}

--- @alias InfinityAccumulatorMode
--- | "output"
--- | "input"
--- | "buffer"

--- @alias InfinityAccumulatorPriority
--- | "primary"
--- | "secondary"
--- | "tertiary"

--- @param name string
--- @return InfinityAccumulatorPriority, InfinityAccumulatorMode
local function get_settings_from_name(name)
  local priority, mode = string.match(name, "^ee%-infinity%-accumulator%-(%a+)%-(%a+)$")
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

  -- Calculate new buffer size
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

--- Returns the power_slider value and dropdown selected index based on the entity's buffer size
--- @param buffer_size double
--- @param mode InfinityAccumulatorMode
--- @return uint, uint
local function get_slider_values(buffer_size, mode)
  if mode ~= "buffer" then
    -- The power_slider is controlling watts, so inflate the buffer size by 60x to get that value
    buffer_size = buffer_size * 60
  end
  -- Determine how many orders of magnitude there are
  local len = string.len(string.format("%.0f", math.floor(buffer_size)))
  -- `power` is the dropdown value - how many sets of three orders of magnitude there are, rounded down
  local power = math.floor((len - 1) / 3)
  -- Slider value is the buffer size scaled to its base-three order of magnitude
  return buffer_size / 10 ^ (power * 3) --[[@as uint]],
    math.max(power, 1) --[[@as uint]]
end

--- Returns the entity buffer size based on the power_slider value and dropdown selected index
local function calc_buffer_size(slider_value, dropdown_index)
  return util.parse_energy(slider_value .. si_suffixes_joule[dropdown_index]) / 60
end

--- @param player_index uint
local function destroy_gui(player_index)
  local self = global.infinity_accumulator_gui[player_index]
  if not self then
    return
  end
  global.infinity_accumulator_gui[player_index] = nil
  local window = self.elems.ee_infinity_accumulator_window
  if not window.valid then
    return
  end
  window.destroy()
end

--- @param self InfinityAccumulatorGui
--- @param new_entity LuaEntity?
local function update_gui(self, new_entity)
  if not new_entity and not self.entity.valid then
    destroy_gui(self.player.index)
    return
  end
  if new_entity then
    self.elems.entity_preview.entity = new_entity
    self.entity = new_entity
  end

  local entity = self.entity
  local priority, mode = get_settings_from_name(entity.name)

  local mode_dropdown = self.elems.mode_dropdown
  mode_dropdown.selected_index = table.find(modes, mode) --[[@as uint]]

  local priority_dropdown = self.elems.priority_dropdown
  priority_dropdown.selected_index = table.find(priorities, priority) --[[@as uint]]
  priority_dropdown.enabled = mode ~= "buffer"

  local slider_value, dropdown_index = get_slider_values(entity.electric_buffer_size, mode)

  local power_slider = self.elems.power_slider
  power_slider.slider_value = slider_value
  local textfield = self.elems.power_textfield
  textfield.text = tostring(slider_value)
  local dropdown = self.elems.power_dropdown
  if mode == "buffer" then
    dropdown.items = si_suffixes_joule
  else
    dropdown.items = si_suffixes_watt
  end
  dropdown.selected_index = dropdown_index
end

--- @param entity LuaEntity
local function update_all_guis(entity)
  for _, gui in pairs(global.infinity_accumulator_gui) do
    if not gui.entity.valid or gui.entity == entity then
      update_gui(gui, entity)
    end
  end
end

local handlers = {
  --- @param self InfinityAccumulatorGui
  --- @param e EventData.on_gui_closed|EventData.on_gui_click
  on_ia_gui_closed = function(self, e)
    destroy_gui(e.player_index)
    local player = self.player
    if not player.valid then
      return
    end
    player.play_sound({ path = "entity-close/ee-infinity-accumulator-tertiary-buffer" })
  end,

  --- @param self InfinityAccumulatorGui
  --- @param e EventData.on_gui_selection_state_changed
  on_ia_gui_mode_dropdown_changed = function(self, e)
    local entity = self.entity
    local mode = modes[e.element.selected_index]
    local priority = "tertiary"
    if mode ~= "buffer" then
      priority = get_settings_from_name(entity.name)
    end
    local new_entity = change_entity(entity, priority, mode)
    if not new_entity then
      return
    end
    update_all_guis(new_entity)
  end,

  --- @param self InfinityAccumulatorGui
  --- @param e EventData.on_gui_selection_state_changed
  on_ia_gui_priority_dropdown_changed = function(self, e)
    local entity = self.entity
    local priority = priorities[e.element.selected_index]
    local _, mode = get_settings_from_name(entity.name)
    local new_entity = change_entity(entity, priority, mode)
    if not new_entity then
      return
    end
    update_all_guis(new_entity)
  end,

  --- @param self InfinityAccumulatorGui
  --- @param e EventData.on_gui_selection_state_changed
  on_ia_gui_power_slider_changed = function(self, e)
    local entity = self.entity
    local slider_value = e.element.slider_value
    local dropdown_index = self.elems.power_dropdown.selected_index
    local buffer_size = calc_buffer_size(slider_value, dropdown_index)
    local _, mode = get_settings_from_name(entity.name)
    set_entity_settings(entity, mode, buffer_size)
    update_all_guis(entity)
  end,

  --- @param self InfinityAccumulatorGui
  --- @param e EventData.on_gui_text_changed
  on_ia_gui_power_textfield_changed = function(self, e)
    local entity = self.entity
    local textfield = e.element
    local text = textfield.text
    local value = tonumber(text)
    if not value or value < 0 or value >= 1000 then
      textfield.style = "ee_invalid_slider_textfield"
      return
    end
    textfield.style = "ee_slider_textfield"
    if string.sub(text, #text) == "." then
      return
    end

    self.elems.power_slider.slider_value = value

    local _, mode = get_settings_from_name(entity.name)
    local buffer_size = calc_buffer_size(value, self.elems.power_dropdown.selected_index)
    set_entity_settings(entity, mode, buffer_size)
    update_all_guis(entity)
  end,

  --- @param self InfinityAccumulatorGui
  --- @param e EventData.on_gui_selection_state_changed
  on_ia_gui_power_dropdown_changed = function(self, e)
    local entity = self.entity
    local _, mode = get_settings_from_name(entity.name)
    local buffer_size = calc_buffer_size(self.elems.power_slider.slider_value, e.element.selected_index)
    set_entity_settings(entity, mode, buffer_size)
    update_all_guis(entity)
  end,
}

gui.add_handlers(handlers, function(e, handler)
  local self = global.infinity_accumulator_gui[e.player_index]
  if not self then
    return
  end
  if not self.entity.valid then
    return
  end

  handler(self, e)
end)

--- @param player LuaPlayer
--- @param entity LuaEntity
local function create_gui(player, entity)
  destroy_gui(player.index)

  local elems = gui.add(player.gui.screen, {
    type = "frame",
    name = "ee_infinity_accumulator_window",
    direction = "vertical",
    elem_mods = { auto_center = true },
    handler = { [defines.events.on_gui_closed] = handlers.on_ia_gui_closed },
    {
      type = "flow",
      style = "flib_titlebar_flow",
      drag_target = "ee_infinity_accumulator_window",
      {
        type = "label",
        style = "frame_title",
        caption = { "entity-name.ee-infinity-accumulator" },
        ignored_by_interaction = true,
      },
      { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
      util.close_button(handlers.on_ia_gui_closed),
    },
    {
      type = "frame",
      style = "entity_frame",
      direction = "vertical",
      {
        type = "frame",
        style = "deep_frame_in_shallow_frame",
        {
          type = "entity-preview",
          name = "entity_preview",
          style = "wide_entity_button",
          elem_mods = { entity = entity },
        },
      },
      {
        type = "flow",
        style_mods = { top_margin = 4, vertical_align = "center" },
        { type = "label", caption = { "gui.ee-mode" } },
        util.pusher(),
        {
          type = "drop-down",
          name = "mode_dropdown",
          items = { { "gui.ee-output" }, { "gui.ee-input" }, { "gui.ee-buffer" } },
          selected_index = 0,
          handler = {
            [defines.events.on_gui_selection_state_changed] = handlers.on_ia_gui_mode_dropdown_changed,
          },
        },
      },
      { type = "line", direction = "horizontal" },
      {
        type = "flow",
        style_mods = { vertical_align = "center" },
        {
          type = "label",
          caption = { "", { "gui.ee-priority" }, " [img=info]" },
          tooltip = { "gui.ee-ia-priority-description" },
        },
        util.pusher(),
        {
          type = "drop-down",
          name = "priority_dropdown",
          items = { { "gui.ee-primary" }, { "gui.ee-secondary" }, { "gui.ee-tertiary" } },
          selected_index = 0,
          handler = {
            [defines.events.on_gui_selection_state_changed] = handlers.on_ia_gui_priority_dropdown_changed,
          },
        },
      },
      { type = "line", direction = "horizontal" },
      {
        type = "flow",
        style_mods = { vertical_align = "center" },
        {
          type = "label",
          style_mods = { right_margin = 6 },
          caption = { "gui.ee-power" },
        },
        {
          type = "slider",
          name = "power_slider",
          style_mods = { horizontally_stretchable = true },
          minimum_value = 0,
          maximum_value = 999,
          value = 0,
          handler = { [defines.events.on_gui_value_changed] = handlers.on_ia_gui_power_slider_changed },
        },
        {
          type = "textfield",
          name = "power_textfield",
          style = "ee_slider_textfield",
          text = "",
          numeric = true,
          allow_decimal = true,
          clear_and_focus_on_right_click = true,
          handler = { [defines.events.on_gui_text_changed] = handlers.on_ia_gui_power_textfield_changed },
        },
        {
          type = "drop-down",
          name = "power_dropdown",
          style_mods = { width = 69 },
          selected_index = 0,
          handler = {
            [defines.events.on_gui_selection_state_changed] = handlers.on_ia_gui_power_dropdown_changed,
          },
        },
      },
    },
  })

  player.opened = elems.ee_infinity_accumulator_window

  --- @class InfinityAccumulatorGui
  local self = {
    elems = elems,
    entity = entity,
    player = player,
  }
  global.infinity_accumulator_gui[player.index] = self

  update_gui(self)
end

--- @param e DestroyedEvent
local function on_entity_destroyed(e)
  local entity = e.entity
  if not entity.valid or not entity_names[entity.name] then
    return
  end

  for player_index, gui in pairs(global.infinity_accumulator_gui) do
    if gui.entity == entity then
      destroy_gui(player_index)
    end
  end
end

--- @param e EventData.on_entity_settings_pasted
local function on_entity_settings_pasted(e)
  local source = e.source
  if not source.valid or not entity_names[source.name] then
    return
  end
  local destination = e.destination
  if not destination.valid or not entity_names[destination.name] then
    return
  end

  local source_priority, source_mode = get_settings_from_name(source.name)
  local destination_priority, destination_mode = get_settings_from_name(destination.name)
  if source_priority == destination_priority and source_mode == destination_mode then
    return
  end
  local new_entity = change_entity(destination, source_priority, source_mode)
  if not new_entity then
    return
  end

  update_all_guis(new_entity)
end

--- @param e EventData.on_gui_opened
local function on_gui_opened(e)
  if e.gui_type ~= defines.gui_type.entity then
    return
  end
  local entity = e.entity
  if not entity or not entity.valid or not entity_names[entity.name] then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  create_gui(player, entity)
end

local infinity_accumulator = {}

infinity_accumulator.on_init = function()
  --- @type table<uint, InfinityAccumulatorGui>
  global.infinity_accumulator_gui = {}
end

infinity_accumulator.on_configuration_changed = function()
  for player_index in pairs(game.players) do
    destroy_gui(player_index --[[@as uint]])
  end
end

infinity_accumulator.events = {
  [defines.events.on_entity_died] = on_entity_destroyed,
  [defines.events.on_entity_settings_pasted] = on_entity_settings_pasted,
  [defines.events.on_gui_opened] = on_gui_opened,
  [defines.events.on_player_mined_entity] = on_entity_destroyed,
  [defines.events.on_robot_mined_entity] = on_entity_destroyed,
  [defines.events.script_raised_destroy] = on_entity_destroyed,
}

return infinity_accumulator
