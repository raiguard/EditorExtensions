local player_data = {}

local gui = require("__flib__.gui")

local string = string

function player_data.init(index)
  local player_table = {
    flags = {
      in_satellite_view = false, -- space exploration compatibility
      inventory_sync_enabled = false,
      map_editor_toggled = false
    },
    gui = {}
  }
  global.players[index] = player_table

  player_data.refresh(game.get_player(index), global.players[index])
end

function player_data.update_settings(player, player_table)
  local settings = {}
  for name, t in pairs(player.mod_settings) do
    if string.sub(name, 1,3) == "ee-" then
      name = string.gsub(name, "^ee%-", "")
      settings[string.gsub(name, "%-", "_")] = t.value
    end
  end
  player_table.settings = settings
end

function player_data.refresh(player, player_table)
  -- close any open GUIs
  for _, name in ipairs{"ia", "il"} do
    if player_table.gui[name] then
      player_table.gui[name].window.destroy()
      gui.update_filters(name, player.index, nil, "remove")
      player_table.gui[name] = nil
    end
  end

  -- set shortcut availability
  player.set_shortcut_available("ee-toggle-map-editor", player.admin)

  -- update settings
  player_data.update_settings(player, player_table)
end

return player_data