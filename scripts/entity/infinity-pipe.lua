local gui = require("__flib__.gui")
local math = require("__flib__.math")
local misc = require("__flib__.misc")
local table = require("__flib__.table")

local shared_constants = require("__EditorExtensions__.shared-constants")

local constants = require("__EditorExtensions__.scripts.constants")
local util = require("__EditorExtensions__.scripts.util")

local infinity_pipe = {}

--- @param entity LuaEntity
--- @param new_name string
--- @return LuaEntity
local function swap_entity(entity, new_name)
  local amount_type = infinity_pipe.remove_stored_amount_type(entity)
  local new_entity = entity.surface.create_entity({
    name = new_name,
    position = entity.position,
    direction = entity.direction,
    force = entity.force,
    fast_replace = true,
    create_build_effect_smoke = false,
    spill = false,
  }) --[[@as LuaEntity]]
  infinity_pipe.store_amount_type(new_entity, { EditorExtensions = { amount_type = amount_type } })
  return new_entity
end

-- BOOTSTRAP

function infinity_pipe.init()
  global.infinity_pipe_amount_types = {}
end

-- ENTITY

--- @param entity LuaEntity
--- @param tags table?
function infinity_pipe.store_amount_type(entity, tags)
  if tags and tags.EditorExtensions then
    global.infinity_pipe_amount_types[entity.unit_number] = tags.EditorExtensions.amount_type
  end
end

--- @param entity LuaEntity
--- @return number?
function infinity_pipe.remove_stored_amount_type(entity)
  local value = global.infinity_pipe_amount_types[entity.unit_number]
  global.infinity_pipe_amount_types[entity.unit_number] = nil
  return value
end

--- @param entity BlueprintEntity|LuaEntity
function infinity_pipe.check_is_our_pipe(entity)
  return string.find(entity.name, "^ee%-infinity%-pipe%-%d+$")
end

--- @param blueprint_entity BlueprintEntity
--- @param entity LuaEntity?
function infinity_pipe.setup_blueprint(blueprint_entity, entity)
  if entity then
    if not blueprint_entity.tags then
      blueprint_entity.tags = {}
    end
    blueprint_entity.tags.EditorExtensions = { amount_type = global.infinity_pipe_amount_types[entity.unit_number] }
  end
  return blueprint_entity
end

--- @param source LuaEntity
--- @param destination LuaEntity
--- @return LuaEntity
function infinity_pipe.paste_settings(source, destination)
  if source.name ~= destination.name then
    destination = swap_entity(destination, source.name)
    destination.set_infinity_pipe_filter(source.get_infinity_pipe_filter())
  end
  global.infinity_pipe_amount_types[destination.unit_number] = global.infinity_pipe_amount_types[source.unit_number]

  return destination
end

--- @param entity LuaEntity
--- @param player_settings table
function infinity_pipe.snap(entity, player_settings)
  local own_id = entity.unit_number
  -- TODO: Move the player setting check out of here?
  if player_settings.infinity_pipe_crafter_snapping then
    for _, fluidbox in ipairs(entity.fluidbox.get_connections(1)) do
      local owner_type = fluidbox.owner.type
      if constants.ip_crafter_snapping_types[owner_type] then
        for i = 1, #fluidbox do
          --- @cast i uint
          local connections = fluidbox.get_connections(i)
          for j = 1, #connections do
            if connections[j].owner.unit_number == own_id then
              local prototype = fluidbox.get_prototype(i)
              if prototype.production_type == "input" then
                local fluid = fluidbox.get_locked_fluid(i)
                if fluid then
                  entity.set_infinity_pipe_filter({ name = fluid, percentage = 1, mode = "at-least" })
                  return
                end
              end
            end
          end
        end
      end
    end
  end
end

-- GUI

--- @class InfinityPipeGuiRefs
--- @field window LuaGuiElement
--- @field titlebar_flow LuaGuiElement
--- @field drag_handle LuaGuiElement
--- @field capacity_dropdown LuaGuiElement
--- @field amount_progressbar LuaGuiElement
--- @field entity_preview LuaGuiElement
--- @field fluid_button LuaGuiElement
--- @field amount_slider LuaGuiElement
--- @field amount_textfield LuaGuiElement
--- @field amount_type_dropdown LuaGuiElement
--- @field amount_radio_buttons table<string, LuaGuiElement>
--- @field temperature_slider LuaGuiElement
--- @field temperature_textfield LuaGuiElement

--- @class InfinityPipeGui
local Gui = {}

