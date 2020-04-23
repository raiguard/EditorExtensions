-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- dependencies
local event = require("__RaiLuaLib__.lualib.event")
local migration = require("__RaiLuaLib__.lualib.migration")
local util = require("scripts.util")

-- locals
local string_find = string.find
local string_gsub = string.gsub
local string_sub = string.sub

-- -----------------------------------------------------------------------------
-- SCRIPTS

require("scripts.infinity-accumulator")
require("scripts.infinity-combinator")
require("scripts.infinity-loader")
require("scripts.infinity-wagon")
require("scripts.tesseract-chest")

local inventory = require("scripts.inventory")

-- -----------------------------------------------------------------------------
-- CHEAT MODE

local function enable_recipes(player, skip_message)
  local force = player.force
  -- check if it has already been enabled for this force
  if force.recipes["ee-infinity-loader"].enabled == false then
    for n,_ in pairs(game.recipe_prototypes) do
      if string_find(n, "^ee%-") and force.recipes[n] then force.recipes[n].enabled = true end
    end
    if not skip_message then
      force.print{"ee-message.testing-tools-enabled", player.name}
    end
  end
end

event.on_player_cheat_mode_enabled(function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  enable_recipes(player)
  inventory.toggle_sync(player, player_table)
end)

event.on_player_cheat_mode_disabled(function(e)
  inventory.toggle_sync(game.get_player(e.player_index), global.players[e.player_index], false)
end)

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
  for i=1,#equipment_to_add do
    grid.put(equipment_to_add[i])
  end
end

event.on_console_command(function(e)
  if e.command == "cheat" and e.parameters == "all" then
    local player = game.get_player(e.player_index)
    if player.cheat_mode then
      -- remove default items
      local main_inventory = player.get_main_inventory()
      for i=1,#items_to_remove do
        main_inventory.remove(items_to_remove[i])
      end
      -- add custom items
      for i=1,#items_to_add do
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
  end
end)

-- -----------------------------------------------------------------------------
-- PLAYER DATA / BOOTSTRAP

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
  for name, t in pairs(player.mod_settings) do
    if string_sub(name, 1,3) == "ee-" then
      name = string_gsub(name, "^ee%-", "")
      settings[string_gsub(name, "%-", "_")] = t.value
    end
  end
  player_table.settings = settings
end

local function refresh_player_data(player, player_table)
  -- set shortcut state
  player.set_shortcut_available("ee-toggle-map-editor", player.admin)

  -- update settings
  update_player_settings(player, player_table)
end

event.on_init(function()
  global.combinators = {}
  global.flags = {
    map_editor_toggled = false
  }
  global.players = {}
  for i,p in pairs(game.players) do
    setup_player(i)
    refresh_player_data(p, global.players[i])
    if p.cheat_mode then
      enable_recipes(p)
    end
  end
end)

event.on_player_created(function(e)
  setup_player(e.player_index)
  refresh_player_data(game.get_player(e.player_index), global.players[e.player_index])
end, nil, {insert_at=1})

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

event.on_runtime_mod_setting_changed(function(e)
  if string_sub(e.setting, 1, 3) == "ee-" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    update_player_settings(player, player_table)
    if e.setting == "ee-inventory-sync" then
      inventory.toggle_sync(player, player_table)
    end
  end
end)

-- -----------------------------------------------------------------------------
-- MAP EDITOR SHORTCUT

event.register({defines.events.on_lua_shortcut, "ee-toggle-map-editor"}, function(e)
  if e.prototype_name and e.prototype_name ~= "ee-toggle-map-editor" then return end
  local player = game.get_player(e.player_index)
  player.toggle_map_editor()
  player.set_shortcut_toggled("ee-toggle-map-editor", player.controller_type == defines.controllers.editor)
  -- the first time someone toggles the map editor, unpause the current tick
  if global.flags.map_editor_toggled == false then
    global.flags.map_editor_toggled = true
    game.tick_paused = false
  end
end)

event.on_player_toggled_map_editor(function(e)
  -- set map editor shortcut state
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local new_state = player.controller_type == defines.controllers.editor
  player.set_shortcut_toggled("ee-toggle-map-editor", new_state)
  -- set default filters
  if new_state and not player_table.flags.map_editor_toggled then
    player_table.flags.map_editor_toggled = true
    local default_filters = player.mod_settings["ee-default-inventory-filters"].value
    if default_filters ~= "" then
      inventory.import_inventory_filters(player, default_filters)
    end
  end
end)

