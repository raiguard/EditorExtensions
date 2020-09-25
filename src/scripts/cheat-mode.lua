local cheat_mode = {}

local constants = require("scripts.constants")
local inventory = require("scripts.inventory")

function cheat_mode.enable_recipes(player, skip_message)
  local force = player.force
  local recipes = force.recipes
  -- check if it has already been enabled for this force
  if recipes["ee-infinity-loader"].enabled == false then
    for _, recipe in pairs(recipes) do
      if recipe.category == "ee-testing-tool" then
        recipe.enabled = true
      end
    end
    if not skip_message then
      force.print{"ee-message.testing-tools-enabled", player.name}
    end
  end
end

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
      force.print{"ee-message.testing-tools-disabled", player.name}
    end
  end
end

local function set_armor(inventory)
  if inventory[1] and inventory[1].valid_for_read and inventory[1].name == "power-armor-mk2" then
    inventory[1].grid.clear()
  else
    inventory[1].set_stack{name = "power-armor-mk2"}
  end
  local grid = inventory[1].grid
  local equipment_to_add = constants.cheat_mode.equipment_to_add
  for i = 1, #equipment_to_add do
    grid.put(equipment_to_add[i])
  end
end

function cheat_mode.set_loadout(player)
  -- remove default items
  local main_inventory = player.get_main_inventory()
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
    set_armor(player.get_inventory(defines.inventory.character_armor))
    -- apply character cheats
    cheat_mode.update_character_cheats(player)
  elseif player.controller_type == defines.controllers.editor then
    -- overwrite the default armor loadout
    set_armor(player.get_inventory(defines.inventory.editor_armor))
    -- if the player uses a character, apply cheats to it upon exit
    if player.stashed_controller_type == defines.controllers.character then
      global.players[player.index].flags.update_character_cheats_when_possible = true
    end
  end
end

function cheat_mode.update_character_cheats(player)
  -- get all associated characters as well as the active one
  local associated_characters = player.get_associated_characters()
  associated_characters[#associated_characters+1] = player.character
  local multiplier = player.cheat_mode and 1 or -1
  -- apply bonuses
  for _, character in pairs(associated_characters) do
    for modifier, amount in pairs(constants.cheat_mode.modifiers) do
      character[modifier] = character[modifier] + (amount * multiplier)
    end
  end
end

function cheat_mode.disable(player, player_table)
  -- disable cheat mode
  player.cheat_mode = false

  -- remove recipes
  cheat_mode.disable_recipes(player)

  -- disable inventory sync
  inventory.toggle_sync(player, player_table)

  -- reset bonuses or set a flag to do so
  if player.controller_type == defines.controllers.character then
    cheat_mode.update_character_cheats(player)
  elseif player.stashed_controller_type == defines.controllers.character then
    player_table.flags.update_character_cheats_when_possible = true
  end
end

return cheat_mode