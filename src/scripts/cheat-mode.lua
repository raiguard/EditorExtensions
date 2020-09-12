local cheat_mode = {}

local reverse_defines = require("__flib__.reverse-defines")

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

-- TODO tap freeplay interface for these counts
local items_to_remove = {
  {name="express-loader", count=50},
  {name="stack-inserter", count=50},
  {name="substation", count=50},
  {name="construction-robot", count=100},
  {name="electric-energy-interface", count=1},
  {name="infinity-chest", count=20},
  {name="infinity-pipe", count=10}
}

local items_to_add = {
  {name="ee-infinity-accumulator", count=50},
  {name="ee-infinity-chest", count=50},
  {name="ee-super-construction-robot", count=100},
  {name="ee-super-inserter", count=50},
  {name="ee-infinity-pipe", count=50},
  {name="ee-super-substation", count=50}
}

local equipment_to_add = {
  {name="ee-infinity-fusion-reactor-equipment", position={0,0}},
  {name="ee-super-personal-roboport-equipment", position={1,0}},
  {name="ee-super-exoskeleton-equipment", position={2,0}},
  {name="ee-super-exoskeleton-equipment", position={3,0}},
  {name="ee-super-energy-shield-equipment", position={4,0}},
  {name="ee-super-night-vision-equipment", position={5,0}},
  {name="belt-immunity-equipment", position={6,0}}
}

local function set_armor(inventory)
  if inventory[1] and inventory[1].valid_for_read and inventory[1].name == "power-armor-mk2" then
    inventory[1].grid.clear()
  else
    inventory[1].set_stack{name="power-armor-mk2"}
  end
  local grid = inventory[1].grid
  for i=1, #equipment_to_add do
    grid.put(equipment_to_add[i])
  end
end

function cheat_mode.set_loadout(player)
  -- remove default items
  local main_inventory = player.get_main_inventory()
  for i=1, #items_to_remove do
    main_inventory.remove(items_to_remove[i])
  end
  -- add custom items
  for i=1, #items_to_add do
    main_inventory.insert(items_to_add[i])
  end
  if player.controller_type == defines.controllers.character then
    -- overwrite the default armor loadout
    set_armor(player.get_inventory(defines.inventory.character_armor))
    -- apply character cheats
    cheat_mode.enable_character_cheats(player)
  elseif player.controller_type == defines.controllers.editor then
    -- overwrite the default armor loadout
    set_armor(player.get_inventory(defines.inventory.editor_armor))
    -- if the player uses a character, apply cheats to it upon exit
    if player.stashed_controller_type == defines.controllers.character then
      global.players[player.index].flags.apply_character_cheats_on_exit = true
    end
  end
end

function cheat_mode.enable_character_cheats(player)
  -- get all associated characters as well as the active one
  local associated_characters = player.get_associated_characters()
  associated_characters[#associated_characters+1] = player.character
  -- apply bonuses
  for _, character in pairs(associated_characters) do
    character.character_build_distance_bonus = 1000000
    character.character_mining_speed_modifier = 2
    character.character_reach_distance_bonus = 1000000
    character.character_resource_reach_distance_bonus = 1000000
  end
end

function cheat_mode.disable_character_cheats(player)
  -- get all associated characters as well as the active one
  local associated_characters = player.get_associated_characters()
  associated_characters[#associated_characters+1] = player.character
  -- negate bonuses
  for _, character in pairs(associated_characters) do
    character.character_build_distance_bonus = character.character_build_distance_bonus - 1000000
    character.character_mining_speed_modifier = character.character_mining_speed_modifier - 2
    character.character_reach_distance_bonus = character.character_reach_distance_bonus - 1000000
    character.character_resource_reach_distance_bonus = character.character_resource_reach_distance_bonus - 1000000
  end
end

function cheat_mode.disable(player, player_table)
  -- reset bonuses or set a flag to do so
  if player.controller_type == defines.controllers.character then
    cheat_mode.disable_character_cheats(player)
  elseif player.stashed_controller_type == defines.controllers.character then
    player_table.flags.update_character_cheats_when_possible = true
  end

  player.cheat_mode = false

  -- remove recipes
  cheat_mode.disable_recipes(player)

  -- disable inventory sync
  inventory.toggle_sync(player, player_table)
end

return cheat_mode