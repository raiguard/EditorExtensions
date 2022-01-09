local gui = require("__flib__.gui")
local math = require("__flib__.math")
local misc = require("__flib__.misc")
local table = require("__flib__.table")

local shared_constants = require("shared-constants")

local constants = require("scripts.constants")
local util = require("scripts.util")

local infinity_pipe = {}

-- GUI

--- @class InfinityPipeGuiRefs
--- @field window LuaGuiElement
--- @field titlebar_flow LuaGuiElement
--- @field drag_handle LuaGuiElement
--- @field amount_progressbar LuaGuiElement
--- @field entity_preview LuaGuiElement
--- @field fluid_button LuaGuiElement
--- @field amount_slider LuaGuiElement
--- @field amount_textfield LuaGuiElement
--- @field amount_radio_buttons table<string, LuaGuiElement>
--- @field temperature_slider LuaGuiElement
--- @field temperature_textfield LuaGuiElement

--- @type InfinityPipeGui
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

  local new_entity = entity.surface.create_entity({
    name = new_name,
    position = entity.position,
    direction = entity.direction,
    force = entity.force,
    fast_replace = true,
    create_build_effect_smoke = false,
    spill = false,
  })

  if new_entity then
    self.entity = new_entity
    self.refs.entity_preview.entity = new_entity
    self.state.capacity = new_capacity

    -- TODO: Absolute filling migration
  end
end

function Gui:change_fluid()
  local fluid_name = self.refs.fluid_button.elem_value
  local filter = self.entity.get_infinity_pipe_filter()

  local min_temp, max_temp, temperature, amount
  if fluid_name then
    local prototype = game.fluid_prototypes[fluid_name]
    if filter then
      -- Changed fluids
      filter.name = fluid_name
      filter.temperature = prototype.default_temperature
    else
      -- Added fluid
      -- TODO: Amount type
      filter = {
        name = fluid_name,
        -- Default to 100% like the vanilla infinity pipe
        percentage = 1,
        temperature = prototype.default_temperature,
        mode = self.state.selected_mode,
      }
    end
    min_temp = prototype.default_temperature
    max_temp = prototype.max_temperature
    amount = filter.percentage * 100
    temperature = filter.temperature
  elseif filter then
    -- Removed fluid
    filter = nil
    min_temp = 0
    max_temp = 100
    amount = 0
    temperature = 0
  else
    -- Just opened the GUI with no fluid
    return
  end

  -- Update amount
  self.state.amount = amount
  self.refs.amount_slider.slider_value = amount
  self.refs.amount_textfield.text = tostring(amount)
  self.refs.amount_textfield.style = "slider_value_textfield"

  -- Update temperature
  self.state.temperature = temperature
  local slider = self.refs.temperature_slider
  local textfield = self.refs.temperature_textfield
  if min_temp == max_temp then
    slider.enabled = false
    textfield.enabled = false
  else
    slider.enabled = true
    slider.set_slider_minimum_maximum(min_temp, max_temp)
    slider.slider_value = temperature
    textfield.enabled = true
  end
  textfield.style = "slider_value_textfield"
  textfield.text = tostring(temperature)

  -- Update filter
  self.entity.set_infinity_pipe_filter(filter)
end

--- @param msg table
--- @param e on_gui_value_changed|on_gui_text_changed
function Gui:change_amount(msg, e)
  local element = e.element
  local type = msg.elem
  local new_amount
  if type == "slider" then
    new_amount = element.slider_value
    self.refs.amount_textfield.text = tostring(new_amount)
    self.refs.amount_textfield.style = "slider_value_textfield"
    self.state.amount = new_amount
  else
    new_amount = tonumber(element.text)
    -- TODO: Amount type
    if new_amount and new_amount <= 100 then
      element.style = "slider_value_textfield"
      self.refs.amount_slider.slider_value = new_amount
      self.state.amount = new_amount
    else
      element.style = "ee_invalid_slider_value_textfield"
      return
    end
  end

  local filter = self.entity.get_infinity_pipe_filter()
  if filter then
    -- TODO: Amount type
    filter.percentage = new_amount / 100

    self.entity.set_infinity_pipe_filter(filter)
  end
end

--- @param e on_gui_confirmed
function Gui:confirm_amount(_, e)
  e.element.text = tostring(self.state.amount)
  e.element.style = "slider_value_textfield"
end

function Gui:change_amount_type(msg, e) end

