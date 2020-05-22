local cheat_mode = {}

local inventory = require("scripts.inventory")

local string = string

function cheat_mode.enable_recipes(player, skip_message)
  local force = player.force
  local recipes = force.recipes
  -- check if it has already been enabled for this force
  if recipes["ee-infinity-loader"].enabled == false then
    for name in pairs(game.recipe_prototypes) do
      if string.sub(name, 1, 3) == "ee-" and recipes[name] then
        recipes[name].enabled = true
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
    for name in pairs(game.recipe_prototypes) do
      if string.sub(name, 1, 3) == "ee-" and recipes[name] then
        recipes[name].enabled = false
      end
    end
    if not skip_message then
      force.print{"ee-message.testing-tools-disabled", player.name}
    end
  end
end

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
    -- apply bonuses
    player.character_build_distance_bonus = 1000000
    player.character_mining_speed_modifier = 2
    player.character_reach_distance_bonus = 1000000
    player.character_resource_reach_distance_bonus = 1000000
    -- overwrite the default armor loadout
    set_armor(player.get_inventory(defines.inventory.character_armor))
  elseif player.controller_type == defines.controllers.editor then
    -- overwrite the default armor loadout
    set_armor(player.get_inventory(defines.inventory.editor_armor))
  end
end

function cheat_mode.enable(player)
  -- enabling cheat mode will cause the recipes to be unlocked, and sync to be enabled
  player.cheat_mode = true

  player.force.research_all_technologies()
  cheat_mode.set_loadout(player)
end

function cheat_mode.disable(player, player_table)
  -- reset bonuses and disable cheat mode
  player.character_build_distance_bonus = 0
  player.character_mining_speed_modifier = 0
  player.character_reach_distance_bonus = 0
  player.character_resource_reach_distance_bonus = 0
  player.cheat_mode = false

  -- remove recipes
  cheat_mode.disable_recipes(player)

  -- disable inventory sync
  inventory.toggle_sync(player, player_table)
end

return cheat_mode