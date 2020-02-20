-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- debug adapter
pcall(require,'__debugadapter__/debugadapter.lua')

-- dependencies
local event = require('lualib/event')
local migrations = require('lualib/migrations')
local util = require('scripts/util')

-- locals
local string_find = string.find

-- -----------------------------------------------------------------------------
-- SCRIPTS

require('scripts/infinity-accumulator')
require('scripts/infinity-combinator')
require('scripts/infinity-loader')
require('scripts/infinity-wagon')
require('scripts/tesseract-chest')

local inventory = require('scripts/inventory')

-- -----------------------------------------------------------------------------
-- TESTING TOOLS RECIPES

local function enable_recipes(player, skip_message)
  local force = player.force
  -- check if it has already been enabled for this force
  if force.recipes['ee-infinity-loader'].enabled == false then
    for n,_ in pairs(game.recipe_prototypes) do
      if string_find(n, '^ee%-') and force.recipes[n] then force.recipes[n].enabled = true end
    end
    if not skip_message then
      force.print{'ee-message.testing-tools-enabled', player.name}
    end
  end
end

-- enable the testing items when cheat mode is enabled
event.on_player_cheat_mode_enabled(function(e)
  enable_recipes(game.get_player(e.player_index))
end)

-- armor outfit
local armor_outfit = {
  {name='infinity-fusion-reactor-equipment', position={0,0}},
  {name='infinity-personal-roboport-equipment', position={1,0}},
  {name='infinity-exoskeleton-equipment', position={2,0}},
  {name='infinity-exoskeleton-equipment', position={3,0}},
  {name='night-vision-equipment', position={0,1}}
}

-- /ee_cheat command
commands.add_command('ee_cheat', {'ee-message.cheat-command-help'}, function(e)
  local player = game.get_player(e.player_index)
  if player.admin then
    local force = player.force
    -- research all techs for the force
    force.research_all_technologies()
    -- enable cheat mode for the player
    -- this will also unlock the testing tools and notify the force
    player.cheat_mode = true
    -- create outfitted power armor
    player.clean_cursor()
    local cursor_stack = player.cursor_stack
    cursor_stack.set_stack{name='power-armor-mk2'}
    local grid = cursor_stack.grid
    for i=1,#armor_outfit do
      grid.put(armor_outfit[i])
    end
    player.insert(cursor_stack)
    cursor_stack.clear()
    -- insert robots
    player.insert{name='infinity-construction-robot', count=100}
    -- reach distance
    if player.character then
      player.character_build_distance_bonus = 1000000
      player.character_reach_distance_bonus = 1000000
      player.character_resource_reach_distance_bonus = 1000000
    end
  else
    player.print{'ee-message.cheat-command-denied'}
  end
end)

-- -----------------------------------------------------------------------------
-- SETUP AND GENERAL SCRIPTING

local function setup_player(index)
  local data = {
    flags = {
      map_editor_toggled = false
    },
    gui = {
      ic = {
        network_color = 'red',
        sort_mode = 'numerical',
        sort_direction = 'descending',
        update_divider = 30
      }
    }
  }
  global.players[index] = data
  -- set map editor shortcut state
  local player = game.get_player(index)
  player.set_shortcut_toggled('ee-toggle-map-editor', player.controller_type == defines.controllers.editor)
end

-- GENERAL SETUP
event.on_init(function()
  global.combinators = {}
  global.flags = {
    map_editor_toggled = false
  }
  global.players = {}
  for i,p in pairs(game.players) do
    setup_player(i)
    if p.cheat_mode then
      enable_recipes(p)
    end
  end
end)

-- set up player when created
event.on_player_created(function(e)
  setup_player(e.player_index)
end, {insert_at_front=true})

-- destroy player table when removed
event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

-- -----------------------------------------------------------------------------
-- MAP EDITOR SHORTCUT

-- when toggled
event.register({defines.events.on_lua_shortcut, 'ee-toggle-map-editor'}, function(e)
  if e.prototype_name and e.prototype_name ~= 'ee-toggle-map-editor' then return end
  local player = game.get_player(e.player_index)
  player.toggle_map_editor()
  player.set_shortcut_toggled('ee-toggle-map-editor', player.controller_type == defines.controllers.editor)
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
  player.set_shortcut_toggled('ee-toggle-map-editor', new_state)
  -- set default filters
  if new_state and not player_table.flags.map_editor_toggled then
    player_table.flags.map_editor_toggled = true
    local default_filters = player.mod_settings['ee-default-inventory-filters'].value
    if default_filters ~= '' then
      inventory.import_inventory_filters(player, default_filters)
    end
  end
end)

-- lock or unlock the editor depending on if the player is an admin
event.register({defines.events.on_player_promoted, defines.events.on_player_demoted}, function(e)
  local player = game.get_player(e.player_index)
  player.set_shortcut_available('ee-toggle-map-editor', player.admin)
end)

-- -----------------------------------------------------------------------------
-- INFINITY INSERTER

-- set manually built inserters to blacklist mode by default
event.on_built_entity(function(e)
  local entity = e.created_entity
  if entity.name == 'infinity-inserter' then
    local control = entity.get_control_behavior()
    if not control then
      -- this is a new inserter, so set control mode to blacklist by default
      entity.inserter_filter_mode = 'blacklist'
    end
  end
end)

