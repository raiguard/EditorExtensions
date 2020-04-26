local data = {}

local cheat_mode = require("scripts.cheat-mode")

local string_gsub = string.gsub
local string_sub = string.sub

function data.setup_player(index)
  local player_data = {
    flags = {
      inventory_sync_enabled = false,
      map_editor_toggled = false
    },
    gui = {
      ic = {
        network_color = "red",
        sort_mode = "numerical",
        sort_direction = "descending",
        update_divider = 30
      }
    }
  }
  global.players[index] = player_data
end

function data.update_player_settings(player, player_table)
  local settings = {}
  for name,  t in pairs(player.mod_settings) do
    if string_sub(name, 1,3) == "ee-" then
      name = string_gsub(name, "^ee%-", "")
      settings[string_gsub(name, "%-", "_")] = t.value
    end
  end
  player_table.settings = settings
end

function data.refresh_player(player, player_table)
  -- close any open GUIs
  for _, name in ipairs{"ia", "il"} do
    if player_table.gui[name] then
      player_table.gui[name].window.destroy()
      player_table.gui[name] = nil
    end
  end

  -- set shortcut availability
  player.set_shortcut_available("ee-toggle-map-editor", player.admin)

  -- update settings
  data.update_player_settings(player, player_table)
end

function data.init()
  global.combinators = {}
  global.flags = {
    map_editor_toggled = false
  }
  global.players = {}
  for i, p in pairs(game.players) do
    data.setup_player(i)
    data.refresh_player(p, global.players[i])
    if p.cheat_mode then
      cheat_mode.enable_recipes(p)
    end
  end
  global.wagons = {}
end

return data