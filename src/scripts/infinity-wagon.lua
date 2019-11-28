local abs = math.abs
local area = require('__stdlib__/stdlib/area/area')
local event = require('__stdlib__/stdlib/event/event')
local on_event = event.register
local position = require('__stdlib__/stdlib/area/position')
local util = require('scripts/util/util')

local conditional_event = require('scripts/util/conditional-event')

-- on game init
event.on_init(function()
    global.wagons = {}
end)

-- when an entity is built
on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_built, defines.events.script_raised_revive}, function(e)
    local entity = e.created_entity or e.entity
    if entity.name == 'infinity-cargo-wagon' or entity.name == 'infinity-fluid-wagon' then
        local proxy = entity.surface.create_entity{name = 'infinity-wagon-' .. (entity.name == 'infinity-cargo-wagon' and 'chest' or 'pipe'), position = entity.position, force = entity.force}
        if table_size(global.wagons) == 0 then
            conditional_event.register('infinity_wagon.on_tick')
        end
        -- create all api lookups here to save time in on_tick()
        local data = {
            wagon = entity,
            wagon_name = entity.name,
            wagon_inv = entity.get_inventory(defines.inventory.cargo_wagon),
            wagon_fluidbox = entity.fluidbox,
            proxy = proxy,
            proxy_inv = proxy.get_inventory(defines.inventory.chest),
            proxy_fluidbox = proxy.fluidbox,
            flip = 0
        }
        global.wagons[entity.unit_number] = data
        -- apply any pre-existing filters
        if e.tags and e.tags.EditorExtensions then
            if entity.name == 'infinity-cargo-wagon' then
                data.proxy.infinity_container_filters = e.tags.EditorExtensions
            elseif entity.name == 'infinity-fluid-wagon' then
                data.proxy.set_infinity_pipe_filter(e.tags.EditorExtensions)
            end
        end
    end
end)

-- before an entity is mined by a player or marked for deconstructione
on_event({defines.events.on_pre_player_mined_item, defines.events.on_marked_for_deconstruction}, function(e)
    local entity = e.entity
    if entity.name == 'infinity-cargo-wagon' then
        -- clear the wagon's inventory and set FLIP to 3 to prevent it from being refilled
        global.wagons[entity.unit_number].flip = 3
        entity.get_inventory(defines.inventory.cargo_wagon).clear()
    end
end)

-- when a deconstruction order is canceled
on_event(defines.events.on_cancelled_deconstruction, function(e)
    local entity = e.entity
    if entity.name == 'infinity-cargo-wagon' then
        global.wagons[entity.unit_number].flip = 0
    end
end)

-- when an entity is destroyed
on_event({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity, defines.events.on_entity_died, defines.events.script_raised_destroy}, function(e)
    local entity = e.entity
    if entity.name == 'infinity-cargo-wagon' or entity.name == 'infinity-fluid-wagon' then
        global.wagons[entity.unit_number].proxy.destroy()
        global.wagons[entity.unit_number] = nil
        if table_size(global.wagons) == 0 then
            conditional_event.deregister('infinity_wagon.on_tick')
        end
    end
end)

-- when a gui is opened
on_event('iw-open-gui', function(e)
    local player = util.get_player(e)
    local selected = player.selected
    if selected and (selected.name == 'infinity-cargo-wagon' or selected.name == 'infinity-fluid-wagon') then
        if position.distance(player.position, selected.position) <= player.reach_distance then
            player.opened = global.wagons[selected.unit_number].proxy
        end
    end
end)

-- override cargo wagon's default GUI opening
on_event(defines.events.on_gui_opened, function(e)
    if e.entity and (e.entity.name == 'infinity-cargo-wagon' or e.entity.name == 'infinity-fluid-wagon') then
        game.players[e.player_index].opened = global.wagons[e.entity.unit_number].proxy
    end
end)

-- when an entity copy/paste happens
on_event(defines.events.on_entity_settings_pasted, function(e)
    if e.source.name == 'infinity-cargo-wagon' and e.destination.name == 'infinity-cargo-wagon' then
        global.wagons[e.destination.unit_number].proxy.copy_settings(global.wagons[e.source.unit_number].proxy)
    elseif e.source.name == 'infinity-fluid-wagon' and e.destination.name == 'infinity-fluid-wagon' then
        global.wagons[e.destination.unit_number].proxy.copy_settings(global.wagons[e.source.unit_number].proxy)
    end
end)

-- when a player selects an area for blueprinting
on_event(defines.events.on_player_setup_blueprint, function(e)
    local player = util.get_player(e)
    local bp = player.blueprint_to_setup
    if not bp or not bp.valid_for_read then
        bp = player.cursor_stack
    end
    local entities = bp.get_blueprint_entities()
    if not entities then return end
    local chests = player.surface.find_entities_filtered{name='infinity-wagon-chest'}
    local pipes = player.surface.find_entities_filtered{name='infinity-wagon-pipe'}
    local chest_index = 0
    local pipe_index = 0
    for _,en in pairs(entities) do
        -- if the entity is an infinity wagon
        if en.name == 'infinity-cargo-wagon' then
            chest_index = chest_index + 1
            if not en.tags then en.tags = {} end
            en.tags.EditorExtensions = chests[chest_index].infinity_container_filters
        elseif en.name == 'infinity-fluid-wagon' then
            pipe_index = pipe_index + 1
            if not en.tags then en.tags = {} end
            en.tags.EditorExtensions = pipes[pipe_index].get_infinity_pipe_filter()
        end
    end
    bp.set_blueprint_entities(entities)
end)