--- @param e on_gui_selection_state_changed
function Gui:change_capacity(_, e)
  local new_capacity = shared_constants.infinity_pipe_capacities[e.element.selected_index]
  local new_name = "ee-infinity-pipe-" .. new_capacity
  if not game.entity_prototypes[new_name] then
    return
  end

  local entity = self.entity
  if not entity or not entity.valid or entity.name == new_name then
    return
  end

  local new_entity = swap_entity(entity, new_name)

  if new_entity then
    self.entity = new_entity
    self.entity_unit_number = new_entity.unit_number

    local filter = self.state.filter
    if filter and self.state.amount_type == constants.infinity_pipe_amount_type.units then
      filter.percentage = filter.percentage * (self.state.capacity / new_capacity)
    end

    self.state.capacity = new_capacity

    self:update(true)
  end
end

function Gui:change_fluid()
  local fluid_name = self.refs.fluid_button.elem_value --[[@as string]]
  local filter = self.state.filter
  if fluid_name then
    local prototype = game.fluid_prototypes[fluid_name]
    if filter then
      -- Changed fluids
      filter.name = fluid_name
      filter.temperature = prototype.default_temperature
    else
      -- Added fluid
      self.state.filter = {
        name = fluid_name,
        -- Default to 100% like the vanilla infinity pipe
        percentage = 1,
        temperature = prototype.default_temperature,
        mode = self.state.selected_mode,
      }
    end
  elseif filter then
    -- Removed fluid
    self.state.filter = nil
  else
    -- Just opened the GUI with no fluid
    return
  end

  self:update()
end

--- @param msg table
--- @param e on_gui_value_changed|on_gui_text_changed
function Gui:change_amount(msg, e)
  local element = e.element
  local type = msg.elem
  local new_percentage
  if type == "slider" then
    new_percentage = element.slider_value
  else
    new_percentage = tonumber(element.text)
    local is_percent = self.state.amount_type == constants.infinity_pipe_amount_type.percent
    local max = is_percent and 100 or self.state.capacity
    local typing_decimal = string.find(element.text, "%.$")
    if not typing_decimal and new_percentage and new_percentage <= max then
      new_percentage = new_percentage / max
    else
      element.style = "ee_invalid_slider_value_textfield"
      return
    end
  end

  if self.state.filter then
    self.state.filter.percentage = new_percentage
  end

  self:update()
end

--- @param e on_gui_selection_state_changed
function Gui:change_amount_type(_, e)
  -- This is a 1:1 representation
  self.state.amount_type = e.element.selected_index
  global.infinity_pipe_amount_types[self.entity.unit_number] = self.state.amount_type

  self:update()
end

--- @param msg table
function Gui:change_amount_mode(msg)
  self.state.selected_mode = msg.mode

  if self.state.filter then
    self.state.filter.mode = msg.mode
  end

  self:update()
end

function Gui:change_temperature(msg, e)
  local filter = self.state.filter
  if not filter then
    return
  end

  local element = e.element
  local type = msg.elem
  local new_temperature
  if type == "slider" then
    new_temperature = element.slider_value
  else
    new_temperature = tonumber(element.text)
    local slider = self.refs.temperature_slider
    if
      new_temperature
      and new_temperature >= slider.get_slider_minimum()
      and new_temperature <= slider.get_slider_maximum()
    then
      -- Pass
    else
      element.style = "ee_invalid_slider_value_textfield"
      return
    end
  end

  if filter then
    filter.temperature = new_temperature
  end

  self:update()
end

function Gui:display_fluid_contents()
  if not self.entity or not self.entity.valid or not self.refs.window.valid then
    return
  end

  local progressbar = self.refs.amount_progressbar

  -- There is only one fluidbox on an infinity pipe
  local fluid_contents = self.entity.get_fluid_contents()
  local fluid_name = next(fluid_contents)
  if not fluid_name then
    progressbar.caption = "0"
    progressbar.value = 0
    return
  end
  local fluid_amount = fluid_contents[fluid_name]

  progressbar.value = fluid_amount / self.state.capacity
  progressbar.caption = misc.delineate_number(string.format("%.2f", fluid_amount))

  if fluid_name ~= self.state.current_fluid_name then
    self.state.current_fluid_name = fluid_name
    local bar_color = game.fluid_prototypes[fluid_name].base_color
    -- Calculate luminance of the background color
    -- Source: https://stackoverflow.com/questions/596216/formula-to-determine-perceived-brightness-of-rgb-color
    local luminance = (0.2126 * bar_color.r) + (0.7152 * bar_color.g) + (0.0722 * bar_color.b)
    if luminance > 0.55 then
      progressbar.style = "production_progressbar"
    else
      progressbar.style = "ee_production_progressbar_light_text"
    end

    progressbar.style.horizontally_stretchable = true
    progressbar.style.color = bar_color
  end
