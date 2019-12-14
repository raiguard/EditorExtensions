-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EDITOR EXTENSIONS CONTROL SCRIPTING

local event = require('lualib/event')
local util = require('lualib/util')

-- --------------------------------------------------------------------------------
-- SCRIPTS

do
  require('scripts/infinity-accumulator')
  require('scripts/infinity-combinator')
  require('scripts/infinity-loader')
  require('scripts/infinity-wagon')
  require('scripts/tesseract-chest')
end

-- --------------------------------------------------------------------------------
-- SETUP AND GENERAL SCRIPTING

local function setup_player(index)
  local data = {
    flags = {},
    gui = {
      ic = {
        network_color = 'red',
        sort_mode = 'numerical',
        sort_direction = 'descending'
      }
    }
  }
  global.players[index] = data
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

event.register(defines.events.on_player_created, function(e)
  setup_player(e.player_index)
end)

-- map editor shortcut and hotkey
event.register({defines.events.on_lua_shortcut, 'ee-toggle-map-editor'}, function(e)
  if e.prototype_name and e.prototype_name ~= 'ee-toggle-map-editor' then return end
  local player = util.get_player(e)
  player.toggle_map_editor()
  player.set_shortcut_toggled('ee-toggle-map-editor', player.controller_type == defines.controllers.editor)
  -- the first time someone toggles the map editor, unpause the current tick
  if global.flags.map_editor_toggled == false then
    global.flags.map_editor_toggled = true
    game.tick_paused = false
  end
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
    local mod_settings = util.get_player(e).mod_settings
    -- default snapping
    if mod_settings['ee-infinity-pipe-snapping'].value then
      -- get own fluidbox
      local own_fluidbox = entity.fluidbox
      if own_fluidbox.get_locked_fluid(1) then
        entity.set_infinity_pipe_filter{name=own_fluidbox.get_locked_fluid(1), percentage=0, mode='exactly'}
      end
    end
    -- assembler snapping
    if mod_settings['ee-infinity-pipe-assembler-snapping'].value then
      -- get own fluidbox
      local own_fluidbox = entity.fluidbox
      -- for every connection the infinity pipe has
      for _,fb in ipairs(own_fluidbox.get_connections(1)) do
        -- if it's connected to an assembling machine
        if fb.owner.type == 'assembling-machine' then
          -- for every fluidbox in the assembling machine
          for i=1,#fb do
            -- if it's an input connection, and it's connected to us
            if fb.get_prototype(i).production_type == 'input' and fb.get_connections(i)[1] == own_fluidbox then
              -- snap infinity filter
              entity.set_infinity_pipe_filter{name=own_fluidbox.get_locked_fluid(1), percentage=1, mode='exactly'}
              return
            end
          end
        end
      end
    end
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