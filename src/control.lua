-- ----------------------------------------------------------------------------------------------------
-- EDITOR EXTENSIONS CONTROL SCRIPTING

-- --------------------------------------------------
-- MODULES

require('scripts/infinity-accumulator')
require('scripts/infinity-loader')
require('scripts/infinity-wagon')
require('scripts/tesseract-chest')

-- --------------------------------------------------
-- SETUP AND GENERAL SCRIPTING

local event = require('scripts/lib/event-handler')
local util = require('scripts/lib/util')

local function setup_player(index)
    local data = {
        gui = {}
    }
    global.players[index] = data
end

-- GENERAL SETUP
event.on_init(function()
    global.players = {}
    -- the first time someone toggles the map editor, unpause the current tick
    global.map_editor_toggled = false
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
    if global.map_editor_toggled == false then
        global.map_editor_toggled = true
        game.tick_paused = false
    end
end)

-- --------------------------------------------------
-- INFINITY INSERTER

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

-- event.register(defines.events.on_built_entity, )