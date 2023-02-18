local format = require("__flib__/format")
local gui = require("__flib__/gui-lite")
local math = require("__flib__/math")
local table = require("__flib__/table")

local shared_constants = require("__EditorExtensions__/shared-constants")

local util = require("__EditorExtensions__/scripts/util")

local crafter_snapping_types = {
  ["assembling-machine"] = true,
  ["furnace"] = true,
  ["rocket-silo"] = true,
}

--- @alias InfinityPipeMode
--- | "at-least",
--- | "at-most",
--- | "exactly",
--- | "add",
--- | "remove",

--- @enum InfinityPipeAmountType
local amount_type = {
  percent = 1,
  units = 2,
}

--- @param entity LuaEntity
--- @param tags table?
local function store_amount_type(entity, tags)
  if tags and tags.EditorExtensions then
    global.infinity_pipe_amount_type[entity.unit_number] = tags.EditorExtensions.amount_type
  end
end

--- @param entity LuaEntity
--- @return number?
local function remove_stored_amount_type(entity)
  local value = global.infinity_pipe_amount_type[entity.unit_number]
  global.infinity_pipe_amount_type[entity.unit_number] = nil
  return value
end

--- @param entity LuaEntity
--- @param new_capacity uint
--- @return LuaEntity?
local function swap_entity(entity, new_capacity)
  local amount_type = remove_stored_amount_type(entity)
  local new_entity = entity.surface.create_entity({
    name = "ee-infinity-pipe-" .. new_capacity,
    position = entity.position,
    direction = entity.direction,
    force = entity.force,
    fast_replace = true,
    create_build_effect_smoke = false,
    spill = false,
  })
  if not new_entity then
    return
  end
  store_amount_type(new_entity, { EditorExtensions = { amount_type = amount_type } })
  return new_entity
end

--- @param entity BlueprintEntity|LuaEntity
local function check_is_our_pipe(entity)
  return string.find(entity.name, "^ee%-infinity%-pipe%-%d+$")
end

--- @param entity LuaEntity
local function snap(entity)
  local own_id = entity.unit_number
  for _, fluidbox in ipairs(entity.fluidbox.get_connections(1)) do
    if not crafter_snapping_types[fluidbox.owner.type] then
      goto continue
    end
    for i = 1, #fluidbox do
      --- @cast i uint
      local connections = fluidbox.get_connections(i)
      for j = 1, #connections do
        if not connections[j].owner.unit_number == own_id then
          goto continue
        end
        local prototype = fluidbox.get_prototype(i)
        if prototype.production_type ~= "input" then
          goto continue
        end
        local fluid = fluidbox.get_locked_fluid(i)
        if fluid then
          entity.set_infinity_pipe_filter({ name = fluid, percentage = 1, mode = "at-least" })
          return
        end
      end
    end
    ::continue::
  end
end

--- @param filter InfinityPipeFilter?
--- @return double, double
local function get_temperature_limits(filter)
  if filter and filter.name then
    local prototype = game.fluid_prototypes[filter.name]
    return prototype.default_temperature, prototype.max_temperature
  end
  return 0, 100
end

-- GUI

--- @class InfinityPipeGui
--- @field elems InfinityPipeGuiElems
--- @field entity LuaEntity
--- @field mode InfinityPipeMode
--- @field player LuaPlayer
--- @field temperature double

--- @class InfinityPipeGuiElems
--- @field ee_infinity_pipe_window LuaGuiElement
--- @field titlebar_flow LuaGuiElement
--- @field drag_handle LuaGuiElement
--- @field capacity_dropdown LuaGuiElement
--- @field amount_progressbar LuaGuiElement
--- @field entity_preview LuaGuiElement
--- @field filter_button LuaGuiElement
--- @field amount_slider LuaGuiElement
--- @field amount_textfield LuaGuiElement
--- @field amount_type_dropdown LuaGuiElement
--- @field mode_radio_button_at_least LuaGuiElement
--- @field mode_radio_button_at_most LuaGuiElement
--- @field mode_radio_button_exactly LuaGuiElement
--- @field mode_radio_button_add LuaGuiElement
--- @field mode_radio_button_remove LuaGuiElement
--- @field temperature_slider LuaGuiElement
--- @field temperature_textfield LuaGuiElement

--- @param player_index uint
local function destroy_gui(player_index)
  local self = global.infinity_pipe_gui[player_index]
  if not self then
    return
  end
  global.infinity_pipe_gui[player_index] = nil
  local window = self.elems.ee_infinity_pipe_window
  if window.valid then
    window.destroy()
  end
end

