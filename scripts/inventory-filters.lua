local gui = require("__flib__/gui-lite")
local migration = require("__flib__/migration")

local util = require("__EditorExtensions__/scripts/util")

local filters_table_version = 0
local filters_table_migrations = {}

--- @param player LuaPlayer
--- @param string string
local function import_filters(player, string)
  if string == "" then
    return
  end
  local decoded_string = game.decode_string(string)
  if
    decoded_string
    and string.sub(decoded_string, 1, 16) == "EditorExtensions"
    and string.sub(decoded_string, 18, 34) == "inventory_filters"
  then
    -- Extract version for migrations
    local version, json = string.match(decoded_string, "^.-%-.-%-(%d-)%-(.*)$")
    local input = game.json_to_table(json)
    if input then
      -- Run migrations
      migration.run(version, filters_table_migrations, nil, input)
      -- Sanitize the filters to only include currently existing prototypes
      local item_prototypes = game.item_prototypes
      local output = {}
      local i = 0
      local filters = input.filters
      for _, filter in pairs(filters) do
        if item_prototypes[filter.name] then
          i = i + 1
          filter.index = i
          output[i] = filter
        end
      end
      player.infinity_inventory_filters = output
      player.remove_unfiltered_items = input.remove_unfiltered_items
      return true
    end
  end
  return false
end

--- @param player LuaPlayer
--- @return string?
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

-- String GUI

--- @param player LuaPlayer
--- @return boolean
local function destroy_string_gui(player)
  local window = player.gui.screen.ee_inventory_filters
  if not window or not window.valid then
    return false
  end

  window.destroy()

  return true
end

--- @param e EventData.on_gui_click
local function on_string_gui_import_click(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  local string = e.element.parent.parent.textbox.text
  if import_filters(player, string) then
    destroy_string_gui(player)
    util.flying_text(player, { "message.ee-imported-infinity-filters" })
  else
    util.flying_text(player, { "message.ee-invalid-infinity-filters-string" }, true)
  end
end

--- @param e EventData.on_gui_click
local function on_string_gui_cancel_click(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  destroy_string_gui(player)

  -- Keep controller GUI open
  player.opened = defines.gui_type.controller
end

--- @param player LuaPlayer
--- @param mode string
local function build_string_gui(player, mode)
  destroy_string_gui(player)
  local elems = gui.add(player.gui.screen, {
    type = "frame",
    name = "ee_inventory_filters",
    direction = "vertical",
    caption = { "gui.ee-" .. mode .. "-infinity-filters" },
    elem_mods = { auto_center = true },
    {
      type = "text-box",
      name = "textbox",
      style_mods = { width = 400, height = 300 },
      clear_and_focus_on_right_click = true,
      text = mode == "import" and "" or export_filters(player),
      elem_mods = { word_wrap = true },
    },
    {
      type = "flow",
      style = "dialog_buttons_horizontal_flow",
      drag_target = "ee_inventory_filters",
      {
        type = "button",
        style = "back_button",
        caption = { "gui.cancel" },
        handler = on_string_gui_cancel_click,
      },
      {
        type = "empty-widget",
        style = "flib_dialog_footer_drag_handle",
        style_mods = mode == "export" and { right_margin = 0 } or nil,
        ignored_by_interaction = true,
      },
      {
        type = "button",
        style = "confirm_button",
        caption = { "gui.confirm" },
        visible = mode == "import",
        handler = on_string_gui_import_click,
      },
    },
  })

  elems.textbox.select_all()
  elems.textbox.focus()
end

-- Relative GUI

--- @param player LuaPlayer
local function destroy_relative_gui(player)
  local window = player.gui.relative.ee_inventory_filters
  if window and window.valid then
    window.destroy()
  end
end

--- @param e EventData.on_gui_click
local function on_relative_gui_button_click(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  local mode = e.element.name
  build_string_gui(player, mode)
end

--- @param player LuaPlayer
local function build_relative_gui(player)
  destroy_relative_gui(player)
  gui.add(player.gui.relative, {
    type = "frame",
    name = "ee_inventory_filters",
    style = "quick_bar_window_frame",
    anchor = {
      gui = defines.relative_gui_type.controller_gui,
      position = defines.relative_gui_position.left,
      name = "editor",
    },
    {
      type = "frame",
      style = "shortcut_bar_inner_panel",
      direction = "vertical",
      {
        type = "sprite-button",
        name = "import",
        style = "shortcut_bar_button",
        sprite = "ee_import_inventory_filters",
        tooltip = { "gui.ee-import-infinity-filters" },
        handler = on_relative_gui_button_click,
      },
      {
        type = "sprite-button",
        name = "export",
        style = "shortcut_bar_button",
        sprite = "ee_export_inventory_filters",
        tooltip = { "gui.ee-export-infinity-filters" },
        handler = on_relative_gui_button_click,
      },
    },
  })
end

--- @param e EventData.on_gui_closed
local function on_gui_closed(e)
  if e.gui_type ~= defines.gui_type.controller then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  if destroy_string_gui(player) then
    player.opened = defines.gui_type.controller
  end
end

--- @param e EventData.on_player_toggled_map_editor
local function on_player_toggled_map_editor(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local in_editor = player.controller_type == defines.controllers.editor
  if not in_editor or global.applied_default_filters[e.player_index] then
    return
  end

  -- Apply default infinity filters if this is their first time in the editor
  global.applied_default_filters[e.player_index] = true
  local default_filters = player.mod_settings["ee-default-infinity-filters"].value --[[@as string]]
  if default_filters == "" then
    return
  end
  import_filters(player, default_filters)
end

--- @param e EventData.on_player_created
local function on_player_created(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  build_relative_gui(player)
end

--- @param e EventData.on_player_removed
local function on_player_removed(e)
  if global.applied_default_filters then
    global.applied_default_filters[e.player_index] = nil
  end
end

local inventory_filters = {}

inventory_filters.on_init = function()
  --- @type table<uint, boolean>
  global.applied_default_filters = {}
end

inventory_filters.on_configuration_changed = function()
  for _, player in pairs(game.players) do
    destroy_string_gui(player)
    build_relative_gui(player)
  end
end

inventory_filters.events = {
  [defines.events.on_gui_closed] = on_gui_closed,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_removed] = on_player_removed,
  [defines.events.on_player_toggled_map_editor] = on_player_toggled_map_editor,
}

gui.add_handlers({
  destroy_string_gui = destroy_string_gui,
  on_relative_gui_button_click = on_relative_gui_button_click,
  on_string_gui_cancel_click = on_string_gui_cancel_click,
  on_string_gui_import_click = on_string_gui_import_click,
})

return inventory_filters
