-- ----------------------------------------------------------------------------------------------------
-- INFINITY INSERTER CONTROL SCRIPTING

local event = require('scripts/lib/event-handler')

-- --------------------------------------------------
-- EVENT HANDLERS

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