-- -----------------------------------------------------------------------------
-- INFINITY PIPE

-- snap manually built infinity pipes
event.on_built_entity(function(e)
  local entity = e.created_entity
  if entity.name == 'infinity-pipe' then
    local neighbours = entity.neighbours[1]
    local own_fb = entity.fluidbox
    local own_id = entity.unit_number
    local s = settings.get_player_settings(e.player_index)
    -- snap to adjacent assemblers
    if s['ee-infinity-pipe-assembler-snapping'].value then
      for ni=1,#neighbours do
        local neighbour = neighbours[ni]
        if neighbour.type == 'assembling-machine' and neighbour.fluidbox then
          local fb = neighbour.fluidbox
          for i=1,#fb do
            local connections = fb.get_connections(i)
            -- local prototype = fb.get_prototype(i)
            -- local production_type = prototype.production_type
            -- local unit_number = connections[1] and connections[1].owner.unit_number
            if connections[1] and (connections[1].owner.unit_number == own_id) and (fb.get_prototype(i).production_type == 'input') then
              -- set to fill the pipe with the fluid
              entity.set_infinity_pipe_filter{name=own_fb.get_locked_fluid(1), percentage=1, mode='exactly'}
              return -- don't do default snapping
            end
          end
        end
      end
    end
    -- snap to locked fluid
    if s['ee-infinity-pipe-snapping'].value then
      local fluid = own_fb.get_locked_fluid(1)
      if fluid then
        entity.set_infinity_pipe_filter{name=fluid, percentage=0, mode='exactly'}
      end
    end
  end
end)

-- -----------------------------------------------------------------------------
-- EVENT FILTERS
-- Add filters to all events that support them so we can preserve as much performance as possible

event.set_filters({defines.events.on_built_entity, defines.events.on_robot_built_entity}, {
  {filter='name', name='infinity-loader-dummy-combinator'},
  {filter='name', name='infinity-loader-logic-combinator'},
  {filter='name', name='infinity-cargo-wagon'},
  {filter='name', name='infinity-fluid-wagon'},
  {filter='name', name='tesseract-chest'},
  {filter='name', name='tesseract-chest-passive-provider'},
  {filter='name', name='infinity-inserter'},
  {filter='name', name='infinity-pipe'},
  {filter='type', type='transport-belt'},
  {filter='type', type='underground-belt'},
  {filter='type', type='splitter'},
  {filter='type', type='loader'},
  {filter='ghost'},
  {filter='ghost_name', name='infinity-loader-logic-combinator'}
})
.set_filters({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity}, {
  {filter='name', name='infinity-accumulator-primary-output'},
  {filter='name', name='infinity-accumulator-primary-input'},
  {filter='name', name='infinity-accumulator-secondary-output'},
  {filter='name', name='infinity-accumulator-secondary-input'},
  {filter='name', name='infinity-accumulator-tertiary'},
  {filter='name', name='infinity-loader-dummy-combinator'},
  {filter='name', name='infinity-loader-logic-combinator'},
  {filter='name', name='infinity-cargo-wagon'},
  {filter='name', name='infinity-fluid-wagon'},
})
.set_filters({defines.events.on_pre_player_mined_item, defines.events.on_marked_for_deconstruction}, {
  {filter='name', name='infinity-cargo-wagon'},
  {filter='name', name='infinity-fluid-wagon'}
})
.set_filters(defines.events.on_cancelled_deconstruction, {
  {filter='name', name='infinity-cargo-wagon'},
  {filter='name', name='infinity-fluid-wagon'}
})

-- -----------------------------------------------------------------------------
-- MIGRATIONS

-- table of migration functions
local version_migrations = {
  ['1.1.0'] = function()
    -- enable infinity equipment recipes, hide electric energy interface recipe
    for _,force in pairs(game.forces) do
      local recipes = force.recipes
      if recipes['ee-infinity-loader'].enabled then
        recipes['electric-energy-interface'].enabled = false
        recipes['ee-infinity-exoskeleton-equipment'].enabled = true
        recipes['ee-infinity-fusion-reactor-equipment'].enabled = true
        recipes['ee-infinity-personal-roboport-equipment'].enabled = true
      end
    end
    -- enable recipes for any players who already have cheat mode enabled
    for _,player in pairs(game.players) do
      if player.cheat_mode then
        enable_recipes(player)
      end
    end
  end,
  ['1.2.0'] = function()
    local player_tables = global.players
    for i,p in pairs(game.players) do
      -- set map editor toggled flag to true
      player_tables[i].flags.map_editor_toggled = true
      if p.cheat_mode then
        -- register events for inventory sync
        event.on_pre_player_toggled_map_editor(inventory.pre_toggled_editor, {name='inventory_sync_pre_toggled_editor', player_index=i})
        event.on_player_toggled_map_editor(inventory.toggled_editor, {name='inventory_sync_toggled_editor', player_index=i})
      end
    end
  end
}

-- handle migrations
event.on_configuration_changed(function(e)
  migrations.on_config_changed(e, version_migrations)
end, {insert_at_front=true})