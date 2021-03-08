local cheat_mode = require("scripts.cheat-mode")
local constants = require("scripts.constants")

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
    for i in pairs(game.players) do
      -- set map editor toggled flag to true
      player_tables[i].flags.map_editor_toggled = true
    end
  end,
  ["1.3.0"] = function()
    -- enable infinity heat pipe recipe
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
    -- ! defunct as of v1.8.0
    -- gui.init()
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
  end,
  ["1.5.14"] = function()
    -- destroy remaining infinity combinator GUI data - it was still being created
    for _, player_table in pairs(global.players) do
      player_table.gui.ic = nil
    end
  end,
  ["1.5.15"] = function()
    for _, player_table in pairs(global.players) do
      player_table.flags.update_character_cheats_when_possible = false
    end
  end,
  ["1.5.21"] = function()
    -- find every non-buffer IA and divide its buffer size by 60
    for _, surface in pairs(game.surfaces) do
      for _, entity in pairs(surface.find_entities_filtered{type = "electric-energy-interface"}) do
        if constants.ia.entity_names[entity.name] and not string.find(entity.name, "tertiary") then
          entity.electric_buffer_size = entity.electric_buffer_size / 60
        end
      end
    end
  end,
  ["1.6.0"] = function()
    for _, player_table in pairs(global.players) do
      player_table.flags.opening_default_gui = false
    end
    -- add speedfluid to all existing pumps
    for _, surface in pairs(game.surfaces) do
      for _, entity in pairs(surface.find_entities_filtered{name = "ee-super-pump"}) do
        entity.fluidbox[2] = {
          name = "ee-super-pump-speed-fluid",
          amount = 100000000000,
          temperature = 30000.01
        }
      end
    end
  end,
  ["1.7.0"] = function()
    for _, player in pairs(game.players) do
      -- add margin to GUI roots if in the editor
      if player.controller_type == defines.controllers.editor then
        player.gui.top.style.left_margin = constants.editor_gui_width
        player.gui.left.style.left_margin = constants.editor_gui_width
      end
    end
  end,
  ["1.7.2"] = function()
    for _, player_table in pairs(global.players) do
      -- remove inventory sync flag - there is a mod setting for it!
      player_table.flags.inventory_sync_enabled = nil
    end
  end,
  ["1.7.3"] = function()
    for _, player_table in pairs(global.players) do
      -- no longer needs to be kept track of
      player_table.flags.in_satellite_view = nil
    end
  end,
  ["1.8.0"] = function()
    -- gui subtable is no longer needed!
    global.__flib.gui = nil
  end,
  ["1.9.0"] = function()
    for _, player_table in pairs(global.players) do
      player_table.flags.connecting_linked_belts = false
      player_table.last_cleared_cursor_tick = 0
      player_table.linked_belt_render_objects = {}
    end
  end,
  ["1.9.2"] = function()
    local linked_belt_sources = {}
    for player_index, player_table in pairs(global.players) do
      local source = player_table.linked_belt_source
      if source and source.valid then
        local players = linked_belt_sources[source.unit_number]
        if players then
          players[player_index] = true
        else
          linked_belt_sources[source.unit_number] = {player_index}
        end
      end
    end
    global.linked_belt_sources = linked_belt_sources
  end,
  ["1.9.9"] = function()
    for unit_number, wagon_data in pairs(global.wagons) do
      if wagon_data.wagon.valid then
        wagon_data.wagon_last_position = wagon_data.wagon.position
      else
        global.wagons[unit_number] = nil
      end
    end
  end
}