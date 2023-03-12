local content =
  [[Editor Extensions has been updated to 2.0. This version is a BREAKING CHANGE, meaning that your testing setups may not function as they did before.

The infinity loader has been overhauled to fix belt saturation issues, solve edge cases with blueprints, and make them much more UPS efficient. Due to this, [font=default-bold][color=255,50,50]all previously placed infinity loaders will no longer function.[/color][/font] You will need to replace them in order for your testing setups to work again.

Due to game engine limitations, the new infinity loader only supports a single item filter. To put different items on each side of a belt, use two infinity loaders.

Each legacy infinity loader has been located and put into your alerts panel. If you wish to remove them, press the button below, or use the [font=default-bold]/ee-remove-legacy-loaders[/font] command.

There are many other changes, improvements, and new features as well. Please consult the changelog for more details.

Finally, the mod's control scripting has been rewritten from scratch, so there may be a few crashes. Please report any crashes you run into, and I will fix them posthaste. Thank you for your patience, and thank you for using Editor Extensions!

- raiguard]]

local flib_gui = require("__flib__/gui-lite")
local flib_migration = require("__flib__/migration")

local function remove_legacy_loaders()
  for _, loader in pairs(global.legacy_infinity_loaders or {}) do
    if loader.valid then
      loader.destroy()
    end
  end
  global.legacy_infinity_loaders = nil
end

local function on_notification_confirm_clicked(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  local window = player.gui.screen.ee_update_notification_window
  if not window then
    return
  end

  window.destroy()
end

flib_gui.add_handlers({
  on_notification_confirm_clicked = on_notification_confirm_clicked,
  on_notification_remove_legacy_loaders_clicked = remove_legacy_loaders,
})

--- @param player LuaPlayer
local function create_gui(player)
  if player.gui.screen.ee_update_notification_window then
    return
  end

  flib_gui.add(player.gui.screen, {
    type = "frame",
    name = "ee_update_notification_window",
    style_mods = { width = 500 },
    direction = "vertical",
    caption = "Editor Extensions 2.0",
    elem_mods = { auto_center = true },
    {
      type = "frame",
      style = "inside_shallow_frame_with_padding",
      { type = "label", style_mods = { single_line = false }, caption = content },
    },
    {
      type = "flow",
      style = "dialog_buttons_horizontal_flow",
      drag_target = "ee_update_notification_window",
      {
        type = "button",
        style = "red_button",
        style_mods = { height = 32, bottom_padding = 2, font = "default-dialog-button" },
        caption = "[img=utility/warning] Destroy all legacy loaders",
        handler = {
          [defines.events.on_gui_click] = remove_legacy_loaders,
        },
      },
      { type = "empty-widget", style = "flib_dialog_footer_drag_handle", ignored_by_interaction = true },
      {
        type = "button",
        style = "confirm_button",
        caption = { "gui.confirm" },
        handler = { [defines.events.on_gui_click] = on_notification_confirm_clicked },
      },
    },
  })
end

--- @param e BuiltEvent
local function on_entity_built(e)
  local entity = e.entity or e.created_entity or e.destination
  if not entity.valid or entity.name ~= "ee-infinity-loader-dummy-combinator" then
    return
  end
  local loaders = global.legacy_infinity_loaders
  if not loaders then
    loaders = {}
    global.legacy_infinity_loaders = loaders
  end
  loaders[entity.unit_number] = entity
end

local update_notification = {}

--- @param e ConfigurationChangedData
update_notification.on_configuration_changed = function(e)
  local ee_changes = e.mod_changes["EditorExtensions"]
  if
    not ee_changes
    or not ee_changes.old_version
    or flib_migration.is_newer_version("1.99.99", ee_changes.old_version)
  then
    return
  end

  for _, player in pairs(game.players) do
    create_gui(player)
  end

  --- @type table<uint64, LuaEntity>
  local loaders = {}
  for _, surface in pairs(game.surfaces) do
    for _, loader in pairs(surface.find_entities_filtered({ name = "ee-infinity-loader-dummy-combinator" })) do
      loaders[loader.unit_number] = loader
    end
    for _, chest in pairs(surface.find_entities_filtered({ name = "ee-infinity-loader-chest" })) do
      chest.destroy()
    end
  end
  global.legacy_infinity_loaders = loaders
end

update_notification.on_nth_tick = {
  [180] = function()
    if not global.legacy_infinity_loaders then
      return
    end

    for i, legacy in pairs(global.legacy_infinity_loaders) do
      if not legacy.valid then
        global.legacy_infinity_loaders[i] = nil
        goto continue
      end

      for _, player in pairs(legacy.force.players) do
        player.add_custom_alert(
          legacy,
          { type = "item", name = "ee-infinity-loader" },
          "Remove legacy infinity loader",
          true
        )
      end

      ::continue::
    end

    if not next(global.legacy_infinity_loaders) then
      global.legacy_infinity_loaders = nil
    end
  end,
}

commands.add_command("ee-remove-legacy-loaders", nil, function()
  remove_legacy_loaders()
end)

update_notification.events = {
  [defines.events.on_built_entity] = on_entity_built,
  [defines.events.on_entity_cloned] = on_entity_built,
  [defines.events.on_robot_built_entity] = on_entity_built,
  [defines.events.script_raised_built] = on_entity_built,
  [defines.events.script_raised_revive] = on_entity_built,
}

return update_notification
