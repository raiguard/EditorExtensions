local player_data = {}

local gui = require("__flib__.gui")

local constants = require("scripts.constants")

function player_data.init(index)
  local player_table = {
    flags = {
      update_character_cheats_when_possible = false,
      map_editor_toggled = false,
      opening_default_gui = false -- currently for super pump, but can be used generically
    },
    gui = {}
  }
  global.players[index] = player_table

  player_data.refresh(game.get_player(index), global.players[index])
end

function player_data.update_settings(player, player_table)
  local player_settings = player.mod_settings
  local settings = {}
  for prototype, internal in pairs(constants.setting_names) do
    settings[internal] = player_settings[prototype].value
  end
  player_table.settings = settings
end

function player_data.refresh(player, player_table)
  -- close any open GUIs
  for _, name in ipairs{"ia", "il", "sp"} do
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