-- lock or unlock the editor depending on if the player is an admin
event.register({defines.events.on_player_promoted, defines.events.on_player_demoted}, function(e)
  local player = game.get_player(e.player_index)
  player.set_shortcut_available("ee-toggle-map-editor", player.admin)
end)

-- -----------------------------------------------------------------------------
-- INFINITY INSERTER

-- set manually built inserters to blacklist mode by default
event.on_built_entity(function(e)
  local entity = e.created_entity
  if entity.name == "ee-infinity-inserter" then
    local control = entity.get_control_behavior()
    if not control then
      -- this is a new inserter, so set control mode to blacklist by default
      entity.inserter_filter_mode = "blacklist"
    end
  end
end)

-- -----------------------------------------------------------------------------
-- INFINITY PIPE

-- snap manually built infinity pipes
event.on_built_entity(function(e)
  local entity = e.created_entity
  if entity.name == "ee-infinity-pipe" then
    local neighbours = entity.neighbours[1]
    local own_fb = entity.fluidbox
    local own_id = entity.unit_number
    local s = settings.get_player_settings(e.player_index)
    -- snap to adjacent assemblers
    if s["ee-infinity-pipe-assembler-snapping"].value then
      for ni=1,#neighbours do
        local neighbour = neighbours[ni]
        if neighbour.type == "assembling-machine" and neighbour.fluidbox then
          local fb = neighbour.fluidbox
          for i=1,#fb do
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
    if s["ee-infinity-pipe-snapping"].value then
      local fluid = own_fb.get_locked_fluid(1)
      if fluid then
        entity.set_infinity_pipe_filter{name=fluid, percentage=0, mode="exactly"}
      end
    end
  end
end)

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
-- EVENT FILTERS

-- Add filters to all events that support them so we can preserve as much performance as possible
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

-- -----------------------------------------------------------------------------
-- MIGRATIONS

-- table of migration functions
local migrations = {
  ["1.1.0"] = function()
    -- enable infinity equipment recipes, hide electric energy interface recipe
    for _,force in pairs(game.forces) do
      local recipes = force.recipes
      if recipes["ee-infinity-loader"].enabled then
        recipes["electric-energy-interface"].enabled = false
        recipes["ee-infinity-exoskeleton-equipment"].enabled = true
        recipes["ee-infinity-fusion-reactor-equipment"].enabled = true
        recipes["ee-infinity-personal-roboport-equipment"].enabled = true
      end
    end
    -- enable recipes for any players who already have cheat mode enabled
    for _,player in pairs(game.players) do
      if player.cheat_mode then
        enable_recipes(player)
      end
    end
  end,
  ["1.2.0"] = function()
    local player_tables = global.players
    for i,p in pairs(game.players) do
      -- set map editor toggled flag to true
      player_tables[i].flags.map_editor_toggled = true
      if p.mod_settings["ee-inventory-sync"].value and p.cheat_mode then
        -- enable events for inventory sync
        event.enable_group("inventory_sync", i)
      end
    end
  end,
  ["1.3.0"] = function()
    -- enable infintiy heat pipe recipe
    for _,force in pairs(game.forces) do
      local recipes = force.recipes
      if recipes["ee-infinity-loader"].enabled then
        recipes["ee-infinity-heat-pipe"].enabled = true
      end
    end
  end,
  ["1.3.1"] = function()
    -- update all infinity wagon names in global
    for _,t in pairs(global.wagons) do
      t.wagon_name = "ee-"..t.wagon_name
    end
  end,
  ["1.4.0"] = function()
    -- remove any sync chests that have somehow remained (LuziferSenpai...)
    for _, player_table in pairs(global.players) do
      player_table.sync_chests = nil
    end
    -- add flag to all players for inventory sync
    for i, player in pairs(game.players) do
      local player_table = global.players[i]
      -- we don't have a settings table yet (that will be created in generic migrations) so do it manually
      player_table.flags.inventory_sync_enabled = player.mod_settings["ee-inventory-sync"].value and player.cheat_mode
    end
    -- remove cursor sync event data
    for _, name in ipairs{"inventory_sync_pre_toggled_editor", "inventory_sync_toggled_editor"} do
      local __event = global.__lualib.event
      local event_data = __event.conditional_events[name]
      local players = __event.players
      if event_data then
        for _, player_index in ipairs(event_data.players) do
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

-- handle migrations
event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    for i, player in pairs(game.players) do
      refresh_player_data(player, global.players[i])
    end
  end
end, nil, {insert_at=1})