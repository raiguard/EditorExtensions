local gui = require("__flib__.gui")

local constants = require("scripts.constants")
local util = require("scripts.util")

local infinity_pipe = {}

-- GUI

--- @class InfinityPipeGui
local Gui = {}

Gui.actions = {}

function Gui.actions.close(Gui, _, _)
  Gui:destroy()
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
        { type = "empty-widget", style = "flib_titlebar_drag_handle" },
        util.close_button({ on_click = { gui = "infinity_pipe", action = "close" } }),
      },
      {
        type = "frame",
        style = "entity_frame",
        direction = "vertical",
        {
          type = "frame",
          style = "deep_frame_in_shallow_frame",
          { type = "entity-preview", style = "wide_entity_button", elem_mods = { entity = entity } },
        },
        {
          type = "flow",
          style_mods = { vertical_align = "center" },
          { type = "label", caption = "Capacity" },
          { type = "empty-widget", style = "flib_horizontal_pusher" },
          {
            type = "drop-down",
            items = { "100", "500", "1,000", "5,000", "10,000", "25,000", "100,000" },
            selected_index = 1,
          },
        },
      },
    },
  })

  refs.window.force_auto_center()
  refs.titlebar_flow.drag_target = refs.window

  player.opened = refs.window

  --- @type InfinityPipeGui
  local self = {
    entity = entity,
    player = player,
    player_table = player_table,
    refs = refs,
    state = {},
  }
  -- TODO: Restore during on_load
  setmetatable(self, { __index = Gui })
  player_table.gui.infinity_pipe = self
end

-- ENTITY

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