end

-- Updates all GUI elements and sets the filter on the entity
--- @param update_entity_preview boolean?
function Gui:update(update_entity_preview)
  -- Entity preview
  if update_entity_preview then
    self.refs.entity_preview.entity = self.entity
  end

  -- Capacity dropdown
  local dropdown = self.refs.capacity_dropdown
  dropdown.selected_index = table.find(shared_constants.infinity_pipe_capacities, self.state.capacity)

  local filter = self.state.filter
  local filter_exists = filter and true or false

  -- Fluid button
  local fluid_button = self.refs.fluid_button
  fluid_button.elem_value = filter and filter.name or nil

  -- Calculate amount from percentage
  local amount = 0
  if filter then
    if self.state.amount_type == constants.infinity_pipe_amount_type.percent then
      amount = math.round(filter.percentage * 100, 0.01)
    else
      amount = math.round(filter.percentage * self.state.capacity)
    end
  end

  -- Amount slider and textfield
  local amount_slider = self.refs.amount_slider
  local amount_textfield = self.refs.amount_textfield
  amount_slider.slider_value = filter and filter.percentage or 0
  amount_textfield.text = tostring(amount)
  amount_textfield.style = "slider_value_textfield"

  amount_slider.enabled = filter_exists
  amount_textfield.enabled = filter_exists

  -- Amount type dropdown
  local amount_type_dropdown = self.refs.amount_type_dropdown
  amount_type_dropdown.selected_index = self.state.amount_type
  amount_type_dropdown.enabled = filter_exists

  -- Amount mode buttons
  local mode = filter and filter.mode or self.state.selected_mode
  for _, button in pairs(self.refs.amount_radio_buttons) do
    button.state = gui.get_tags(button).mode == mode
  end

  -- Get minimum and maximum temperatures
  local min_temp = 0
  local max_temp = 0
  if filter then
    local prototype = game.fluid_prototypes[filter.name]
    min_temp = prototype.default_temperature
    max_temp = prototype.max_temperature
  end

  -- Slider and textfield
  local temperature_slider = self.refs.temperature_slider
  local temperature_textfield = self.refs.temperature_textfield
  if filter and min_temp ~= max_temp then
    temperature_slider.enabled = true
    temperature_slider.set_slider_minimum_maximum(min_temp, max_temp)
    temperature_slider.slider_value = filter.temperature
    temperature_textfield.enabled = true
  else
    temperature_slider.enabled = false
    temperature_textfield.enabled = false
  end
  temperature_textfield.style = "slider_value_textfield"
  temperature_textfield.text = tostring(filter and filter.temperature or 0)

  -- Set filter on entity
  self.entity.set_infinity_pipe_filter(filter)
end

function Gui:destroy()
  if self.refs.window.valid then
    self.refs.window.destroy()
    self.player.opened = nil
    self.player.play_sound({ path = "entity-close/ee-infinity-pipe-100" })

    self.player_table.gui.infinity_pipe = nil
  end
end

function Gui:dispatch(msg, e)
  if msg.action then
    local handler = self[msg.action]
    if handler then
      handler(self, msg, e)
    end
  end
end

