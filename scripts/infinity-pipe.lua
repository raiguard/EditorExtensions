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

--- @type table<string, uint>
local defines_amount_type = {
  percent = 1,
  units = 2,
}

--- @param entity LuaEntity
--- @param amount_type uint?
local function store_amount_type(entity, amount_type)
  global.infinity_pipe_amount_type[entity.unit_number] = amount_type
end

--- @param entity LuaEntity
--- @return uint?
local function get_stored_amount_type(entity)
  return global.infinity_pipe_amount_type[entity.unit_number]
end

--- @param entity LuaEntity
--- @return uint?
local function remove_stored_amount_type(entity)
  local value = global.infinity_pipe_amount_type[entity.unit_number]
  global.infinity_pipe_amount_type[entity.unit_number] = nil
  return value
end

--- @param entity LuaEntity
--- @param new_capacity double
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
  store_amount_type(new_entity, amount_type)
  return new_entity
end

--- @param entity BlueprintEntity|LuaEntity
local function check_is_our_pipe(entity)
  return string.find(entity.name, "^ee%-infinity%-pipe%-%d+$")
end

--- @param entity LuaEntity
local function snap(entity)
  local own_id = entity.unit_number
  for _, fluidbox in pairs(entity.fluidbox.get_connections(1)) do
    if crafter_snapping_types[fluidbox.owner.type] then
      for i = 1, #fluidbox do
        --- @cast i uint
        local connections = fluidbox.get_connections(i)
        local prototype = fluidbox.get_prototype(i)
        for j = 1, #connections do
          if prototype.production_type == "input" and connections[j].owner.unit_number == own_id then
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
local function update_fluid_content_bar(self)
  if not self.entity.valid then
    return
  end
  local bar = self.elems.amount_progressbar
  local fluidbox = self.entity.fluidbox
  local capacity = fluidbox.get_capacity(1)
  local content = fluidbox[1] or { amount = 0 }

  local caption
  if content.amount < 100 then
    caption = string.format("%.1f", content.amount)
  else
    caption = format.number(math.floor(content.amount))
  end
  bar.caption = caption
  bar.value = content.amount / capacity

  if not content.name then
    return
  end

  local bar_color = game.fluid_prototypes[content.name].base_color
  -- Calculate luminance of the background color
  -- Source: https://stackoverflow.com/questions/596216/formula-to-determine-perceived-brightness-of-rgb-color
  local luminance = (0.2126 * bar_color.r) + (0.7152 * bar_color.g) + (0.0722 * bar_color.b)
  if luminance > 0.55 then
    bar.style = "ee_infinity_pipe_progressbar"
  else
    bar.style = "ee_infinity_pipe_progressbar_light_text"
  end
  bar.style.color = bar_color
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

  local amount_type = get_stored_amount_type(entity) or 1
  elems.amount_slider.slider_value = filter.percentage or 0
  elems.amount_textfield.style = "ee_slider_textfield"
  local percentage = filter.percentage or 0
  if amount_type == defines_amount_type.percent then
    elems.amount_textfield.text = tostring(math.floor(percentage * 100))
  else
    elems.amount_textfield.text = tostring(math.floor(percentage * capacity))
  end
  elems.amount_type_dropdown.selected_index = amount_type

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

  update_fluid_content_bar(self)
end

--- @param entity LuaEntity
local function destroy_all_guis(entity)
  for player_index, gui in pairs(global.infinity_pipe_gui) do
    if not gui.entity.valid or gui.entity == entity then
      destroy_gui(player_index)
    end
  end
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
    local max = 100
    local amount_type = get_stored_amount_type(entity)
    if amount_type == defines_amount_type.units then
      max = entity.fluidbox.get_capacity(1)
    end
    if not value or value < 0 or value > max then
      textfield.style = "ee_invalid_slider_textfield"
      return
    end
    textfield.style = "ee_slider_textfield"

    local percentage = value / 100
    if amount_type == defines_amount_type.units then
      local capacity = entity.fluidbox.get_capacity(1)
      percentage = value / capacity
    end

    self.elems.amount_slider.slider_value = percentage

    local filter = entity.get_infinity_pipe_filter()
    if filter then
      filter.percentage = percentage
      entity.set_infinity_pipe_filter(filter)
      update_all_guis(entity)
    end
  end,

  --- @param self InfinityPipeGui
  --- @param e EventData.on_gui_selection_state_changed
  on_ip_gui_amount_type_changed = function(self, e)
    local amount_type = e.element.selected_index
    store_amount_type(self.entity, amount_type)
    update_all_guis(self.entity)
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

  --- @param self InfinityPipeGui
  --- @param e EventData.on_gui_value_changed
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

  --- @param self InfinityPipeGui
  --- @param e EventData.on_gui_text_changed
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
          style = "ee_infinity_pipe_progressbar",
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
          handler = { [defines.events.on_gui_selection_state_changed] = handlers.on_ip_gui_amount_type_changed },
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

-- COPY/PASTE

