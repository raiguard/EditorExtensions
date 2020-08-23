local gui = require("__flib__.gui")

local cheat_mode = require("scripts.cheat-mode")

return {
  ["1.1.0"] = function()
    -- enable infinity equipment recipes, hide electric energy interface recipe
    for _, force in pairs(game.forces) do
      local recipes = force.recipes
      if recipes["ee-infinity-loader"].enabled then
        recipes["electric-energy-interface"].enabled = false
        recipes["ee-super-exoskeleton-equipment"].enabled = true
        recipes["ee-infinity-fusion-reactor-equipment"].enabled = true
        recipes["ee-super-personal-roboport-equipment"].enabled = true
      end
    end
    -- enable recipes for any players who already have cheat mode enabled
    for _, player in pairs(game.players) do
      if player.cheat_mode then
        cheat_mode.enable_recipes(player)
      end
    end
  end,
  ["1.2.0"] = function()
    local player_tables = global.players
    for i, player in pairs(game.players) do
      -- set map editor toggled flag to true
      player_tables[i].flags.map_editor_toggled = true
    end
  end,
  ["1.3.0"] = function()
    -- enable infintiy heat pipe recipe
    for _, force in pairs(game.forces) do
      local recipes = force.recipes
      if recipes["ee-infinity-loader"].enabled then
        recipes["ee-infinity-heat-pipe"].enabled = true
      end
    end
  end,
  ["1.3.1"] = function()
    -- update all infinity wagon names in global
    for _, t in pairs(global.wagons) do
      t.wagon_name = "ee-"..t.wagon_name
    end
  end,
  ["1.4.0"] = function()
    -- remove any sync chests that have somehow remained
    for _,  player_table in pairs(global.players) do
      player_table.sync_chests = nil
    end
    -- add flag to all players for inventory sync
    for i,  player in pairs(game.players) do
      local player_table = global.players[i]
      -- we don't have a settings table yet (that will be created in generic migrations) so do it manually
      player_table.flags.inventory_sync_enabled = player.mod_settings["ee-inventory-sync"].value and player.cheat_mode
    end
  end,
  ["1.5.0"] = function()
    -- remove old lualib info
    global.__lualib = nil
    -- initialize GUI module
    gui.init()
    -- destroy any infinity combinator GUIs
    for _, player_table in pairs(global.players) do
      player_table.sync_inventories = nil
      if player_table.gui.ic then
        if player_table.gui.ic.window then
          player_table.gui.ic.window.destroy()
        end
        player_table.gui.ic = nil
      end
    end
  end,
  ["1.5.13"] = function()
    -- is now called aggregate_filters
    global.aggregate_data = nil
    -- these were never removed when they were supposed to be
    global.combinators = nil
    global.tesseract_data = nil
  end
}