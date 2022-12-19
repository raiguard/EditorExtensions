--- @class PlayerData
local player_data = {}

local inventory_filters = require("__EditorExtensions__/scripts/inventory-filters")

--- @param player LuaPlayer
function player_data.init(player)
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

--- @param player LuaPlayer
--- @param player_table PlayerTable
function player_data.refresh(player, player_table)
  -- close any open GUIs
  for _, name in pairs({ "ia", "il", "sp" }) do
    if player_table.gui[name] then
      player_table.gui[name].refs.window.destroy()
      player_table.gui[name] = nil
    end
  end

  inventory_filters.string_gui.destroy(player)
  inventory_filters.relative_gui.build(player) -- Will destroy as well

  player.set_shortcut_available("ee-toggle-map-editor", player.admin)
end

return player_data