--- @param self InfinityPipeGui
--- @param new_entity LuaEntity?
--- @param reset_temperature boolean?
local function update_gui(self, new_entity, reset_temperature)
  if not new_entity and not self.entity.valid then
    destroy_gui(self.player.index)
    return
  end
  local elems = self.elems
  if new_entity then
    elems.entity_preview.entity = new_entity
    self.entity = new_entity
  end
  local entity = self.entity
  local filter = entity.get_infinity_pipe_filter() or {}
  if filter.mode then
    self.mode = filter.mode
  end
  if filter.temperature then
    self.temperature = filter.temperature
  elseif reset_temperature then
    self.temperature = 0
  end

  local capacity = entity.fluidbox.get_capacity(1)
  elems.capacity_dropdown.selected_index = table.find(shared_constants.infinity_pipe_capacities, capacity) --[[@as uint]]

  elems.filter_button.elem_value = filter.name
  elems.amount_slider.slider_value = filter.percentage or 0
  elems.amount_textfield.style = "ee_slider_textfield"
  elems.amount_textfield.text = tostring(math.floor((filter.percentage or 0) * 100))

  local mode = self.mode
  elems.mode_radio_button_at_least.state = mode == "at-least"
  elems.mode_radio_button_at_most.state = mode == "at-most"
  elems.mode_radio_button_exactly.state = mode == "exactly"
  elems.mode_radio_button_add.state = mode == "add"
  elems.mode_radio_button_remove.state = mode == "remove"

  local min, max = get_temperature_limits(filter)
  if min == max then
    elems.temperature_slider.enabled = false
    elems.temperature_textfield.enabled = false
    elems.temperature_slider.set_slider_minimum_maximum(min, max + 1)
    elems.temperature_slider.slider_value = min
  else
    elems.temperature_slider.enabled = true
    elems.temperature_textfield.enabled = true
    elems.temperature_slider.set_slider_minimum_maximum(min, max)
    elems.temperature_slider.slider_value = self.temperature
  end
  elems.temperature_textfield.style = "ee_slider_textfield"
  elems.temperature_textfield.text = tostring(self.temperature)
end

--- @param entity LuaEntity
--- @param reset_temperature boolean?
local function update_all_guis(entity, reset_temperature)
  for _, gui in pairs(global.infinity_pipe_gui) do
    if not gui.entity.valid then
      update_gui(gui, entity, reset_temperature)
    elseif gui.entity == entity then
      update_gui(gui, nil, reset_temperature)
    end
  end
end

