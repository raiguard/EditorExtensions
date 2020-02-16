-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY

-- dependencies
local event = require('lualib/event')
local gui = require('lualib/gui')

-- -----------------------------------------------------------------------------
-- INVENTORY AND CURSOR STACK SYNC

-- -- sync the inventory when they go in/out of the editor
-- local function on_player_toggled_map_editor(e)
  
-- end

-- -- toggle the sync when the player goes in/out of cheat mode
-- event.register({defines.events.on_player_cheat_mode_enabled, defines.events.on_player_cheat_mode_disabled}, function(e)
--   local player = game.get_player(e.player_index)
--   local player_table = global.players[e.player_index]
--   local cheat_mode = player.cheat_mode
--   if cheat_mode and player.mod_settings['ee-inventory-and-cursor-sync'].value then
--     player_table.flags.inventory_sync = true
--   else
--     player_table.flags.inventory_sync = false
--   end
-- end)

-- -----------------------------------------------------------------------------
-- INFINITY INVENTORY FILTERS

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
            {type='text-box', style={width=400, height=300}, clear_and_focus_on_right_click=true, handlers=(mode == 'import' and 'textbox' or nil),
              save_as='textbox'},
            {template='inventory_filters_string.'..mode..'_nav_flow'}
          }}
        )
        gui_data.drag_handle.drag_target = gui_data.window
        gui_data.lower_drag_handle.drag_target = gui_data.window
        gui_data.window.force_auto_center()
        gui_data.textbox.focus()

        if mode == 'export' then
          -- TODO: export filters!
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
        -- TODO: import filters!
        local player_table = global.players[e.player_index]
        gui.destroy(player_table.gui.inventory_filters_string.window, 'inventory_filters_string', e.player_index)
        player_table.gui.inventory_filters_string = nil
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