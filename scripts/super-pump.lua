local gui = require("__flib__/gui-lite")
local math = require("__flib__/math")
local table = require("__flib__/table")

local util = require("__EditorExtensions__/scripts/util")

--- @param entity LuaEntity
--- @param speed double
local function set_speed(entity, speed)
  entity.fluidbox[2] = {
    name = "ee-super-pump-speed-fluid",
    amount = 100000000000,
    temperature = speed + 0.01, -- avoid floating point imprecision
  }
end

--- @param entity LuaEntity
local function get_speed(entity)
  return math.floor(entity.fluidbox[2].temperature)
end

local slider_to_temperature = {
  [0] = 0,
  [1] = 100,
  [2] = 200,
  [3] = 300,
  [4] = 400,
  [5] = 500,
  [6] = 600,
  [7] = 700,
  [8] = 800,
  [9] = 900,
  [10] = 1000,
  [11] = 2000,
  [12] = 3000,
  [13] = 4000,
  [14] = 5000,
  [15] = 6000,
  [16] = 7000,
  [17] = 8000,
  [18] = 9000,
  [19] = 10000,
  [20] = 15000,
  [21] = 20000,
  [22] = 25000,
  [23] = 30000,
}
local temperature_to_slider = table.invert(slider_to_temperature)

--- @param speed double
--- @return double
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
  return temperature_to_slider[index]
end

--- @param value double
--- @return double
local function from_slider_value(value)
  return slider_to_temperature[value]
end

--- @param entity LuaEntity
--- @param flow LuaGuiElement
local function update_gui(entity, flow)
  local speed = get_speed(entity)

  local textfield = flow.speed_textfield --[[@as LuaGuiElement]]
  textfield.style = "ee_slider_textfield"
  textfield.text = tostring(speed)

  local slider = flow.speed_slider --[[@as LuaGuiElement]]
  slider.slider_value = to_slider_value(speed)
end

local handlers = {
  --- @param entity LuaEntity
  --- @param e EventData.on_gui_value_changed
  on_pump_speed_slider_value_changed = function(entity, e)
    local new_speed = from_slider_value(e.element.slider_value)
    set_speed(entity, new_speed)
    update_gui(entity, e.element.parent)
  end,

  --- @param entity LuaEntity
  --- @param e EventData.on_gui_text_changed
  on_pump_speed_textfield_changed = function(entity, e)
    local textfield = e.element
    local text = textfield.text
    local speed = tonumber(text)

    if not speed or speed > 600000 then
      textfield.style = "ee_invalid_slider_textfield"
      return
    end

    set_speed(entity, speed)
    update_gui(entity, e.element.parent)
  end,
}

gui.add_handlers(handlers, function(e, handler)
  local player = game.get_player(e.player_index)
  if not player or player.opened_gui_type ~= defines.gui_type.entity then
    return
  end
  local entity = player.opened
  if not entity or not entity.valid then
    return
  end
  if entity.name ~= "ee-super-pump" then
    return
  end
  handler(entity, e)
end)

--- @param player LuaPlayer
local function create_gui(player)
  local existing = player.gui.relative.ee_super_pump_window
  if existing then
    existing.destroy()
  end

  gui.add(player.gui.relative, {
    type = "frame",
    name = "ee_super_pump_window",
    style = "frame_with_even_paddings",
    style_mods = { width = 448 },
    anchor = {
      gui = defines.relative_gui_type.entity_with_energy_source_gui,
      position = defines.relative_gui_position.bottom,
      name = "ee-super-pump",
    },
    {
      type = "frame",
      name = "inner_frame",
      style = "inside_shallow_frame_with_padding",
      {
        type = "flow",
        name = "inner_flow",
        style = "centering_horizontal_flow",
        { type = "label", caption = { "gui.ee-speed" }, tooltip = { "gui.ee-speed-tooltip" } },
        {
          type = "slider",
          name = "speed_slider",
          style_mods = { horizontally_stretchable = true, margin = { 0, 8, 0, 8 } },
          minimum_value = 0,
          maximum_value = 23,
          value = 0,
          handler = { [defines.events.on_gui_value_changed] = handlers.on_pump_speed_slider_value_changed },
        },
        {
          type = "textfield",
          name = "speed_textfield",
          style = "ee_slider_textfield",
          numeric = true,
          clear_and_focus_on_right_click = true,
          handler = { [defines.events.on_gui_text_changed] = handlers.on_pump_speed_textfield_changed },
        },
      },
    },
  })
end

--- @param e BuiltEvent
local function on_entity_built(e)
  local entity = e.created_entity or e.entity or e.destination
  if not entity or not entity.valid or entity.name ~= "ee-super-pump" then
    return
  end
  local speed = 12000
  local tags = e.tags
  if tags and tags.EditorExtensions then
    speed = tags.EditorExtensions.speed --[[@as double]]
  end
  set_speed(entity, speed)
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
    if entity.name ~= "ee-super-pump" then
      goto continue
    end
    local real_entity = e.surface.find_entity(entity.name, entity.position)
    if not real_entity then
      goto continue
    end
    blueprint.set_blueprint_entity_tag(i, "EditorExtensions", { speed = get_speed(real_entity) })
    ::continue::
  end
end

local function on_entity_settings_pasted(e)
  local source, destination = e.source, e.destination
  if not source.valid or not destination.valid then
    return
  end
  if source.name ~= "ee-super-pump" or destination.name ~= "ee-super-pump" then
    return
  end
  set_speed(destination, get_speed(source))
end

--- @param e EventData.on_gui_opened
local function on_gui_opened(e)
  local player = game.get_player(e.player_index)
  if not player or player.opened_gui_type ~= defines.gui_type.entity then
    return
  end
  local entity = e.entity
  if not entity or not entity.valid then
    return
  end
  if entity.name ~= "ee-super-pump" then
    return
  end

  update_gui(entity, player.gui.relative.ee_super_pump_window.inner_frame.inner_flow)
end

--- @param e EventData.on_player_created
local function on_player_created(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  create_gui(player)
end

local super_pump = {}

super_pump.on_configuration_changed = function()
  for _, player in pairs(game.players) do
    create_gui(player)
  end
end

super_pump.events = {
  [defines.events.on_built_entity] = on_entity_built,
  [defines.events.on_entity_cloned] = on_entity_built,
  [defines.events.on_entity_settings_pasted] = on_entity_settings_pasted,
  [defines.events.on_gui_opened] = on_gui_opened,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_setup_blueprint] = on_player_setup_blueprint,
  [defines.events.on_robot_built_entity] = on_entity_built,
  [defines.events.script_raised_built] = on_entity_built,
  [defines.events.script_raised_revive] = on_entity_built,
}

return super_pump