local handlers = {
  --- @param self InfinityPipeGui
  --- @param e EventData.on_gui_closed|EventData.on_gui_click
  on_ip_gui_closed = function(self, e)
    destroy_gui(e.player_index)
    local player = self.player
    if not player.valid then
      return
    end
    player.play_sound({ path = "entity-close/ee-infinity-accumulator-tertiary-buffer" })
  end,

  --- @param self InfinityPipeGui
  --- @param e EventData.on_gui_selection_state_changed
  on_ip_gui_capacity_dropdown_selection_state_changed = function(self, e)
    local entity = self.entity
    local new_capacity = shared_constants.infinity_pipe_capacities[e.element.selected_index]
    if new_capacity == entity.fluidbox.get_capacity(1) then
      return
    end
    local new_entity = swap_entity(entity, new_capacity)
    if not new_entity then
      return
    end
    update_all_guis(new_entity)
  end,

  --- @param self InfinityPipeGui
  --- @param e EventData.on_gui_elem_changed
  on_ip_gui_filter_changed = function(self, e)
    local entity = self.entity
    local elem = e.element.elem_value --[[@as string?]]
    if elem then
      if not filter then
        filter = { mode = self.mode, percentage = 1 }
      end
      filter.name = elem
      entity.set_infinity_pipe_filter(filter)
    else
      entity.set_infinity_pipe_filter(nil)
    end
    update_all_guis(entity, not elem)
  end,

  --- @param self InfinityPipeGui
  --- @param e EventData.on_gui_elem_changed
  on_ip_gui_amount_slider_value_changed = function(self, e)
    local entity = self.entity
    local value = e.element.slider_value
    local filter = entity.get_infinity_pipe_filter()
    if not filter then
      -- Textfield should always match slider
      local textfield = self.elems.amount_textfield
      textfield.style = "ee_slider_textfield"
      textfield.text = tostring(math.floor(value * 100))
      return
    end
    filter.percentage = value
    entity.set_infinity_pipe_filter(filter)
    update_all_guis(entity)
  end,

  --- @param self InfinityPipeGui
  --- @param e EventData.on_gui_text_changed
  on_ip_gui_amount_textfield_changed = function(self, e)
    local entity = self.entity
    local textfield = e.element
    local text = textfield.text
    local value = tonumber(text)
    if not value or value < 0 or value > 100 then
      textfield.style = "ee_invalid_slider_textfield"
      return
    end
    textfield.style = "ee_slider_textfield"
    value = value / 100

    self.elems.amount_slider.slider_value = value

    local filter = entity.get_infinity_pipe_filter()
    if filter then
      filter.percentage = value
      entity.set_infinity_pipe_filter(filter)
      update_all_guis(entity)
    end
  end,

  --- @param self InfinityPipeGui
  --- @param e EventData.on_gui_checked_state_changed
  on_ip_gui_mode_radio_button_selected = function(self, e)
    local mode = e.element.tags.mode --[[@as string]]
    self.mode = mode

    local entity = self.entity
    local filter = entity.get_infinity_pipe_filter()
    if filter then
      filter.mode = mode
      entity.set_infinity_pipe_filter(filter)
    end

    update_all_guis(entity)
  end,

  on_ip_gui_temperature_slider_value_changed = function(self, e)
    local entity = self.entity
    local value = math.floor(e.element.slider_value)
    local filter = entity.get_infinity_pipe_filter()
    if not filter then
      -- Textfield should always match slider
      local textfield = self.elems.temperature_textfield
      textfield.style = "ee_slider_textfield"
      textfield.text = tostring(value)
      return
    end
    filter.temperature = value
    entity.set_infinity_pipe_filter(filter)
    update_all_guis(entity)
  end,

  on_ip_gui_temperature_textfield_changed = function(self, e)
    local entity = self.entity
    local textfield = e.element
    local text = textfield.text
    local value = tonumber(text)

    local filter = entity.get_infinity_pipe_filter()
    local min, max = get_temperature_limits(filter)

    if not value or value < min or value > max then
      textfield.style = "ee_invalid_slider_textfield"
      return
    end
    textfield.style = "ee_slider_textfield"

    self.elems.temperature_slider.slider_value = value

    if filter then
      filter.temperature = value
      entity.set_infinity_pipe_filter(filter)
      update_all_guis(entity)
    end
  end,
}

