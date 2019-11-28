-- ----------------------------------------------------------------------------------------------------
-- INFINITY INSERTER CONTROL SCRIPTING

local event = require('__stdlib__/stdlib/event/event')
local on_event = event.register
local version = require('__stdlib__/stdlib/vendor/version')

-- ----------------------------------------------------------------------------------------------------
-- LISTENERS

event.on_configuration_changed(function(e)
    if e.mod_changes['EditorExtensions'] and e.mod_changes['EditorExtensions'].old_version then
        local t = e.mod_changes['EditorExtensions']
        local v = version('0.4.0')
        if version(t.old_version) < v then
            -- set all existing inserters to blacklist mode to preserve non-filter functionality
            for _,s in pairs(game.surfaces) do
                for _,e in pairs(s.find_entities_filtered{name='infinity-inserter'}) do
                    e.inserter_filter_mode = 'blacklist'
                end
            end
        end
    end
end)

on_event({defines.events.on_built_entity}, function(e)
    local entity = e.created_entity or e.entity
    if entity.name == 'infinity-inserter' then
        local control = entity.get_control_behavior()
        if not control then
            -- this is a new inserter, so set control mode to blacklist by default
            entity.inserter_filter_mode = 'blacklist'
        end
    end
end)