-- ----------------------------------------------------------------------------------------------------
-- INFINITY MODE CONTROL SCRIPTING

-- --------------------------------------------------
-- MODULES

-- require('scripts/infinity-accumulator')
-- require('scripts/infinity-inserter')
-- require('scripts/infinity-loader')
-- require('scripts/infinity-wagon')
-- require('scripts/tesseract-chest')

-- --------------------------------------------------
-- SETUP AND GENERAL SCRIPTING

local event = require('scripts/lib/event-handler')
local util = require('scripts/lib/util')

-- GENERAL SETUP
event.on_init(function()
    global.players = {}
end)

local function update_shortcut_toggled(player)
    player.set_shortcut_toggled('ee-toggle-map-editor', player.controller_type == defines.controllers.editor)
end

-- map editor shortcut
event.register(defines.events.on_lua_shortcut, function(e)
    if e.prototype_name ~= 'ee-toggle-map-editor' then return end
    local player = util.get_player(e)
    player.toggle_map_editor()
    update_shortcut_toggled(player)
end)

-- map editor hotkey
event.register('ee-toggle-map-editor', function(e)
    local player = util.get_player(e)
    player.toggle_map_editor()
    update_shortcut_toggled(player)
end)