gui.add_handlers(handlers, function(e, handler)
  local self = global.infinity_pipe_gui[e.player_index]
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

  --- @type InfinityPipeGuiElems
  local elems = gui.add(player.gui.screen, {
    type = "frame",
    name = "ee_infinity_pipe_window",
    direction = "vertical",
    elem_mods = { auto_center = true },
    handler = { [defines.events.on_gui_closed] = handlers.on_ip_gui_closed },
    {
      type = "flow",
      name = "titlebar_flow",
      style = "flib_titlebar_flow",
      drag_target = "ee_infinity_pipe_window",
      {
        type = "label",
        style = "frame_title",
        caption = { "entity-name.ee-infinity-pipe" },
        ignored_by_interaction = true,
      },
      { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
      util.close_button(handlers.on_ip_gui_closed),
    },
    {
      type = "frame",
      style = "entity_frame",
      direction = "vertical",
      {
        type = "frame",
        style = "deep_frame_in_shallow_frame",
        style_mods = { bottom_margin = 4 },
        {
          type = "entity-preview",
          name = "entity_preview",
          style = "wide_entity_button",
          elem_mods = { entity = entity },
        },
      },
      {
        type = "flow",
        style_mods = { horizontal_spacing = 8, vertical_align = "center" },
        {
          type = "progressbar",
          name = "amount_progressbar",
          style = "production_progressbar",
          style_mods = { horizontally_stretchable = true, bottom_margin = 2 },
        },
        { type = "label", caption = "/" },
        {
          type = "drop-down",
          name = "capacity_dropdown",
          items = table.map(shared_constants.infinity_pipe_capacities, function(capacity)
            return format.number(capacity)
          end),
          selected_index = 0,
          handler = {
            [defines.events.on_gui_selection_state_changed] = handlers.on_ip_gui_capacity_dropdown_selection_state_changed,
          },
        },
      },
      { type = "line", direction = "horizontal" },
      {
        type = "flow",
        style = "centering_horizontal_flow",
        direction = "horizontal",
        {
          type = "choose-elem-button",
          name = "filter_button",
          style = "flib_standalone_slot_button_default",
          elem_type = "fluid",
          handler = { [defines.events.on_gui_elem_changed] = handlers.on_ip_gui_filter_changed },
        },
        {
          type = "slider",
          name = "amount_slider",
          style_mods = { horizontally_stretchable = true, margin = { 0, 8, 0, 8 } },
          minimum_value = 0,
          maximum_value = 1,
          value_step = 0.01,
          value = 0,
          handler = { [defines.events.on_gui_value_changed] = handlers.on_ip_gui_amount_slider_value_changed },
        },
        {
          type = "textfield",
          name = "amount_textfield",
          style = "slider_value_textfield",
          numeric = true,
          allow_decimal = true,
          clear_and_focus_on_right_click = true,
          text = "0",
          handler = { [defines.events.on_gui_text_changed] = handlers.on_ip_gui_amount_textfield_changed },
        },
        {
          type = "drop-down",
          name = "amount_type_dropdown",
          style_mods = { width = 55 },
          items = { { "gui-infinity-pipe.percent" }, { "gui-infinity-pipe.ee-units" } },
          selected_index = 1,
          actions = {
            on_selection_state_changed = { gui = "infinity_pipe", action = "change_amount_type" },
          },
        },
      },
      {
        type = "flow",
        style_mods = { horizontal_spacing = 0 },
        direction = "horizontal",
        util.mode_radio_button("at-least", handlers.on_ip_gui_mode_radio_button_selected),
        util.pusher(),
        util.mode_radio_button("at-most", handlers.on_ip_gui_mode_radio_button_selected),
        util.pusher(),
        util.mode_radio_button("exactly", handlers.on_ip_gui_mode_radio_button_selected),
        util.pusher(),
        util.mode_radio_button("add", handlers.on_ip_gui_mode_radio_button_selected),
        util.pusher(),
        util.mode_radio_button("remove", handlers.on_ip_gui_mode_radio_button_selected),
      },
      { type = "line", direction = "horizontal" },
      {
        type = "flow",
        style = "centering_horizontal_flow",
        style_mods = { vertical_align = "center" },
        direction = "horizontal",
        { type = "label", caption = { "gui-infinity-pipe.temperature" } },
        {
          type = "slider",
          name = "temperature_slider",
          style_mods = { horizontally_stretchable = true, margin = { 0, 8, 0, 8 } },
          minimum_value = 0,
          maximum_value = 100,
          value = 0,
          handler = {
            [defines.events.on_gui_value_changed] = handlers.on_ip_gui_temperature_slider_value_changed,
          },
        },
        {
          type = "textfield",
          name = "temperature_textfield",
          style = "slider_value_textfield",
          clear_and_focus_on_right_click = true,
          text = "0",
          handler = {
            [defines.events.on_gui_text_changed] = handlers.on_ip_gui_temperature_textfield_changed,
          },
        },
      },
    },
  })

  player.opened = elems.ee_infinity_pipe_window

  --- @type InfinityPipeGui
  local self = {
    elems = elems,
    entity = entity,
    mode = "at-least",
    temperature = 0,
    player = player,
  }
  global.infinity_pipe_gui[player.index] = self

  update_gui(self)
end

--- @param e BuiltEvent
local function on_built_entity(e)
  local entity = e.created_entity or e.entity or e.destination
  if not entity or not entity.valid or not check_is_our_pipe(entity) then
    return
  end
  snap(entity)
end

--- @param e EventData.on_gui_opened
local function on_gui_opened(e)
  local entity = e.entity
  if not entity or not check_is_our_pipe(entity) then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  create_gui(player, entity)
end

--- @param e EventData.on_player_setup_blueprint
local function on_player_setup_blueprint(e)
  -- if entity then
  -- 	if not blueprint_entity.tags then
  -- 		blueprint_entity.tags = {}
  -- 	end
  -- 	blueprint_entity.tags.EditorExtensions = { amount_type = global.infinity_pipe_amount_type[entity.unit_number] }
  -- end
  -- return blueprint_entity
end

-- TODO: Settings copy/paste

local infinity_pipe = {}

infinity_pipe.on_init = function()
  global.infinity_pipe_gui = {}
  --- @type table<uint, InfinityPipeAmountType>
  global.infinity_pipe_amount_type = {}
end

infinity_pipe.on_configuration_changed = function()
  for player_index in pairs(game.players) do
    destroy_gui(player_index --[[@as uint]])
  end
end

infinity_pipe.events = {
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_entity_cloned] = on_built_entity,
  [defines.events.on_gui_opened] = on_gui_opened,
  [defines.events.on_player_setup_blueprint] = on_player_setup_blueprint,
  [defines.events.on_robot_built_entity] = on_built_entity,
  [defines.events.script_raised_built] = on_built_entity,
  [defines.events.script_raised_revive] = on_built_entity,
}

return infinity_pipe
