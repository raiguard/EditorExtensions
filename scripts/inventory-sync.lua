local table = require("__flib__/table")

--- @class InventorySyncData
--- @field filters table<integer, string?>
--- @field hand_location uint?
--- @field inventory LuaInventory

--- @param player LuaPlayer
local function pre_sync(player)
  local prefix = table.find(defines.controllers, player.controller_type) .. "_"
  local hand_location = player.hand_location or {}
  --- @type table<string, InventorySyncData>
  local sync_tables = {}
  for _, name in ipairs({ "cursor", "main", "guns", "armor", "ammo" }) do
    --- @type table<integer, string?>
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
      --- @type InventorySyncData
      sync_tables[name] = {
        filters = sync_filters,
        hand_location = hand_location.inventory == inventory_def and hand_location.slot or nil,
        inventory = sync_inventory,
      }
    end
  end
  global.inventory_sync[player.index] = sync_tables
end

--- @param player LuaPlayer
local function post_sync(player)
  -- determine prefix based on controller type
  local prefix = table.find(defines.controllers, player.controller_type) .. "_"
  -- iterate all inventories
  local sync_data = global.inventory_sync[player.index]
  if not sync_data then
    return
  end
  global.inventory_sync[player.index] = nil
  -- Cursor first to allow setting the hand, then armor to correct the inventory size
  for _, name in ipairs({ "cursor", "armor", "main", "guns", "ammo" }) do
    local sync_table = sync_data[name]
    -- God mode doesn't have every inventory
    if not sync_table then
      goto continue
    end
    local sync_filters = sync_table.filters
    local sync_inventory = sync_table.inventory
    if name == "cursor" and player.cursor_stack then
      player.cursor_stack.transfer_stack(sync_inventory[1])
    else
      local inventory_def = defines.inventory[prefix .. name]
      if not inventory_def then
        goto continue
      end
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
    sync_inventory.destroy()
    ::continue::
  end
end

--- @param e EventData.on_pre_player_toggled_map_editor
local function on_pre_player_toggled_map_editor(e)
  local player = game.get_player(e.player_index)
  if not player or not player.cheat_mode then
    return
  end
  if not player.mod_settings["ee-inventory-sync"].value then
    return
  end
  pre_sync(player)
end

--- @param e EventData.on_player_toggled_map_editor
local function on_player_toggled_map_editor(e)
  local player = game.get_player(e.player_index)
  if not player or not player.cheat_mode then
    return
  end
  if not player.mod_settings["ee-inventory-sync"].value then
    return
  end
  post_sync(player)
end

local inventory_sync = {}

inventory_sync.on_init = function()
  --- @type table<uint, table<string, InventorySyncData?>>
  global.inventory_sync = {}
end

inventory_sync.events = {
  [defines.events.on_pre_player_toggled_map_editor] = on_pre_player_toggled_map_editor,
  [defines.events.on_player_toggled_map_editor] = on_player_toggled_map_editor,
}

return inventory_sync
