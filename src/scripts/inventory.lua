-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY

-- dependencies
local event = require("__RaiLuaLib__.lualib.event")
local gui = require("__RaiLuaLib__.lualib.gui")
local migration = require("__RaiLuaLib__.lualib.migration")

-- locals
local math_min = math.min
local string_find = string.find
local string_sub = string.sub

-- -----------------------------------------------------------------------------
-- INVENTORY AND CURSOR STACK SYNC

event.on_pre_player_toggled_map_editor(function(e)
  local player_table = global.players[e.player_index]
  if not player_table.flags.inventory_sync_enabled then return end
  local player = game.get_player(e.player_index)
  -- determine prefix based on controller type
  local prefix
  local controller_type = player.controller_type
  local controllers = defines.controllers
  if controller_type == controllers.editor then
    prefix = "editor_"
  elseif controller_type == controllers.god then
    prefix = "god_"
  else
    prefix = "character_"
  end
  -- iterate all inventories
  local inventories = {}
  for _,name in ipairs{"cursor", "main", "guns", "ammo", "armor"} do
    local sync_inventory
    if name == "cursor" then
      sync_inventory = game.create_inventory(1)
      local cursor_stack = player.cursor_stack
      if cursor_stack and cursor_stack.valid_for_read then
        sync_inventory[1].set_stack(cursor_stack)
      end
    else
      local inventory_def = defines.inventory[prefix..name]
      if inventory_def then
        local source_inventory = player.get_inventory(inventory_def)
        sync_inventory = game.create_inventory(#source_inventory)
        for i=1,#source_inventory do
          sync_inventory[i].set_stack(source_inventory[i])
        end
      end
    end
    inventories[name] = sync_inventory
  end
  player_table.sync_inventories = inventories
end)

event.on_player_toggled_map_editor(function(e)
  local player_table = global.players[e.player_index]
  if not player_table.flags.inventory_sync_enabled then return end
  local player = game.get_player(e.player_index)
  -- determine prefix based on controller type
  local prefix
  local controller_type = player.controller_type
  local controllers = defines.controllers
  if controller_type == controllers.editor then
    prefix = "editor_"
  elseif controller_type == controllers.god then
    prefix = "god_"
  else
    prefix = "character_"
  end
  -- iterate all inventories
  local inventories = player_table.sync_inventories
  for _,name in ipairs{"cursor", "main", "guns", "ammo", "armor"} do
    local sync_inventory = inventories[name]
    if name == "cursor" then
      player.cursor_stack.set_stack(sync_inventory[1])
    else
      local inventory_def = defines.inventory[prefix..name]
      if inventory_def then
        local destination_inventory = player.get_inventory(inventory_def)
        for i=1,math_min(#destination_inventory, #sync_inventory) do
          destination_inventory[i].set_stack(sync_inventory[i])
        end
      end
    end
    sync_inventory.destroy()
  end
  player_table.sync_inventories = nil
end)

local function toggle_sync(player, player_table, enable)
  enable = enable or (player_table.settings.inventory_sync and player.cheat_mode)
  if enable ~= player_table.flags.inventory_sync_enabled then
    if enable then
      player_table.flags.inventory_sync_enabled = true
      player.print{"ee-message.inventory-sync-enabled"}
    else
      player_table.flags.inventory_sync_enabled = false
      player.print{"ee-message.inventory-sync-disabled"}
    end
  end
end

-- -----------------------------------------------------------------------------
-- INFINITY INVENTORY FILTERS

local filters_table_version = 0
local filters_table_migrations = {}

local function export_filters(player)
  local filters = player.infinity_inventory_filters
  local output = {
    filters = filters,
    remove_unfiltered_items = player.remove_unfiltered_items
  }
  return game.encode_string("EditorExtensions-inventory_filters-"..filters_table_version.."-"..game.table_to_json(output))
end

local function import_filters(player, string)
  local decoded_string = game.decode_string(string)
  if not decoded_string then return false end
  if string_sub(decoded_string, 1, 16) == "EditorExtensions" and string_sub(decoded_string, 18, 34) == "inventory_filters" then
    -- extract version for migrations
    local _,_,version,json = string_find(decoded_string, "^.-%-.-%-(%d-)%-(.*)$")
    version = tonumber(version)
    local input = game.json_to_table(json)
    if version < filters_table_version then
      migration.generic(version, filters_table_migrations, input)
    end
    -- sanitise the filters to only include currently existing prototypes
    local item_prototypes = game.item_prototypes
    local output = {}
    local output_index = 0
    local filters = input.filters
    for i=1,#filters do
      local filter = filters[i]
      if item_prototypes[filter.name] then
        output_index = output_index + 1
        output[output_index] = {name=filter.name, count=filter.count, mode=filter.mode, index=output_index}
      end
    end
    player.infinity_inventory_filters = output
    player.remove_unfiltered_items = input.remove_unfiltered_items
    return true
  end
  return false
end

gui.templates:extend{
  inventory_filters_string = {
    export_nav_flow = {type="flow", style_mods={top_margin=8}, direction="horizontal", children={
      {type="button", style="back_button", caption={"gui.cancel"}, handlers="inventory_filters_string.back_button"},
      {type="empty-widget", style="draggable_space_header", style_mods={height=32, horizontally_stretchable=true}, save_as="lower_drag_handle"}
    }},
    import_nav_flow = {type="flow", style_mods={top_margin=8}, direction="horizontal", children={
      {type="button", style="back_button", caption={"gui.cancel"}, handlers="inventory_filters_string.back_button"},
      {type="empty-widget", style="draggable_space_header", style_mods={height=32, horizontally_stretchable=true}, save_as="lower_drag_handle"},
      {type="button", style="confirm_button", caption={"gui.confirm"}, mods={enabled=false}, handlers="inventory_filters_string.confirm_button",
        save_as="confirm_button"}
    }}
  }
}

gui.handlers:extend{
  inventory_filters_buttons = {
    import_export_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        if player_table.gui.inventory_filters_string then
          event.disable_group("gui.inventory_filters_string", e.player_index)
          player_table.gui.inventory_filters_string.window.destroy()
          player_table.gui.inventory_filters_string = nil
        end
        local mode = e.element.sprite:find("export") and "export" or "import"
        local gui_data = gui.build(player.gui.screen, {
          {type="frame", style="dialog_frame", direction="vertical", save_as="window", children={
            {type="flow", children={
              {type="label", style="frame_title", caption={"ee-gui."..mode.."-inventory-filters"}},
              {type="empty-widget", style="draggable_space_header", style_mods={height=24, horizontally_stretchable=true}, save_as="drag_handle"}
            }},
            {type="text-box", style_mods={width=400, height=300}, clear_and_focus_on_right_click=true, mods={word_wrap=true},
              handlers=(mode == "import" and "inventory_filters_string.textbox" or nil), save_as="textbox"},
            {template="inventory_filters_string."..mode.."_nav_flow"}
          }}
        })
        gui_data.drag_handle.drag_target = gui_data.window
        gui_data.lower_drag_handle.drag_target = gui_data.window
        gui_data.window.force_auto_center()
        gui_data.textbox.focus()

        if mode == "export" then
          gui_data.textbox.text = export_filters(player)
          gui_data.textbox.select_all()
        end

        player_table.gui.inventory_filters_string = gui_data
      end
    },
    inventory_window = {
      on_gui_closed = function(e)
        if e.gui_type and e.gui_type == 3 then
          local player_table = global.players[e.player_index]
          event.disable_group("gui.inventory_filters_buttons", e.player_index)
          player_table.gui.inventory_filters_buttons.window.destroy()
          player_table.gui.inventory_filters_buttons = nil
        end
      end
    },
    player = {
      on_player_toggled_map_editor = function(e)
        -- close the GUI if the player exits the map editor
        local player_table = global.players[e.player_index]
        event.disable_group("gui.inventory_filters_buttons", e.player_index)
        player_table.gui.inventory_filters_buttons.window.destroy()
        player_table.gui.inventory_filters_buttons = nil
        if player_table.gui.inventory_filters_string then
          event.disable_group("gui.inventory_filters_string", e.player_index)
          player_table.gui.inventory_filters_string.window.destroy()
          player_table.gui.inventory_filters_string = nil
        end
      end,
      on_player_display_resolution_changed = function(e)
        local player = game.get_player(e.player_index)
        local gui_data = global.players[e.player_index].gui.inventory_filters_buttons
        gui_data.window.location = {x=0, y=(player.display_resolution.height-(56*player.display_scale))}
      end
    }
  },
  inventory_filters_string = {
    back_button = {
      on_gui_click = function(e)
        local player_table = global.players[e.player_index]
        event.disable_group("gui.inventory_filters_string", e.player_index)
        player_table.gui.inventory_filters_string.window.destroy()
        player_table.gui.inventory_filters_string = nil
      end
    },
    confirm_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.inventory_filters_string
        if import_filters(player, gui_data.textbox.text) then
          event.disable_group("gui.inventory_filters_string", e.player_index)
          gui_data.window.destroy()
          player_table.gui.inventory_filters_string = nil
        else
          player.print{"ee-message.invalid-inventory-filters-string"}
        end
      end
    },
    textbox = {
      on_gui_text_changed = function(e)
        local gui_data = global.players[e.player_index].gui.inventory_filters_string
        if e.element.text == "" then
          gui_data.confirm_button.enabled = false
        else
          gui_data.confirm_button.enabled = true
        end
      end
    }
  }
}

