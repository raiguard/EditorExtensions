local infinity_pipe = {}

local gui = require("__flib__.gui")

local constants = require("scripts.constants")

-- -----------------------------------------------------------------------------
-- GUI

local ip_gui = {}

gui.add_handlers{
  ip = {
    close_button = {
      on_gui_click = function(e)
        ip_gui.destroy(game.get_player(e.player_index), global.players[e.player_index])
      end
    },
    window = {
      on_gui_closed = function(e)
        ip_gui.destroy(game.get_player(e.player_index), global.players[e.player_index])
      end
    }
  }
}

function ip_gui.create(player, player_table, entity)
  local gui_data = gui.build(player.gui.screen, {
    {type = "frame", direction = "vertical", handlers = "ip.window", save_as = "window", children = {
      {type = "flow", save_as = "titlebar.flow", children = {
        {
          type = "label",
          style = "frame_title",
          caption = {"entity-name.ee-infinity-pipe"},
          ignored_by_interaction = true
        },
        {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
        {
          type = "sprite-button",
          style = "frame_action_button",
          sprite = "utility/close_white",
          hovered_sprite = "utility/close_black",
          clicked_sprite = "utility/close_black",
          handlers = "ip.close_button"
        }
      }},
      {type = "frame", style = "inside_shallow_frame_with_padding", children = {
        {type = "frame", style = "deep_frame_in_shallow_frame", children = {
          {
            type = "entity-preview",
            style_mods = {width = 100, height = 100},
            elem_mods = {entity = entity},
            save_as="preview"
          }
        }},
        {type = "flow", direction = "vertical", children = {
          {type = "empty-widget", style_mods = {height = 100, width = 300}}
        }}
      }}
    }}
  })

  gui_data.titlebar.flow.drag_target = gui_data.window
  gui_data.window.force_auto_center()

  gui_data.entity = entity

  player.opened = gui_data.window

  player_table.gui.ip = gui_data

  player.play_sound{path="entity-open/ee-infinity-pipe"}
end

function ip_gui.destroy(player, player_table)
  player_table.gui.ip.window.destroy()
  player_table.gui.ip = nil
  player.opened = nil
  player.play_sound{path="entity-close/ee-infinity-pipe"}
end

-- -----------------------------------------------------------------------------
-- PUBLIC FUNCTIONS

function infinity_pipe.open(player_index, entity)
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]
  ip_gui.create(player, player_table, entity)
end

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
                  entity.set_infinity_pipe_filter{name = fluid, percentage = 1, mode = "at-least"}
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