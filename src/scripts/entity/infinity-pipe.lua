local gui = require("__flib__.gui")
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
--- @field entity_preview LuaGuiElement

--- @type InfinityPipeGui
local Gui = {}

Gui.actions = {}

--- @param Gui InfinityPipeGui
function Gui.actions.close(Gui, _, _)
  Gui:destroy()
end

--- @param Gui InfinityPipeGui
--- @param e on_gui_selection_state_changed
function Gui.actions.change_capacity(Gui, _, e)
  local selected_capacity = shared_constants.infinity_pipe_capacities[e.element.selected_index]
  local new_name = "ee-infinity-pipe-" .. selected_capacity
  if not game.entity_prototypes[new_name] then
    return
  end

  local entity = Gui.entity
  if not entity or not entity.valid then
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
    Gui.entity = new_entity
    Gui.refs.entity_preview.entity = new_entity

    -- TODO: Absolute filling migration
  end
end

function Gui:destroy()
  if self.refs.window.valid then
    self.refs.window.destroy()
    self.player.opened = nil
    self.player.play_sound({ path = "entity-close/ee-infinity-pipe-100" })
  end
end

function Gui:dispatch(msg, e)
  if msg.action then
    local handler = self.actions[msg.action]
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

  --- @type InfinityPipeGuiRefs
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      ref = { "window" },
      actions = { on_closed = { gui = "infinity_pipe", action = "close" } },
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
        util.close_button({ on_click = { gui = "infinity_pipe", action = "close" } }),
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
          style_mods = { vertical_align = "center" },
          { type = "label", caption = "Capacity" },
          { type = "empty-widget", style = "flib_horizontal_pusher" },
          {
            type = "drop-down",
            items = table.map(shared_constants.infinity_pipe_capacities, function(capacity)
              return misc.delineate_number(capacity)
            end),
            selected_index = 1,
            actions = {
              on_selection_state_changed = { gui = "infinity_pipe", action = "change_capacity" },
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
    state = {},
  }
  setmetatable(self, { __index = Gui })
  player_table.gui.infinity_pipe = self
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
