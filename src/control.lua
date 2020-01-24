
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EDITOR EXTENSIONS CONTROL SCRIPTING

-- debug adapter
pcall(require,'__debugadapter__/debugadapter.lua')

local event = require('lualib/event')
local util = require('lualib/util')

-- locals
local string_find = string.find

-- -----------------------------------------------------------------------------
-- SCRIPTS

do
  require('scripts/infinity-accumulator')
  require('scripts/infinity-combinator')
  require('scripts/infinity-loader')
  require('scripts/infinity-wagon')
  require('scripts/tesseract-chest')
end

-- -----------------------------------------------------------------------------
-- SETUP AND GENERAL SCRIPTING

local function setup_player(index)
  local data = {
    flags = {},
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
  end
end)

-- set up player when created
event.register(defines.events.on_player_created, function(e)
  setup_player(e.player_index)
end)

-- destroy player table when removed
event.register(defines.events.on_player_removed, function(e)
  global.players[e.player_index] = nil
end)

-- map editor shortcut and hotkey
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

event.register(defines.events.on_player_toggled_map_editor, function(e)
  -- set map editor shortcut state
  local player = game.get_player(e.player_index)
  player.set_shortcut_toggled('ee-toggle-map-editor', player.controller_type == defines.controllers.editor)
end)

-- --------------------------------------------------------------------------------
-- INFINITY INSERTER

-- set manually built inserters to blacklist mode by default
event.register(defines.events.on_built_entity, function(e)
  local entity = e.created_entity
  if entity.name == 'infinity-inserter' then
    local control = entity.get_control_behavior()
    if not control then
      -- this is a new inserter, so set control mode to blacklist by default
      entity.inserter_filter_mode = 'blacklist'
    end
  end
end)

-- --------------------------------------------------------------------------------
-- INFINITY PIPE

-- snap manually built infinity pipes
event.register(defines.events.on_built_entity, function(e)
  local entity = e.created_entity
  if entity.name == 'infinity-pipe' then
    local neighbours = entity.neighbours[1]
    local own_fb = entity.fluidbox
    local s = settings.get_player_settings(e.player_index)
    -- snap to adjacent assemblers
    if s['ee-infinity-pipe-assembler-snapping'].value then
      for ni=1,#neighbours do
        local neighbour = neighbours[ni]
        if neighbour.type == 'assembling-machine' and neighbour.fluidbox then
          local fb = neighbour.fluidbox
          for i=1,#fb do
            if fb.get_connections(i)[1] == own_fb and fb.get_prototype(i).production_type == 'input' then
              -- set to fill the pipe with the fluid
              entity.set_infinity_pipe_filter{name=own_fb.get_locked_fluid(i), percentage=1, mode='exactly'}
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

-- --------------------------------------------------------------------------------
-- TESTING TOOLS RECIPES

event.on_player_cheat_mode_enabled(function(e)
  local player = game.get_player(e.player_index)
  local force = player.force
  -- check if it has already been enabled for this force
  if force.recipes['ee-infinity-loader'].enabled == false then
    for n,r in pairs(game.recipe_prototypes) do
      if string_find(n, 'ee-') and force.recipes[n] then force.recipes[n].enabled = true end
    end
    force.print{'ee-message.testing-tools-enabled', player.name}
  end
end)

-- --------------------------------------------------------------------------------
-- EVENT FILTERS
-- Add filters to all events that support them so we can preserve as much performance as possible

event.set_filters({defines.events.on_built_entity, defines.events.on_robot_built_entity}, {
  {filter='name', name='infinity-loader-dummy-combinator'},
  {filter='name', name='infinity-loader-logic-combinator'},
  {filter='name', name='infinity-cargo-wagon'},
  {filter='name', name='infinity-fluid-wagon'},
  {filter='name', name='tesseract-chest'},
  {filter='name', name='tesseract-chest-passive-provider'},
  {filter='name', name='tesseract-chest-storage'},
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

-- DEBUG ADAPTER

if __DebugAdapter then
  script.on_event('DEBUG-INSPECT-GLOBAL', function(e)
    local breakpoint -- put breakpoint here to inspect global at any time
  end)
end