--- @param player_index uint
--- @param entity LuaEntity
function infinity_pipe.create_gui(player_index, entity)
  local player = game.get_player(player_index) --[[@as LuaPlayer]]
  local player_table = global.players[player_index]

  local radio_buttons = {}
  for _, mode in pairs(constants.infinity_pipe_modes) do
    local ref = string.gsub(mode, "%-", "_")
    table.insert(radio_buttons, {
      type = "radiobutton",
      caption = { "gui-infinity-container." .. mode },
      tooltip = { "gui-infinity-pipe." .. mode .. "-tooltip" },
      state = false,
      ref = { "amount_radio_buttons", ref },
      tags = { mode = mode },
      actions = {
        on_checked_state_changed = { gui = "infinity_pipe", action = "change_amount_mode", mode = mode },
      },
    })
    table.insert(radio_buttons, { type = "empty-widget", style = "flib_horizontal_pusher" })
  end
  -- Remove the last pusher
  radio_buttons[#radio_buttons] = nil

  -- Clean up disassociated GUI if one exists
  local existing = player.gui.screen["ee_infinity_pipe_window"]
  if existing then
    existing.destroy()
  end

  --- @type InfinityPipeGuiRefs
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      name = "ee_infinity_pipe_window",
      direction = "vertical",
      ref = { "window" },
      actions = { on_closed = { gui = "infinity_pipe", action = "destroy" } },
      {
        type = "flow",
        style = "flib_titlebar_flow",
        ref = { "titlebar_flow" },
        actions = { on_click = { gui = "infinity_pipe", action = "recenter" } },
        {
          type = "label",
          style = "frame_title",
          caption = { "entity-name.ee-infinity-pipe" },
          ignored_by_interaction = true,
        },
        { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
        util.close_button({ on_click = { gui = "infinity_pipe", action = "destroy" } }),
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
            style = "wide_entity_button",
            elem_mods = { entity = entity },
            ref = { "entity_preview" },
          },
        },
        {
          type = "flow",
          style_mods = { horizontal_spacing = 8, vertical_align = "center" },
          {
            type = "progressbar",
            style = "production_progressbar",
            style_mods = { horizontally_stretchable = true, bottom_margin = 2 },
            ref = { "amount_progressbar" },
          },
          { type = "label", caption = "/" },
          {
            type = "drop-down",
            items = table.map(shared_constants.infinity_pipe_capacities, function(capacity)
              return misc.delineate_number(capacity)
            end),
            selected_index = 0,
            ref = { "capacity_dropdown" },
            actions = {
              on_selection_state_changed = { gui = "infinity_pipe", action = "change_capacity" },
            },
          },
        },
        { type = "line", direction = "horizontal" },
        {
          type = "flow",
          style_mods = { vertical_align = "center" },
          direction = "horizontal",
          {
            type = "choose-elem-button",
            style = "flib_standalone_slot_button_default",
            elem_type = "fluid",
            ref = { "fluid_button" },
            actions = {
              on_elem_changed = { gui = "infinity_pipe", action = "change_fluid" },
            },
          },
          {
            type = "slider",
            style_mods = { horizontally_stretchable = true, margin = { 0, 8, 0, 8 } },
            minimum_value = 0,
            maximum_value = 1,
            value_step = 0.01,
            value = 0,
            ref = { "amount_slider" },
            actions = {
              on_value_changed = { gui = "infinity_pipe", action = "change_amount", elem = "slider" },
            },
          },
          {
            type = "textfield",
            style = "slider_value_textfield",
            numeric = true,
            allow_decimal = true,
            clear_and_focus_on_right_click = true,
            text = "0",
            ref = { "amount_textfield" },
            actions = {
              on_text_changed = { gui = "infinity_pipe", action = "change_amount", elem = "textfield" },
            },
          },
          {
            type = "drop-down",
            style_mods = { width = 55 },
            items = { { "gui-infinity-pipe.percent" }, { "gui-infinity-pipe.ee-units" } },
            selected_index = 1,
            ref = { "amount_type_dropdown" },
            actions = {
              on_selection_state_changed = { gui = "infinity_pipe", action = "change_amount_type" },
            },
          },
        },
        {
          type = "flow",
          style_mods = { horizontal_spacing = 0 },
          direction = "horizontal",
          children = radio_buttons,
        },
        { type = "line", direction = "horizontal" },
        {
          type = "flow",
          style_mods = { vertical_align = "center" },
          direction = "horizontal",
          { type = "label", caption = { "gui-infinity-pipe.temperature" } },
          {
            type = "slider",
            style_mods = { horizontally_stretchable = true, margin = { 0, 8, 0, 8 } },
            minimum_value = 0,
            maximum_value = 100,
            value = 0,
            ref = { "temperature_slider" },
            actions = {
              on_value_changed = { gui = "infinity_pipe", action = "change_temperature", elem = "slider" },
            },
          },
          {
            type = "textfield",
            style = "slider_value_textfield",
            clear_and_focus_on_right_click = true,
            text = "0",
            ref = { "temperature_textfield" },
            actions = {
              on_text_changed = { gui = "infinity_pipe", action = "change_temperature", elem = "textfield" },
            },
          },
        },
      },
    },
  })

  refs.window.force_auto_center()
  refs.titlebar_flow.drag_target = refs.window

  player.opened = refs.window

  local filter = entity.get_infinity_pipe_filter()

  --- @class InfinityPipeGui
  local self = {
    entity = entity,
    entity_unit_number = entity.unit_number,
    player = player,
    player_table = player_table,
    refs = refs,
    state = {
      amount_type = global.infinity_pipe_amount_types[entity.unit_number]
        or constants.infinity_pipe_amount_type.percent,
      capacity = entity.fluidbox.get_capacity(1),
      filter = filter,
      selected_mode = filter and filter.mode or "at-least",
    },
  }
  setmetatable(self, { __index = Gui })
  player_table.gui.infinity_pipe = self

  -- Set GUI state
  self:update()
  self:display_fluid_contents()
end

--- @param self InfinityPipeGui
function infinity_pipe.load_gui(self)
  setmetatable(self, { __index = Gui })
end

return infinity_pipe
