-- ----------------------------------------------------------------------------------------------------
-- EDITOR EXTENSIONS CONTROL SCRIPTING

local event = require('lualib/event')
local util = require('lualib/util')

-- --------------------------------------------------
-- MODULES

require('scripts/infinity-accumulator')
require('scripts/infinity-combinator')
require('scripts/infinity-loader')
require('scripts/infinity-wagon')
require('scripts/tesseract-chest')

-- --------------------------------------------------
-- SETUP AND GENERAL SCRIPTING

local function setup_player(index)
    local data = {
        flags = {},
        gui = {}
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

-- --------------------------------------------------
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

-- --------------------------------------------------
-- INFINITY PIPE

-- snap infinity pipe filter to adjacent assembler input if a player built it manually
event.register(defines.events.on_built_entity, function(e)
    local entity = e.created_entity
    if entity.name == 'infinity-pipe' then
        -- get own fluidbox
        local own_fluidbox = entity.fluidbox
        -- see if it's connected to anything
        if #own_fluidbox.get_connections(1) == 0 then
            -- there are no connections, so do nothing
            return
        end
        -- for each adjacent assembling machine, if any
        for _,e in ipairs(util.entity.check_tile_neighbors(entity, function(e) return e.type == 'assembling-machine' end, false, true)) do
            -- check each fluidbox to see if we're connected to it
            local fluidbox = e.fluidbox
            for i=1,#fluidbox do
                local connections = fluidbox.get_connections(i)
                if #connections == 1 and connections[1] == own_fluidbox and fluidbox.get_prototype(i).production_type == 'input' then
                    -- snap infinity filter
                    entity.set_infinity_pipe_filter{name=own_fluidbox.get_locked_fluid(1), percentage=1, mode='exactly'}
                    return
                end
            end
        end
    end
end)

-- --------------------------------------------------
-- EVENT FILTERS
-- Add filters to all events that support them so we can preserve as much performance as possible

event.set_filters({defines.events.on_built_entity, defines.events.on_robot_built_entity}, {
    {filter='name', name='infinity-loader-dummy-combinator'},
    {filter='name', name='infinity-loader-logic-combinator'},
    {filter='name', name='infinity-cargo-wagon'},
    {filter='name', name='infinity-fluid-wagon'},
    {filter='name', name='tesseract-chest'},
    {filter='name', name='tesseract-passive-provider-chest'},
    {filter='name', name='tesseract-storage-chest'},
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