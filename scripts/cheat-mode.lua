local util = require("__EditorExtensions__/scripts/util")

local character_modifiers = {
  character_build_distance_bonus = 1000000,
  character_mining_speed_modifier = 2,
  character_reach_distance_bonus = 1000000,
  character_resource_reach_distance_bonus = 1000000,
}

local equipment_to_add = {
  { name = "ee-infinity-fusion-reactor-equipment", position = { 0, 0 } },
  { name = "ee-super-personal-roboport-equipment", position = { 1, 0 } },
  { name = "ee-super-exoskeleton-equipment", position = { 2, 0 } },
  { name = "ee-super-exoskeleton-equipment", position = { 3, 0 } },
  { name = "ee-super-energy-shield-equipment", position = { 4, 0 } },
  { name = "ee-super-night-vision-equipment", position = { 5, 0 } },
  { name = "ee-super-battery-equipment", position = { 6, 0 } },
  { name = "belt-immunity-equipment", position = { 7, 0 } },
}

local items_to_add = {
  { name = "ee-infinity-accumulator", count = 50 },
  { name = "ee-infinity-chest", count = 50 },
  { name = "ee-super-construction-robot", count = 100 },
  { name = "ee-super-inserter", count = 50 },
  { name = "ee-infinity-loader", count = 50 },
  { name = "ee-infinity-pipe", count = 50 },
  { name = "ee-super-substation", count = 50 },
}

local items_to_remove = {
  { name = "express-loader", count = 50 },
  { name = "stack-inserter", count = 50 },
  { name = "substation", count = 50 },
  { name = "construction-robot", count = 100 },
  { name = "electric-energy-interface", count = 1 },
  { name = "infinity-chest", count = 20 },
  { name = "infinity-pipe", count = 10 },
  { name = "linked-chest", count = 10 },
}

--- @param inventory LuaInventory?
local function set_armor(inventory)
  if not inventory or not inventory.valid then
    return
  end
  inventory[1].set_stack({ name = "power-armor-mk2" })
  local grid = inventory[1].grid
  if not grid then
    return
  end
  for i = 1, #equipment_to_add do
    grid.put(equipment_to_add[i])
  end
end

--- @param player LuaPlayer
local function set_character_cheats(player)
  if player.character_reach_distance_bonus >= 1000000 then
    return
  end
  local character = player.character
  if not character or not character.valid then
    return
  end
  for modifier, amount in pairs(character_modifiers) do
    character[modifier] = character[modifier] + amount
  end
end

--- @param player LuaPlayer
local function set_loadout(player)
  -- Remove default items
  local main_inventory = player.get_main_inventory()
  if not main_inventory then
    return
  end
  local items_to_remove = items_to_remove
  for i = 1, #items_to_remove do
    main_inventory.remove(items_to_remove[i])
  end
  -- Add custom items
  local items_to_add = items_to_add
  for i = 1, #items_to_add do
    main_inventory.insert(items_to_add[i])
  end
  if player.controller_type == defines.controllers.character then
    set_armor(player.get_inventory(defines.inventory.character_armor))
    set_character_cheats(player)
  elseif player.controller_type == defines.controllers.editor then
    set_armor(player.get_inventory(defines.inventory.editor_armor))
  end
end

--- @param force LuaForce
local function disable_recipes(force)
  for _, recipe in pairs(force.recipes) do
    if recipe.category == "ee-testing-tool" then
      recipe.enabled = false
    end
  end
end

--- @param force LuaForce
local function enable_recipes(force)
  for _, recipe in pairs(force.recipes) do
    if recipe.category == "ee-testing-tool" then
      recipe.enabled = true
    end
  end
  for _, player in pairs(force.players) do
    player.clear_recipe_notifications()
  end
end

--- @param e EventData.on_console_command
local function on_console_command(e)
  if e.command ~= "cheat" or not game.console_command_used then
    return
  end
  local player = game.get_player(e.player_index)
  if not player or not player.valid then
    return
  end
  if e.parameters == "all" then
    set_loadout(player)
  end
  enable_recipes(player.force --[[@as LuaForce]])
  if game.is_multiplayer() then
    player.force.print({ "message.ee-tools-enabled", player.name })
  end
end

--- @param e EventData.on_player_created
local function on_player_created(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  if util.in_debug_world() or util.in_testing_scenario() then
    set_loadout(player)
    enable_recipes(player.force --[[@as LuaForce]])
  end
end

--- @param e EventData.on_player_toggled_map_editor
local function on_player_toggled_map_editor(e)
  local player = game.get_player(e.player_index)
  if not player or not player.cheat_mode or player.controller_type ~= defines.controllers.character then
    return
  end
  set_character_cheats(player)
end

local cheat_mode = {}

cheat_mode.events = {
  [defines.events.on_console_command] = on_console_command,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_toggled_map_editor] = on_player_toggled_map_editor,
}

cheat_mode.add_remote_interface = function()
  remote.add_interface("ee_cheat_mode", {
    --- @param force LuaForce
    disable_testing_recipes = function(force)
      disable_recipes(force)
    end,
    --- @param force LuaForce
    enable_testing_recipes = function(force)
      enable_recipes(force)
    end,
  })
end

return cheat_mode
