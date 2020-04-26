local event = require("__flib__.control.event")
local gui = require("__flib__.control.gui")
local migration = require("__flib__.control.migration")
local util = require("scripts.util")

local string_find = string.find
local string_gsub = string.gsub
local string_sub = string.sub

-- require("scripts.infinity-accumulator")
-- require("scripts.infinity-combinator")
-- require("scripts.infinity-loader")
local infinity_wagon = require("scripts.entity.infinity-wagon")
local tesseract_chest = require("scripts.entity.tesseract-chest")

local inventory = require("scripts.inventory")

-- -----------------------------------------------------------------------------
-- CHEAT MODE

local function enable_recipes(player, skip_message)
  local force = player.force
  -- check if it has already been enabled for this force
  if force.recipes["ee-infinity-loader"].enabled == false then
    for n, _ in pairs(game.recipe_prototypes) do
      if string_find(n, "^ee%-") and force.recipes[n] then force.recipes[n].enabled = true end
    end
    if not skip_message then
      force.print{"ee-message.testing-tools-enabled", player.name}
    end
  end
end

local items_to_remove = {
  {name="express-loader", count=50},
  {name="stack-inserter", count=50},
  {name="substation", count=50},
  {name="construction-robot", count=100},
  {name="electric-energy-interface", count=1},
  {name="infinity-chest", count=20},
  {name="infinity-pipe", count=10}
}

local items_to_add = {
  {name="ee-infinity-accumulator", count=50},
  {name="ee-infinity-chest", count=50},
  {name="ee-infinity-construction-robot", count=100},
  {name="ee-infinity-inserter", count=50},
  {name="ee-infinity-pipe", count=50},
  {name="ee-infinity-substation", count=50}
}

local equipment_to_add = {
  {name="ee-infinity-fusion-reactor-equipment", position={0,0}},
  {name="ee-infinity-personal-roboport-equipment", position={1,0}},
  {name="ee-infinity-exoskeleton-equipment", position={2,0}},
  {name="ee-infinity-exoskeleton-equipment", position={3,0}},
  {name="night-vision-equipment", position={0,1}}
}

local function set_armor(inventory)
  inventory[1].set_stack{name="power-armor-mk2"}
  local grid = inventory[1].grid
  for i=1, #equipment_to_add do
    grid.put(equipment_to_add[i])
  end
end

local function set_cheat_loadout(player)
  -- remove default items
  local main_inventory = player.get_main_inventory()
  for i=1, #items_to_remove do
    main_inventory.remove(items_to_remove[i])
  end
  -- add custom items
  for i=1, #items_to_add do
    main_inventory.insert(items_to_add[i])
  end
  if player.controller_type == defines.controllers.character then
    -- increase reach distance
    player.character_build_distance_bonus = 1000000
    player.character_reach_distance_bonus = 1000000
    player.character_resource_reach_distance_bonus = 1000000
    -- overwrite the default armor loadout
    set_armor(player.get_inventory(defines.inventory.character_armor))
  elseif player.controller_type == defines.controllers.editor then
    -- overwrite the default armor loadout
    set_armor(player.get_inventory(defines.inventory.editor_armor))
  end
end

-- -----------------------------------------------------------------------------
-- ENTITY SNAPPING

-- set manually built inserters to blacklist mode by default
local function snap_infinity_inserter(entity)
  local control = entity.get_control_behavior()
  if not control then
    -- this is a new inserter, so set control mode to blacklist by default
    entity.inserter_filter_mode = "blacklist"
  end
end

