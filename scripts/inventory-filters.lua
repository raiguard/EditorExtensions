local gui = require("__flib__/gui")
local migration = require("__flib__/migration")

local inventory_filters = {}

-- -----------------------------------------------------------------------------
-- INFINITY INVENTORY FILTERS

local filters_table_version = 0
local filters_table_migrations = {}

function inventory_filters.import_filters(player, string)
  local decoded_string = game.decode_string(string)
  if
    decoded_string
    and string.sub(decoded_string, 1, 16) == "EditorExtensions"
    and string.sub(decoded_string, 18, 34) == "inventory_filters"
  then
    -- extract version for migrations
    local _, _, version, json = string.find(decoded_string, "^.-%-.-%-(%d-)%-(.*)$")
    local input = game.json_to_table(json)
    if input then
      -- run migrations
      migration.run(version, filters_table_migrations, nil, input)
      -- sanitize the filters to only include currently existing prototypes
      local item_prototypes = game.item_prototypes
      local output = {}
      local output_index = 0
      local filters = input.filters
      for i = 1, #filters do
        local filter = filters[i]
        if item_prototypes[filter.name] then
          output_index = output_index + 1
          output[output_index] = { name = filter.name, count = filter.count, mode = filter.mode, index = output_index }
        end
      end
      player.infinity_inventory_filters = output
      player.remove_unfiltered_items = input.remove_unfiltered_items
      return true
    end
  end
  return false
end

local function export_filters(player)
  local filters = player.infinity_inventory_filters
  local output = {
    filters = filters,
    remove_unfiltered_items = player.remove_unfiltered_items,
  }
  return game.encode_string(
    "EditorExtensions-inventory_filters-" .. filters_table_version .. "-" .. game.table_to_json(output)
  )
end

-- -----------------------------------------------------------------------------
-- INFINITY INVENTORY FILTERS GUI

--- @param player LuaPlayer
--- @param player_table PlayerTable
--- @param mode string
local function open_string_gui(player, player_table, mode)
  -- create GUI
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      ref = { "window" },
      children = {
        {
          type = "flow",
          style = "flib_titlebar_flow",
          ref = { "titlebar_flow" },
          children = {
            {
              type = "label",
              style = "frame_title",
              caption = { "ee-gui." .. mode .. "-infinity-filters" },
              ignored_by_interaction = true,
            },
            { type = "empty-widget", style = "flib_dialog_titlebar_drag_handle", ignored_by_interaction = true },
          },
        },
        {
          type = "frame",
          style = "inside_shallow_frame_with_padding",
          children = {
            {
              type = "text-box",
              style_mods = { width = 400, height = 300 },
              clear_and_focus_on_right_click = true,
              text = mode == "import" and "" or export_filters(player),
              elem_mods = { word_wrap = true },
              actions = (
                mode == "import"
                  and {
                    on_text_changed = { gui = "inv_filters", action = "update_confirm_button_enabled" },
                  }
                or nil
              ),
              ref = { "textbox" },
            },
          },
        },
        {
          type = "flow",
          style = "dialog_buttons_horizontal_flow",
          children = {
            {
              type = "button",
              style = "back_button",
              caption = { "gui.cancel" },
              actions = { on_click = { gui = "inv_filters", action = "close_string_gui" } },
            },
            {
              type = "empty-widget",
              style = "flib_dialog_footer_drag_handle",
              style_mods = mode == "export" and { right_margin = 0 } or nil,
              ref = { "footer_drag_handle" },
            },
            (mode == "import" and {
              type = "button",
              style = "confirm_button",
              caption = { "gui.confirm" },
              elem_mods = { enabled = false },
              actions = { on_click = { gui = "inv_filters", action = "import_filters" } },
              ref = { "confirm_button" },
            } or nil),
          },
        },
      },
    },
  })

  refs.textbox.select_all()
  refs.textbox.focus()

  refs.titlebar_flow.drag_target = refs.window
  refs.footer_drag_handle.drag_target = refs.window

  refs.window.force_auto_center()

  player_table.gui.inventory_filters_string = refs
end

--- @param player_table PlayerTable
local function close_string_gui(player_table)
  local refs = player_table.gui.inventory_filters_string
  refs.window.destroy()
  player_table.gui.inventory_filters_string = nil
end

--- @param player LuaPlayer
--- @param player_table PlayerTable
function inventory_filters.create_filters_buttons(player, player_table)
  local refs = gui.build(player.gui.relative, {
    {
      type = "frame",
      style = "quick_bar_window_frame",
      ref = { "window" },
      anchor = {
        gui = "controller-gui",
        position = defines.relative_gui_position.left,
        name = "editor",
      },
      children = {
        {
          type = "frame",
          style = "shortcut_bar_inner_panel",
          direction = "vertical",
          children = {
            {
              type = "sprite-button",
              style = "shortcut_bar_button",
              sprite = "ee_import_inventory_filters",
              tooltip = { "ee-gui.import-infinity-filters" },
              tags = { mode = "import" },
              actions = { on_click = { gui = "inv_filters", action = "open_string_gui" } },
            },
            {
              type = "sprite-button",
              style = "shortcut_bar_button",
              sprite = "ee_export_inventory_filters",
              tooltip = { "ee-gui.export-infinity-filters" },
              tags = { mode = "export" },
              actions = { on_click = { gui = "inv_filters", action = "open_string_gui" } },
            },
          },
        },
      },
    },
  })

  player_table.gui.inventory_filters_buttons = refs
end

--- @param player_table PlayerTable
function inventory_filters.destroy_filters_buttons(player_table)
  local buttons_gui_data = player_table.gui.inventory_filters_buttons
  if buttons_gui_data then
    player_table.gui.inventory_filters_buttons.window.destroy()
    player_table.gui.inventory_filters_buttons = nil
  end
end

--- @param player_index uint
function inventory_filters.close_string_gui(player_index)
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]
  local guis = player_table.gui

  if guis.inventory_filters_string then
    close_string_gui(player_table)
    -- keep controller GUI open
    player.opened = defines.gui_type.controller
  end
end

function inventory_filters.handle_gui_action(e, msg)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local player_table = global.players[e.player_index]
  local refs = player_table.gui.inventory_filters_string

  if msg.action == "open_string_gui" then
    if refs then
      close_string_gui(player_table)
    end
    open_string_gui(player, player_table, gui.get_tags(e.element).mode)
  elseif msg.action == "close_string_gui" then
    close_string_gui(player_table)
  elseif msg.action == "update_confirm_button_enabled" then
    if #refs.textbox.text > 0 then
      refs.confirm_button.enabled = true
    else
      refs.confirm_button.enabled = false
    end
  elseif msg.action == "import_filters" then
    local string = refs.textbox.text

    if inventory_filters.import_filters(player, string) then
      close_string_gui(player_table)
      player.create_local_flying_text({
        text = { "ee-message.imported-infinity-filters" },
        create_at_cursor = true,
      })
    else
      player.create_local_flying_text({
        text = { "ee-message.invalid-infinity-filters-string" },
        create_at_cursor = true,
      })
      player.play_sound({ path = "utility/cannot_build", volume_modifier = 0.75 })
    end
  end
end

return inventory_filters
