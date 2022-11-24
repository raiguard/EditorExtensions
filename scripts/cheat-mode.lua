local cheat_mode = {}

local constants = require("__EditorExtensions__/scripts/constants")

--- @param player LuaPlayer
--- @param skip_message boolean?
function cheat_mode.enable_recipes(player, skip_message)
  local force = player.force
  local recipes = force.recipes
  -- check if it has already been enabled for this force
  if recipes["ee-infinity-loader"].enabled == false then
    for _, recipe in pairs(recipes) do
      if recipe.category == "ee-testing-tool" and not recipe.enabled then
        recipe.enabled = true
      end
    end
    if not skip_message then
      force.print({ "ee-message.testing-tools-enabled", player.name })
    end
  end
end

--- @param player LuaPlayer
--- @param skip_message boolean?
function cheat_mode.disable_recipes(player, skip_message)
  local force = player.force
  local recipes = force.recipes
  if recipes["ee-infinity-loader"].enabled then
    for _, recipe in pairs(recipes) do
      if recipe.category == "ee-testing-tool" then
        recipe.enabled = false
      end
    end
    if not skip_message then
      force.print({ "ee-message.testing-tools-disabled", player.name })
    end
  end
end

--- @param inventory LuaInventory
local function set_armor(inventory)
  if inventory[1] and inventory[1].valid_for_read and inventory[1].name == "power-armor-mk2" then
    inventory[1].grid.clear()
  else
    inventory[1].set_stack({ name = "power-armor-mk2" })
  end
  local grid = inventory[1].grid
  local equipment_to_add = constants.cheat_mode.equipment_to_add
  for i = 1, #equipment_to_add do
    grid.put(equipment_to_add[i])
  end
end

--- @param player LuaPlayer
function cheat_mode.set_loadout(player)
  -- remove default items
  local main_inventory = player.get_main_inventory()
  if not main_inventory then
    return
  end
  local items_to_remove = constants.cheat_mode.items_to_remove
  for i = 1, #items_to_remove do
    main_inventory.remove(items_to_remove[i])
  end
  -- add custom items
  local items_to_add = constants.cheat_mode.items_to_add
  for i = 1, #items_to_add do
    main_inventory.insert(items_to_add[i])
  end
  if player.controller_type == defines.controllers.character then
    -- overwrite the default armor loadout
    set_armor(
      player.get_inventory(defines.inventory.character_armor) --[[@as LuaInventory]]
    )
    -- apply character cheats
    cheat_mode.update_character_cheats(player)
  elseif player.controller_type == defines.controllers.editor then
    -- overwrite the default armor loadout
    set_armor(
      player.get_inventory(defines.inventory.editor_armor) --[[@as LuaInventory]]
    )
    -- if the player uses a character, apply cheats to it upon exit
    if player.stashed_controller_type == defines.controllers.character then
      global.players[player.index].flags.update_character_cheats_when_possible = true
    end
  end
end

--- @param player LuaPlayer
function cheat_mode.update_character_cheats(player)
  -- abort if they were already applied
  -- we can safely assume that only this mod or Creative Mod would increase the reach this much
  if player.cheat_mode and player.character and player.character_reach_distance_bonus >= 1000000 then
    return
  end
  -- get all associated characters as well as the active one
  local associated_characters = player.get_associated_characters()
  associated_characters[#associated_characters + 1] = player.character
  local multiplier = player.cheat_mode and 1 or -1
  -- apply bonuses
  for _, character in pairs(associated_characters) do
    for modifier, amount in pairs(constants.cheat_mode.modifiers) do
      character[modifier] = math.max(character[modifier] + (amount * multiplier), 0)
    end
  end
end

--- @param player LuaPlayer
--- @param set_loadout boolean?
function cheat_mode.enable(player, set_loadout)
  -- recipes will be enabled automatically
  player.cheat_mode = true

  player.force.research_all_technologies()

  cheat_mode.update_character_cheats(player)

  if set_loadout then
    cheat_mode.set_loadout(player)
  end
end

--- @param player LuaPlayer
--- @param player_table PlayerTable
function cheat_mode.disable(player, player_table)
  -- disable cheat mode
  player.cheat_mode = false

  -- remove recipes
  cheat_mode.disable_recipes(player)

  -- reset bonuses or set a flag to do so
  if player.controller_type == defines.controllers.character then
    cheat_mode.update_character_cheats(player)
  elseif player.stashed_controller_type == defines.controllers.character then
    player_table.flags.update_character_cheats_when_possible = true
  end
end

return cheat_mode
