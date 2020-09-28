local super_pump = {}

local gui = require("__flib__.gui")

-- -----------------------------------------------------------------------------
-- GUI

local function create_gui(player, player_table, entity)
  local elems = gui.build(player.gui.screen, {
    {type = "frame", direction = "vertical", handlers = "sp.window", save_as = "window", children = {
      {type = "flow", save_as = "titlebar_flow", children = {
        {type = "label", style = "frame_title", caption = {"entity-name.ee-super-pump"}, ignored_by_interaction = true},
        {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
        {template = "close_button", handlers = "sp.close_button"}
      }},
      {type = "frame", style = "inside_shallow_frame_with_padding", children = {
        {type = "frame", style = "deep_frame_in_shallow_frame", children = {
          {
            type = "entity-preview",
            style_mods = {width = 100, height = 100},
            elem_mods = {entity = entity},
            save_as = "preview"
          }
        }}
      }}
    }}
  })

  -- dragging and centering
  elems.titlebar_flow.drag_target = elems.window
  elems.window.force_auto_center()

  -- save to player table
  player_table.gui.sp = {
    entity = entity,
    elems = elems
  }

  -- mark as opened
  player.opened = elems.window

  -- play opened sound
  player.play_sound{path = "entity-open/ee-super-pump"}
end

local function destroy_gui(player, player_table)
  local gui_data = player_table.gui.sp
  gui_data.elems.window.destroy()
  player_table.gui.sp = nil

  if player.opened == gui_data.entity then
    player.opened = nil
  end

  player.play_sound{path = "entity-close/ee-super-pump"}
end

gui.add_handlers{
  sp = {
    close_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        destroy_gui(player, player_table)
      end
    },
    window = {
      on_gui_closed = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        destroy_gui(player, player_table)
      end
    }
  }
}

-- -----------------------------------------------------------------------------
-- EXTERNAL FUNCTIONS

function super_pump.open(player_index, entity)
  -- TODO check for other GUI
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]
  create_gui(player, player_table, entity)
end

return super_pump