event.on_gui_opened(function(e)
  if e.gui_type and e.gui_type == 3 then
    local player = game.get_player(e.player_index)
    if player.controller_type == defines.controllers.editor then
      -- create buttons GUI
      local player_table = global.players[e.player_index]
      local gui_data = gui.build(player.gui.screen, {
        {type="frame", style="shortcut_bar_window_frame", style_mods={right_padding=4}, save_as="window", children={
          {type="frame", style="shortcut_bar_inner_panel", direction="horizontal", children={
            {type="sprite-button", style="shortcut_bar_button", sprite="ee-import-inventory-filters", tooltip={"ee-gui.import-inventory-filters"},
              handlers="inventory_filters_buttons.import_export_button", save_as="import_button"},
            {type="sprite-button", style="shortcut_bar_button", sprite="ee-export-inventory-filters", tooltip={"ee-gui.export-inventory-filters"},
              handlers="inventory_filters_buttons.import_export_button", save_as="export_button"}
          }}
        }}
      }, "inventory_filters_buttons", player.index)
      -- register events
      event.enable_group("gui.inventory_filters_buttons", e.player_index)
      -- add to global
      player_table.gui.inventory_filters_buttons = gui_data
      -- position GUI
      gui.handlers.inventory_filters_buttons.player.on_player_display_resolution_changed{player_index=e.player_index}
    end
  end
end)

-- -----------------------------------------------------------------------------
-- OBJECT

return {
  import_inventory_filters = import_filters,
  toggle_sync = toggle_sync
}