-- snap manually built infinity pipes
local function snap_infinity_pipe(entity, player_settings)
  local neighbours = entity.neighbours[1]
  local own_fb = entity.fluidbox
  local own_id = entity.unit_number
  -- snap to adjacent assemblers
  if player_settings.infinity_pipe_assembler_snapping then
    for ni=1, #neighbours do
      local neighbour = neighbours[ni]
      if neighbour.type == "assembling-machine" and neighbour.fluidbox then
        local fb = neighbour.fluidbox
        for i=1, #fb do
          local connections = fb.get_connections(i)
          if connections[1] and (connections[1].owner.unit_number == own_id) and (fb.get_prototype(i).production_type == "input") then
            -- set to fill the pipe with the fluid
            entity.set_infinity_pipe_filter{name=own_fb.get_locked_fluid(1), percentage=1, mode="exactly"}
            return -- don't do default snapping
          end
        end
      end
    end
  end
  -- snap to locked fluid
  if player_settings.infinity_pipe_snapping then
    local fluid = own_fb.get_locked_fluid(1)
    if fluid then
      entity.set_infinity_pipe_filter{name=fluid, percentage=0, mode="exactly"}
    end
  end
end

-- -----------------------------------------------------------------------------
-- GLOBAL DATA

local function setup_player(index)
  local data = {
    flags = {
      inventory_sync_enabled = false,
      map_editor_toggled = false
    },
    gui = {
      ic = {
        network_color = "red",
        sort_mode = "numerical",
        sort_direction = "descending",
        update_divider = 30
      }
    }
  }
  global.players[index] = data
end

local function update_player_settings(player, player_table)
  local settings = {}
  for name,  t in pairs(player.mod_settings) do
    if string_sub(name, 1,3) == "ee-" then
      name = string_gsub(name, "^ee%-", "")
      settings[string_gsub(name, "%-", "_")] = t.value
    end
  end
  player_table.settings = settings
end

local function refresh_player_data(player, player_table)
  -- set shortcut availability
  player.set_shortcut_available("ee-toggle-map-editor", player.admin)

  -- update settings
  update_player_settings(player, player_table)
end

local function init_global_data()
  global.combinators = {}
  global.flags = {
    map_editor_toggled = false
  }
  global.players = {}
  for i, p in pairs(game.players) do
    setup_player(i)
    refresh_player_data(p, global.players[i])
    if p.cheat_mode then
      enable_recipes(p)
    end
  end
  global.wagons = {}
end

-- -----------------------------------------------------------------------------
-- COMMANDS

commands.add_command("EditorExtensions", {"ee-message.command-help"}, function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if e.parameter == "toggle-inventory-sync" then
    inventory.toggle_sync(player, player_table, not player_table.flags.inventory_sync_enabled)
  end
end)

-- -----------------------------------------------------------------------------
-- MIGRATIONS

local migrations = {
  ["1.1.0"] = function()
    -- enable infinity equipment recipes, hide electric energy interface recipe
    for _, force in pairs(game.forces) do
      local recipes = force.recipes
      if recipes["ee-infinity-loader"].enabled then
        recipes["electric-energy-interface"].enabled = false
        recipes["ee-infinity-exoskeleton-equipment"].enabled = true
        recipes["ee-infinity-fusion-reactor-equipment"].enabled = true
        recipes["ee-infinity-personal-roboport-equipment"].enabled = true
      end
    end
    -- enable recipes for any players who already have cheat mode enabled
    for _, player in pairs(game.players) do
      if player.cheat_mode then
        enable_recipes(player)
      end
    end
  end,
  ["1.2.0"] = function()
    local player_tables = global.players
    for i, p in pairs(game.players) do
      -- set map editor toggled flag to true
      player_tables[i].flags.map_editor_toggled = true
      if p.mod_settings["ee-inventory-sync"].value and p.cheat_mode then
        -- enable events for inventory sync
        -- REMOVED: the event module no longer exists
        -- event.enable_group("inventory_sync", i)
      end
    end
  end,
  ["1.3.0"] = function()
    -- enable infintiy heat pipe recipe
    for _, force in pairs(game.forces) do
      local recipes = force.recipes
      if recipes["ee-infinity-loader"].enabled then
        recipes["ee-infinity-heat-pipe"].enabled = true
      end
    end
  end,
  ["1.3.1"] = function()
    -- update all infinity wagon names in global
    for _, t in pairs(global.wagons) do
      t.wagon_name = "ee-"..t.wagon_name
    end
  end,
  ["1.4.0"] = function()
    -- remove any sync chests that have somehow remained (LuziferSenpai...)
    for _,  player_table in pairs(global.players) do
      player_table.sync_chests = nil
    end
    -- add flag to all players for inventory sync
    for i,  player in pairs(game.players) do
      local player_table = global.players[i]
      -- we don't have a settings table yet (that will be created in generic migrations) so do it manually
      player_table.flags.inventory_sync_enabled = player.mod_settings["ee-inventory-sync"].value and player.cheat_mode
    end
    -- remove cursor sync event data
    for _,  name in ipairs{"inventory_sync_pre_toggled_editor", "inventory_sync_toggled_editor"} do
      local __event = global.__lualib.event
      local event_data = __event.conditional_events[name]
      local players = __event.players
      if event_data then
        for _,  player_index in ipairs(event_data.players) do
          players[player_index][name] = nil
          if table_size(players[player_index]) == 0 then
            players[player_index] = nil
          end
        end
        __event.conditional_events[name] = nil
      end
    end
  end
}

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  gui.on_init()
  init_global_data()
  tesseract_chest.update_data()
  gui.bootstrap_postprocess()
