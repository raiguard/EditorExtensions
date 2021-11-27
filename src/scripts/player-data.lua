local player_data = {}

local constants = require("scripts.constants")
local inventory = require("scripts.inventory")

function player_data.init(player)
  --- @class PlayerTable
  local player_table = {
    flags = {
      map_editor_toggled = false,
      opening_default_gui = false, -- currently for super pump, but can be used generically
      update_character_cheats_when_possible = false,
    },
    gui = {},
    last_cleared_cursor_tick = 0,
    linked_belt_render_objects = {},
    linked_belt_source = nil,
  }
  global.players[player.index] = player_table

  player_data.refresh(player, player_table)
end

function player_data.update_settings(player, player_table)
  local player_settings = player.mod_settings
  local settings = {}
  for prototype, internal in pairs(constants.setting_names) do
    if internal == "testing_lab" then
      settings[internal] = constants.testing_lab_setting[player_settings[prototype].value]
    else
      settings[internal] = player_settings[prototype].value
    end
  end
  player_table.settings = settings
end

function player_data.refresh(player, player_table)
  -- close any open GUIs
  for _, name in ipairs({ "ia", "il", "sp" }) do
    if player_table.gui[name] then
      player_table.gui[name].refs.window.destroy()
      player_table.gui[name] = nil
    end
  end

  -- recreate inventory filters buttons
  inventory.destroy_filters_buttons(player_table)
  inventory.create_filters_buttons(player, player_table)

  -- set shortcut availability
  player.set_shortcut_available("ee-toggle-map-editor", player.admin)

  -- update settings
  player_data.update_settings(player, player_table)
end

return player_data
