--- @class CheatMode
local cheat_mode = {}

local constants = require("__EditorExtensions__/scripts/constants")

--- @param inventory LuaInventory?
local function set_armor(inventory)
  if not inventory or not inventory.valid then
    return
  end
  -- TODO: Use highest-tier armor instead of hardcoding to power armor mk2
  inventory[1].set_stack({ name = "power-armor-mk2" })
  local grid = inventory[1].grid
  if not grid then
    return
  end
  local equipment_to_add = constants.cheat_mode.equipment_to_add
  for i = 1, #equipment_to_add do
    grid.put(equipment_to_add[i])
  end
end

--- @param player LuaPlayer
function cheat_mode.set_loadout(player)
  -- Remove default items
  local main_inventory = player.get_main_inventory()
  if not main_inventory then
    return
  end
  local items_to_remove = constants.cheat_mode.items_to_remove
  for i = 1, #items_to_remove do
    main_inventory.remove(items_to_remove[i])
  end
  -- Add custom items
  local items_to_add = constants.cheat_mode.items_to_add
  for i = 1, #items_to_add do
    main_inventory.insert(items_to_add[i])
  end
  if player.controller_type == defines.controllers.character then
    set_armor(player.get_inventory(defines.inventory.character_armor))
    cheat_mode.update_character_cheats(player)
  elseif player.controller_type == defines.controllers.editor then
    set_armor(player.get_inventory(defines.inventory.editor_armor))
    -- If the player uses a character, apply cheats to it upon exit
    if player.stashed_controller_type == defines.controllers.character then
      global.players[player.index].flags.update_character_cheats_when_possible = true
    end
  end
end

--- @param player LuaPlayer
function cheat_mode.update_character_cheats(player)
  -- Abort if they were already applied
  -- We can safely assume that only this mod, Creative Mod, or Tapeline would increase the reach this much
  if player.cheat_mode and player.character and player.character_reach_distance_bonus >= 1000000 then
    return
  end
  -- Get all associated characters as well as the active one
  local associated_characters = player.get_associated_characters()
  associated_characters[#associated_characters + 1] = player.character
  local multiplier = player.cheat_mode and 1 or -1
  -- Apply bonuses
  for _, character in pairs(associated_characters) do
    for modifier, amount in pairs(constants.cheat_mode.modifiers) do
      character[modifier] = math.max(character[modifier] + (amount * multiplier), 0)
    end
  end
end

return cheat_mode
