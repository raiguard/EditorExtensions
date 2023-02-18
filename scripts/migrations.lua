local util = require("__EditorExtensions__/scripts/util")

local aggregate_chest = require("__EditorExtensions__/scripts/entity/aggregate-chest")
local infinity_pipe = require("__EditorExtensions__/scripts/entity/infinity-pipe")

local migrations = {}

function migrations.generic()
  aggregate_chest.update_data()
  aggregate_chest.update_all_filters()

  util.add_cursor_enhancements_overrides()

  for player_index in pairs(game.players) do
    migrations.migrate_player(player_index --[[@as uint]])
  end
end

--- @param player_index uint
function migrations.init_player(player_index)
  local player = game.get_player(player_index)
  if not player then
    return
  end
  -- TODO: Make this less monolithic
  --- @class PlayerTable
  local player_table = {
    flags = {
      map_editor_toggled = false,
      opening_default_gui = false, -- currently for super pump, but can be used generically
      update_character_cheats_when_possible = false,
    },
    gui = {},
    lab_state = nil,
    last_cleared_cursor_tick = 0,
    --- @type table<string, uint>
    linked_belt_render_objects = {},
    --- @type LuaEntity?
    linked_belt_source = nil,
    normal_state = nil,
    sync_data = nil,
  }
  global.players[player.index] = player_table

  if player.connected then
    player.print({ "message.ee-welcome" })
  end
end

--- @param player_index uint
function migrations.migrate_player(player_index)
  local player = game.get_player(player_index)
  if not player then
    return
  end
  inventory_filters.relative_gui.build(player)
  inventory_filters.string_gui.destroy(player)
  util.player_can_use_editor(player)
end

migrations.by_version = {
  ["2.0.0"] = function()
    -- FIXME:
    -- infinity_loader.init()
  end,
}

return migrations
