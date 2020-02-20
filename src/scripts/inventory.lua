-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY

-- dependencies
local event = require('lualib/event')
local gui = require('lualib/gui')
local migrations = require('lualib/migrations')

-- locals
local string_find = string.find
local string_sub = string.sub

-- -----------------------------------------------------------------------------
-- INVENTORY AND CURSOR STACK SYNC

-- before the mode is switched
local function pre_toggled_editor(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  -- cursor stack
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read then
    local chest = player.surface.create_entity{
      name = 'ee-cursor-sync-chest',
      position = player.position,
      create_build_effect_smoke = false
    }
    if not chest then error('Failed to create cursor sync chest.') end
    local chest_inventory = chest.get_inventory(defines.inventory.chest)
    chest_inventory[1].set_stack(cursor_stack)
    player_table.cursor_sync_chest = chest
  end
  -- main inventory
  do
    local chest = player.surface.create_entity{
      name = 'ee-inventory-sync-chest',
      position = player.position,
      create_build_effect_smoke = false
    }
    if not chest then error('Failed to create inventory sync chest.') end
    local chest_inventory = chest.get_inventory(defines.inventory.chest)
    local player_inventory = player.get_main_inventory()
    for i=1,#player_inventory do
      chest_inventory[i].set_stack(player_inventory[i])
    end
    player_table.inventory_sync_chest = chest
  end
end

-- after the mode is switched
local function toggled_editor(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  -- cursor stack
  if player_table.cursor_sync_chest then
    local chest = player_table.cursor_sync_chest
    if not chest then error('Failed to retrieve inventory sync chest.') end
    player.cursor_stack.set_stack(chest.get_inventory(defines.inventory.chest)[1])
    chest.destroy()
    player_table.cursor_sync_chest = nil
  end
  -- main inventory
  local chest = player_table.inventory_sync_chest
  if not chest then error('Failed to retrieve inventory sync chest.') end
  local chest_inventory = chest.get_inventory(defines.inventory.chest)
  local player_inventory = player.get_main_inventory()
  for i=1,#player_inventory do
    player_inventory[i].set_stack(chest_inventory[i])
  end
  chest.destroy()
  player_table.inventory_sync_chest = nil
end

-- toggle the sync when the player goes in/out of cheat mode
event.register({defines.events.on_player_cheat_mode_enabled, defines.events.on_player_cheat_mode_disabled, defines.events.on_runtime_mod_setting_changed}, function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local cheat_mode = player.cheat_mode
  if cheat_mode and player.mod_settings['ee-inventory-sync'].value then
    player_table.flags.inventory_sync = true
    event.register(defines.events.on_pre_player_toggled_map_editor, pre_toggled_editor, {name='inventory_sync_pre_toggled_editor', player_index=e.player_index})
    event.register(defines.events.on_player_toggled_map_editor, toggled_editor, {name='inventory_sync_toggled_editor', player_index=e.player_index})
  else
    player_table.flags.inventory_sync = false
    event.deregister(defines.events.on_pre_player_toggled_map_editor, pre_toggled_editor, 'inventory_sync_pre_toggled_editor', e.player_index)
    event.deregister(defines.events.on_player_toggled_map_editor, toggled_editor, 'inventory_sync_toggled_editor', e.player_index)
  end
end)

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
  return game.encode_string('EditorExtensions-inventory_filters-'..filters_table_version..'-'..game.table_to_json(output))
end

local function import_filters(player, string)
  local decoded_string = game.decode_string(string)
  if not decoded_string then return false end
  if string_sub(decoded_string, 1, 16) == 'EditorExtensions' and string_sub(decoded_string, 18, 34) == 'inventory_filters' then
    -- extract version for migrations
    local _,_,version,json = string_find(decoded_string, '^.-%-.-%-(%d-)%-(.*)$')
    version = tonumber(version)
    local input = game.json_to_table(json)
    if version < filters_table_version then
      migrations.generic(version, filters_table_migrations, input)
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

gui.add_templates{
  inventory_filters_string = {
    export_nav_flow = {type='flow', style={top_margin=8}, direction='horizontal', children={
      {type='button', style='back_button', caption={'gui.cancel'}, handlers='back_button'},
      {type='empty-widget', style={name='draggable_space', height=32, horizontally_stretchable=true}, save_as='lower_drag_handle'}
    }},
    import_nav_flow = {type='flow', style={top_margin=8}, direction='horizontal', children={
      {type='button', style='back_button', caption={'gui.cancel'}, handlers='back_button'},
      {type='empty-widget', style={name='draggable_space', height=32, horizontally_stretchable=true}, save_as='lower_drag_handle'},
      {type='button', style='confirm_button', caption={'gui.confirm'}, mods={enabled=false}, handlers='confirm_button', save_as=true}
    }}
  }
}

gui.add_handlers{
  inventory_filters_buttons = {
    import_export_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        if player_table.gui.inventory_filters_string then
          gui.destroy(player_table.gui.inventory_filters_string.window, 'inventory_filters_string', e.player_index)
        end
        local mode = e.element.sprite:find('export') and 'export' or 'import'
        local gui_data = gui.create(player.gui.screen, 'inventory_filters_string', e.player_index,
          {type='frame', style='dialog_frame', direction='vertical', save_as='window', children={
            {type='flow', style='ee_titlebar_flow', direction='horizontal', children={
              {type='label', style='frame_title', caption={'ee-gui.'..mode..'-inventory-filters'}},
              {type='empty-widget', style={name='draggable_space_header', height=24, horizontally_stretchable=true}, save_as='drag_handle'}
            }},
            {type='text-box', style={width=400, height=300}, clear_and_focus_on_right_click=true, mods={word_wrap=true},
              handlers=(mode == 'import' and 'textbox' or nil), save_as='textbox'},
            {template='inventory_filters_string.'..mode..'_nav_flow'}
          }}
        )
        gui_data.drag_handle.drag_target = gui_data.window
        gui_data.lower_drag_handle.drag_target = gui_data.window
        gui_data.window.force_auto_center()
        gui_data.textbox.focus()

        if mode == 'export' then
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
          gui.destroy(player_table.gui.inventory_filters_buttons.window, 'inventory_filters_buttons', e.player_index)
          player_table.gui.inventory_filters_buttons = nil
        end
      end
    },
    player = {
      on_player_toggled_map_editor = function(e)
        -- close the GUI if the player exits the map editor
        local player_table = global.players[e.player_index]
        gui.destroy(player_table.gui.inventory_filters_buttons.window, 'inventory_filters_buttons', e.player_index)
        player_table.gui.inventory_filters_buttons = nil
        if player_table.gui.inventory_filters_string then
          gui.destroy(player_table.gui.inventory_filters_string.window, 'inventory_filters_string', e.player_index)
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
        gui.destroy(player_table.gui.inventory_filters_string.window, 'inventory_filters_string', e.player_index)
        player_table.gui.inventory_filters_string = nil
      end
    },
    confirm_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.inventory_filters_string
        if import_filters(player, gui_data.textbox.text) then
          gui.destroy(gui_data.window, 'inventory_filters_string', e.player_index)
          player_table.gui.inventory_filters_string = nil
        else
          player.print{'ee-message.invalid-inventory-filters-string'}
        end
      end
    },
    textbox = {
      on_gui_text_changed = function(e)
        local gui_data = global.players[e.player_index].gui.inventory_filters_string
        if e.element.text == '' then
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
      local gui_data = gui.create(player.gui.screen, 'inventory_filters_buttons', player.index,
        {type='frame', style={name='shortcut_bar_window_frame', right_padding=4}, save_as='window', children={
          {type='frame', style='shortcut_bar_inner_panel', direction='horizontal', children={
            {type='sprite-button', style='shortcut_bar_button', sprite='ee-import-inventory-filters', tooltip={'ee-gui.import-inventory-filters'},
              save_as='import_button'},
            {type='sprite-button', style='shortcut_bar_button', sprite='ee-export-inventory-filters', tooltip={'ee-gui.export-inventory-filters'},
              save_as='export_button'}
          }}
        }}
      )
      -- register events
      gui.register_handlers('inventory_filters_buttons', 'player', {player_index=e.player_index})
      gui.register_handlers('inventory_filters_buttons', 'import_export_button', {player_index=e.player_index,
        gui_filters={gui_data.import_button, gui_data.export_button}})
      gui.register_handlers('inventory_filters_buttons', 'inventory_window', {player_index=e.player_index})
      -- add to global
      player_table.gui.inventory_filters_buttons = gui_data
      -- position GUI
      gui.call_handler('inventory_filters_buttons.player.on_player_display_resolution_changed', {player_index=e.player_index})
    end
  end
end)

-- -----------------------------------------------------------------------------
-- OBJECT

return {
  import_inventory_filters = import_filters
}