end)

event.on_load(function()
  gui.bootstrap_postprocess()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    for i,  player in pairs(game.players) do
      refresh_player_data(player, global.players[i])
    end
    tesseract_chest.update_data()
    tesseract_chest.update_all_filters()
  end
end)

-- CHEAT MODE

event.on_player_cheat_mode_enabled(function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  enable_recipes(player)
  inventory.toggle_sync(player, player_table)
end)

event.on_player_cheat_mode_disabled(function(e)
  inventory.toggle_sync(game.get_player(e.player_index), global.players[e.player_index], false)
end)

event.on_console_command(function(e)
  if e.command == "cheat" and e.parameters == "all" then
    local player = game.get_player(e.player_index)
    if player.cheat_mode then
      set_cheat_loadout(player)
    end
  end
end)

-- ENTITIES

event.register(
  {
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive
  },
  function(e)
    local entity = e.entity or e.created_entity
    if string_sub(entity.name, 1, 18) == "ee-tesseract-chest" then
      tesseract_chest.set_filters(entity)
    elseif infinity_wagon.wagon_names[entity.name] then
      infinity_wagon.build(entity, e.tags)
    -- only snap manually built entities
    elseif e.name == defines.events.on_built_entity then
      if entity.name == "ee-infinity-inserter" then
        snap_infinity_inserter(entity)
      elseif entity.name == "ee-infinity-pipe" then
        snap_infinity_pipe(entity, global.players[e.player_index].settings)
      end
    end
  end
)

event.register(
  {
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_entity_died,
    defines.events.script_raised_destroy
  },
  function(e)
    local entity = e.entity
    if infinity_wagon.wagon_names[entity.name] then
      infinity_wagon.destroy(entity)
    end
  end
)

event.register({defines.events.on_pre_player_mined_item, defines.events.on_marked_for_deconstruction}, function(e)
  local entity = e.entity
  if entity.name == "ee-infinity-cargo-wagon" then
    infinity_wagon.clear_inventory(entity)
  end
end)

event.on_cancelled_deconstruction(function(e)
  local entity = e.entity
  infinity_wagon.on_cancelled_deconstruction(entity)
end)

event.register("ee-mouse-leftclick", function(e)
  local player = game.get_player(e.player_index)
  local selected = player.selected
  infinity_wagon.check_and_open(player, selected)
end)

event.on_entity_settings_pasted(function(e)
  infinity_wagon.on_entity_settings_pasted(e)
end)

-- GUI

gui.register_events()

event.on_gui_opened(function(e)
  gui.dispatch_handlers(e)
  infinity_wagon.on_gui_opened(e)
  inventory.on_gui_opened(e)
end)

event.on_gui_closed(function(e)
  gui.dispatch_handlers(e)
  inventory.on_gui_closed(e)
end)

-- MAP EDITOR

