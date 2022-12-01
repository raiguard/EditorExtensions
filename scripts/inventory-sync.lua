local inventory = {}

local reverse_defines = require("__flib__/reverse-defines")

-- -----------------------------------------------------------------------------
-- INVENTORY AND CURSOR STACK SYNC

--- @param player_table PlayerTable
--- @param player LuaPlayer
function inventory.create_sync_inventories(player_table, player)
  -- determine prefix based on controller type
  local prefix = reverse_defines.controllers[player.controller_type] .. "_"
  -- hand location
  local hand_location = player.hand_location or {}
  -- iterate all inventories
  local sync_tables = {}
  for _, name in ipairs({ "cursor", "main", "guns", "armor", "ammo" }) do
    local sync_filters = {}
    local sync_inventory
    local inventory_def = defines.inventory[prefix .. name]
    if name == "cursor" then
      sync_inventory = game.create_inventory(1)
      local cursor_stack = player.cursor_stack
      if cursor_stack and cursor_stack.valid_for_read then
        sync_inventory[1].transfer_stack(cursor_stack)
      end
    elseif inventory_def then
      local source_inventory = player.get_inventory(inventory_def) --[[@as LuaInventory]]
      local get_filter = source_inventory.get_filter
      local set_filter = source_inventory.set_filter
      local supports_filters = source_inventory.supports_filters()
      local source_inventory_len = #source_inventory --[[@as uint16]]
      sync_inventory = game.create_inventory(source_inventory_len)
      for i = 1, source_inventory_len do
        --- @cast i uint
        sync_inventory[i].transfer_stack(source_inventory[i])
        if supports_filters then
          sync_filters[i] = get_filter(i)
          set_filter(i, nil)
        end
      end
    end
    if sync_inventory then
      sync_tables[name] = {
        filters = sync_filters,
        hand_location = (hand_location.inventory == inventory_def and hand_location.slot or nil),
        inventory = sync_inventory,
      }
    end
  end
  player_table.sync_data = sync_tables
end

--- @param player_table PlayerTable
--- @param player LuaPlayer
function inventory.get_from_sync_inventories(player_table, player)
  -- determine prefix based on controller type
  local prefix = reverse_defines.controllers[player.controller_type] .. "_"
  -- iterate all inventories
  local sync_data = player_table.sync_data
  -- Cursor first to allow setting the hand, then armor to correct the inventory size
  for _, name in ipairs({ "cursor", "armor", "main", "guns", "ammo" }) do
    local sync_table = sync_data[name]
    -- god mode doesn't have every inventory
    if sync_table then
      local sync_filters = sync_table.filters
      local sync_inventory = sync_table.inventory
      if name == "cursor" and player.cursor_stack then
        player.cursor_stack.transfer_stack(sync_inventory[1])
      else
        local inventory_def = defines.inventory[prefix .. name]
        if inventory_def then
          local destination_inventory = player.get_inventory(inventory_def) --[[@as LuaInventory]]
          local set_filter = destination_inventory.set_filter
          local supports_filters = destination_inventory.supports_filters()
          for i = 1, math.min(#destination_inventory, #sync_inventory) do
            --- @cast i uint
            if supports_filters then
              set_filter(i, sync_filters[i])
            end
            destination_inventory[i].clear()
            destination_inventory[i].transfer_stack(sync_inventory[i])
          end
          local hand_location = sync_table.hand_location
          if hand_location and hand_location <= #destination_inventory then
            player.hand_location = { inventory = inventory_def, slot = hand_location }
          end
        end
      end
      sync_inventory.destroy()
    end
  end
  player_table.sync_data = nil
end

return inventory