--- @param msg table
function Gui:change_amount_mode(msg)
  local to_mode = msg.mode

  for _, button in pairs(self.refs.amount_radio_buttons) do
    button.state = gui.get_tags(button).mode == to_mode
  end

  self.state.selected_mode = to_mode

  local filter = self.entity.get_infinity_pipe_filter()
  if not filter then
    return
  end
  filter.mode = to_mode
  self.entity.set_infinity_pipe_filter(filter)
end

function Gui:change_temperature(msg, e)
  local element = e.element
  local type = msg.elem
  local new_temperature
  if type == "slider" then
    new_temperature = element.slider_value
    self.refs.temperature_textfield.text = tostring(new_temperature)
    self.refs.temperature_textfield.style = "slider_value_textfield"
    self.state.temperature = new_temperature
  else
    new_temperature = tonumber(element.text)
    local slider = self.refs.temperature_slider
    if
      new_temperature
      and new_temperature >= slider.get_slider_minimum()
      and new_temperature <= slider.get_slider_maximum()
    then
      element.style = "slider_value_textfield"
      slider.slider_value = new_temperature
      self.state.temperature = new_temperature
    else
      element.style = "ee_invalid_slider_value_textfield"
      return
    end
  end

  local filter = self.entity.get_infinity_pipe_filter()
  if filter then
    filter.temperature = new_temperature

    self.entity.set_infinity_pipe_filter(filter)
  end
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
  progressbar.caption = misc.delineate_number(math.round_to(fluid_amount, 2))

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

--- @param player_index number
--- @param entity LuaEntity
function infinity_pipe.create_gui(player_index, entity)
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]

  local filter = entity.get_infinity_pipe_filter() or { mode = "at-least" }

  local capacity = entity.fluidbox.get_capacity(1)

  local radio_buttons = {}
  for _, mode in pairs(constants.infinity_pipe_modes) do
    local ref = string.gsub(mode, "%-", "_")
    table.insert(radio_buttons, {
      type = "radiobutton",
      caption = { "gui-infinity-container." .. mode },
      tooltip = { "gui-infinity-pipe." .. mode .. "-tooltip" },
      state = filter.mode == mode,
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

  --- @type InfinityPipeGuiRefs
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
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
          -- { type = "label", caption = { "description.fluid-capacity" } },
          -- { type = "empty-widget", style = "flib_horizontal_pusher" },
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
            selected_index = table.find(shared_constants.infinity_pipe_capacities, capacity),
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
            fluid = filter.name,
            ref = { "fluid_button" },
            actions = {
              on_elem_changed = { gui = "infinity_pipe", action = "change_fluid" },
            },
          },
          {
            type = "slider",
            style_mods = { horizontally_stretchable = true, margin = { 0, 8, 0, 8 } },
            minimum_value = 0,
            maximum_value = 100,
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
            clear_and_focus_on_right_click = true,
            lose_focus_on_confirm = true,
            text = "0",
            ref = { "amount_textfield" },
            actions = {
              on_confirmed = { gui = "infinity_pipe", action = "confirm_amount" },
              on_text_changed = { gui = "infinity_pipe", action = "change_amount", elem = "textfield" },
            },
          },
          {
            type = "drop-down",
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
            text = 0,
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

  --- @class InfinityPipeGui
  local self = {
    entity = entity,
    player = player,
    player_table = player_table,
    refs = refs,
    state = {
      amount = 0,
      capacity = capacity,
      selected_mode = filter.mode,
      temperature = filter.default_temperature or 0,
    },
  }
  setmetatable(self, { __index = Gui })
  player_table.gui.infinity_pipe = self

  -- Set GUI state
  self:change_fluid()
  self:display_fluid_contents()
end

--- @param self InfinityPipeGui
function infinity_pipe.load_gui(self)
  setmetatable(self, { __index = Gui })
end

-- ENTITY

-- TODO: Move the player setting check out of here?
--- @param entity LuaEntity
--- @param player_settings table
function infinity_pipe.snap(entity, player_settings)
  local own_id = entity.unit_number

  if player_settings.infinity_pipe_crafter_snapping then
    for _, fluidbox in ipairs(entity.fluidbox.get_connections(1)) do
      local owner_type = fluidbox.owner.type
      if constants.ip_crafter_snapping_types[owner_type] then
        for i = 1, #fluidbox do
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

return infinity_pipe