event.on_player_toggled_map_editor(function(e)
  -- the first time someone toggles the map editor, unpause the current tick
  if global.flags.map_editor_toggled == false then
    global.flags.map_editor_toggled = true
    game.tick_paused = false
  end

  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local to_state = player.controller_type == defines.controllers.editor

  -- update shortcut toggled state
  player.set_shortcut_toggled("ee-toggle-map-editor", to_state)

  -- apply default inventory filters if this is their first time in the editor
  if to_state and not player_table.flags.map_editor_toggled then
    player_table.flags.map_editor_toggled = true
    local default_filters = player_table.settings.default_inventory_filters
    if default_filters ~= "" then
      inventory.import_inventory_filters(player, default_filters)
    end
  end
end)

-- SHORTCUT

event.on_lua_shortcut(function(e)
  if e.prototype_name == "ee-toggle-map-editor" then
    game.get_player(e.player_index).toggle_map_editor()
  end
end)

event.register("ee-toggle-map-editor", function(e)
  local player = game.get_player(e.player_index)
  if player.admin then
    player.toggle_map_editor()
  else
    player.print{"ee-message.map-editor-denied"}
  end
end)

-- PLAYER

event.on_player_created(function(e)
  setup_player(e.player_index)
  refresh_player_data(game.get_player(e.player_index), global.players[e.player_index])
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

event.register({defines.events.on_player_promoted, defines.events.on_player_demoted}, function(e)
  -- lock or unlock the shortcut depending on if they're an admin
  local player = game.get_player(e.player_index)
  player.set_shortcut_available("ee-toggle-map-editor", player.admin)
end)

event.on_player_setup_blueprint(function(e)
  infinity_wagon.on_player_setup_blueprint(e)
end)

-- SETTINGS

event.on_runtime_mod_setting_changed(function(e)
  if e.setting == "ee-tesseract-include-hidden" then
    tesseract_chest.update_data()
    tesseract_chest.update_all_filters()
  elseif string_sub(e.setting, 1, 3) == "ee-" and e.setting_type == "runtime-per-user" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    update_player_settings(player, player_table)
    if e.setting == "ee-inventory-sync" then
      inventory.toggle_sync(player, player_table)
    end
  end
end)

-- TICK

event.on_tick(function(e)
  infinity_wagon.on_tick()
end)

-- -----------------------------------------------------------------------------
-- EVENT FILTERS

event.set_filters({defines.events.on_built_entity, defines.events.on_robot_built_entity}, {
  {filter="name", name="ee-infinity-loader-dummy-combinator"},
  {filter="name", name="ee-infinity-loader-logic-combinator"},
  {filter="name", name="ee-infinity-cargo-wagon"},
  {filter="name", name="ee-infinity-fluid-wagon"},
  {filter="name", name="ee-tesseract-chest"},
  {filter="name", name="ee-tesseract-chest-passive-provider"},
  {filter="name", name="ee-infinity-inserter"},
  {filter="name", name="ee-infinity-pipe"},
  {filter="type", type="transport-belt"},
  {filter="type", type="underground-belt"},
  {filter="type", type="splitter"},
  {filter="type", type="loader"},
  {filter="ghost"},
  {filter="ghost_name", name="ee-infinity-loader-logic-combinator"}
})

event.set_filters({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity}, {
  {filter="name", name="ee-infinity-accumulator-primary-output"},
  {filter="name", name="ee-infinity-accumulator-primary-input"},
  {filter="name", name="ee-infinity-accumulator-secondary-output"},
  {filter="name", name="ee-infinity-accumulator-secondary-input"},
  {filter="name", name="ee-infinity-accumulator-tertiary"},
  {filter="name", name="ee-infinity-loader-dummy-combinator"},
  {filter="name", name="ee-infinity-loader-logic-combinator"},
  {filter="name", name="ee-infinity-cargo-wagon"},
  {filter="name", name="ee-infinity-fluid-wagon"},
})

event.set_filters({defines.events.on_pre_player_mined_item, defines.events.on_marked_for_deconstruction}, {
  {filter="name", name="ee-infinity-cargo-wagon"},
  {filter="name", name="ee-infinity-fluid-wagon"}
})

event.set_filters(defines.events.on_cancelled_deconstruction, {
  {filter="name", name="ee-infinity-cargo-wagon"},
  {filter="name", name="ee-infinity-fluid-wagon"}
})