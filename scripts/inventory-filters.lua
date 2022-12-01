local gui = require("__flib__/gui-lite")
local migration = require("__flib__/migration")

local inventory_filters = {}

local filters_table_version = 0
local filters_table_migrations = {}

--- @param player LuaPlayer
--- @param string string
function inventory_filters.import(player, string)
  local decoded_string = game.decode_string(string)
  if
    decoded_string
    and string.sub(decoded_string, 1, 16) == "EditorExtensions"
    and string.sub(decoded_string, 18, 34) == "inventory_filters"
  then
    -- Extract version for migrations
    local _, _, version, json = string.find(decoded_string, "^.-%-.-%-(%d-)%-(.*)$")
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
function inventory_filters.export(player)
  local filters = player.infinity_inventory_filters
  local output = {
    filters = filters,
    remove_unfiltered_items = player.remove_unfiltered_items,
  }
  return game.encode_string(
    "EditorExtensions-inventory_filters-" .. filters_table_version .. "-" .. game.table_to_json(output)
  )
end

local string_gui = {}

--- @param player LuaPlayer
--- @param mode string
function string_gui.build(player, mode)
  local elems = gui.add(player.gui.screen, {
    type = "frame",
    name = "ee_inventory_filters_window",
    direction = "vertical",
    caption = { "ee-gui." .. mode .. "-infinity-filters" },
    elem_mods = { auto_center = true },
    {
      type = "text-box",
      name = "textbox",
      style_mods = { width = 400, height = 300 },
      clear_and_focus_on_right_click = true,
      text = mode == "import" and "" or inventory_filters.export(player),
      elem_mods = { word_wrap = true },
    },
    {
      type = "flow",
      style = "dialog_buttons_horizontal_flow",
      drag_target = "ee_inventory_filters_window",
      {
        type = "button",
        style = "back_button",
        caption = { "gui.cancel" },
        handler = { [defines.events.on_gui_click] = string_gui.destroy },
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
        handler = { [defines.events.on_gui_click] = string_gui.import },
      },
    },
  })

  elems.textbox.select_all()
  elems.textbox.focus()
end

--- @param player LuaPlayer
--- @param e on_gui_click|on_gui_closed?
function string_gui.destroy(player, e)
  local window = player.gui.screen.ee_inventory_filters_window
  if window and window.valid then
    window.destroy()

    if e and e.name == defines.events.on_gui_closed then
      -- Keep controller GUI open
      player.opened = defines.gui_type.controller
    end
  end
end

--- @param player LuaPlayer
--- @param e on_gui_click
function string_gui.import(player, e)
  local string = e.element.parent.parent.textbox.text
  if inventory_filters.import(player, string) then
    string_gui.destroy(player)
    util.flying_text(player, { "ee-message.imported-infinity-filters" })
  else
    util.flying_text(player, { "ee-message.invalid-infinity-filters-string" }, true)
  end
end

gui.add_handlers(string_gui, function(e, handler)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  handler(player, e)
end, "filters_string")

local relative_gui = {}

--- @param player LuaPlayer
function relative_gui.build(player)
  gui.add(player.gui.relative, {
    type = "frame",
    name = "ee_inventory_filters_window",
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
        tooltip = { "ee-gui.import-infinity-filters" },
        handler = relative_gui.on_button_click,
      },
      {
        type = "sprite-button",
        name = "export",
        style = "shortcut_bar_button",
        sprite = "ee_export_inventory_filters",
        tooltip = { "ee-gui.export-infinity-filters" },
        handler = relative_gui.on_button_click,
      },
    },
  })
end

--- @param player LuaPlayer
function relative_gui.destroy(player)
  local window = player.gui.relative.ee_inventory_filters_window
  if window and window.valid then
    window.destroy()
  end
  player.gui.screen.clear()
end

--- @param player LuaPlayer
--- @param e on_gui_click
function relative_gui.on_button_click(player, e)
  local mode = e.element.name
  string_gui.destroy(player) -- Just in case
  string_gui.build(player, mode)
end

gui.add_handlers(relative_gui, function(e, handler)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  handler(player, e)
end, "filters_relative")

inventory_filters.relative_gui = relative_gui
inventory_filters.string_gui = string_gui

return inventory_filters