--- @param pipe LuaEntity
--- @param combinator LuaEntity
local function copy_from_pipe_to_combinator(pipe, combinator)
  local filter = pipe.get_infinity_pipe_filter()
  if not filter then
    return
  end
  local cb = combinator.get_or_create_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
  cb.set_signal(1, {
    signal = { type = "fluid", name = filter.name },
    count = 1,
  })
  update_all_guis(pipe)
end

--- @param combinator LuaEntity
--- @param pipe LuaEntity
local function copy_from_combinator_to_pipe(combinator, pipe)
  local cb = combinator.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior?]]
  if not cb then
    return
  end
  local signal = cb.get_signal(1)
  if signal.signal and signal.signal.type == "fluid" then
    pipe.set_infinity_pipe_filter({ type = "fluid", name = signal.signal.name, percentage = 1 })
  else
    pipe.set_infinity_pipe_filter(nil)
  end
  update_all_guis(pipe)
end

--- @param source LuaEntity
--- @param destination LuaEntity
local function copy_from_pipe_to_pipe(source, destination)
  if source.name ~= destination.name then
    local new_destination = swap_entity(destination, source.fluidbox.get_capacity(1))
    if not new_destination then
      return
    end
    destination = new_destination
  end
  local source_amount_type = get_stored_amount_type(source)
  local destination_amount_type = get_stored_amount_type(destination)
  if source_amount_type ~= destination_amount_type then
    store_amount_type(destination, source_amount_type)
  end
  update_all_guis(destination)
end

-- EVENTS

--- @param e BuiltEvent
local function on_entity_built(e)
  local entity = e.created_entity or e.entity or e.destination
  if not entity or not entity.valid or not check_is_our_pipe(entity) then
    return
  end

  local tags = e.tags
  if tags and tags.EditorExtensions then
    store_amount_type(entity, tags.EditorExtensions.amount_type --[[@as uint]])
  end

  if e.name == defines.events.on_built_entity then
    snap(entity)
  end
end

--- @param e DestroyedEvent
local function on_entity_destroyed(e)
  local entity = e.entity
  if not entity.valid or not check_is_our_pipe(entity) then
    return
  end
  remove_stored_amount_type(e.entity)
  destroy_all_guis(entity)
end

--- @param e EventData.on_gui_opened
local function on_gui_opened(e)
  local entity = e.entity
  if not entity or not entity.valid or not check_is_our_pipe(entity) then
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
  local blueprint = util.get_blueprint(e)
  if not blueprint then
    return
  end

  local entities = blueprint.get_blueprint_entities()
  if not entities then
    return
  end
  for i, entity in pairs(entities) do
    --- @cast i uint
    if not check_is_our_pipe(entity) then
      goto continue
    end
    local real_entity = e.surface.find_entity(entity.name, entity.position)
    if not real_entity then
      goto continue
    end
    blueprint.set_blueprint_entity_tag(
      i,
      "EditorExtensions",
      { amount_type = global.infinity_pipe_amount_type[real_entity.unit_number] }
    )
    ::continue::
  end
end

--- @param e EventData.on_entity_settings_pasted
local function on_entity_settings_pasted(e)
  local source, destination = e.source, e.destination
  if not source.valid or not destination.valid then
    return
  end
  local source_is_pipe, destination_is_pipe = check_is_our_pipe(source), check_is_our_pipe(destination)
  if source_is_pipe and destination.name == "constant-combinator" then
    copy_from_pipe_to_combinator(source, destination)
  elseif source.name == "constant-combinator" and destination_is_pipe then
    copy_from_combinator_to_pipe(source, destination)
  elseif source_is_pipe and destination_is_pipe then
    copy_from_pipe_to_pipe(source, destination)
  end
end

local infinity_pipe = {}

infinity_pipe.on_init = function()
  --- @type table<uint, InfinityPipeGui>
  global.infinity_pipe_gui = {}
  --- @type table<uint, uint>
  global.infinity_pipe_amount_type = {}
end

infinity_pipe.on_configuration_changed = function()
  for player_index in pairs(game.players) do
    destroy_gui(player_index --[[@as uint]])
  end
end

infinity_pipe.events = {
  [defines.events.on_built_entity] = on_entity_built,
  [defines.events.on_entity_cloned] = on_entity_built,
  [defines.events.on_entity_died] = on_entity_destroyed,
  [defines.events.on_entity_settings_pasted] = on_entity_settings_pasted,
  [defines.events.on_gui_opened] = on_gui_opened,
  [defines.events.on_player_mined_entity] = on_entity_destroyed,
  [defines.events.on_player_setup_blueprint] = on_player_setup_blueprint,
  [defines.events.on_robot_built_entity] = on_entity_built,
  [defines.events.on_robot_mined_entity] = on_entity_destroyed,
  [defines.events.script_raised_built] = on_entity_built,
  [defines.events.script_raised_destroy] = on_entity_destroyed,
  [defines.events.script_raised_revive] = on_entity_built,
}

infinity_pipe.on_nth_tick = {
  [1] = function()
    for _, gui in pairs(global.infinity_pipe_gui) do
      update_fluid_content_bar(gui)
    end
  end,
}

return infinity_pipe
