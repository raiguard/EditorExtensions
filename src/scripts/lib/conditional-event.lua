-- ----------------------------------------------------------------------------------------------------
-- CONDITIONAL EVENT HANDLER
-- This script creates and handles conditional events.

local abs = math.abs
local event = require('__stdlib__/stdlib/event/event')
local string = require('__stdlib__/stdlib/utils/string')
local table = require('__stdlib__/stdlib/utils/table')

local util = require('scripts/util/util')

local conditional_event = {}

-- all conditional events are contained here to enable lookup
local events_def = {
    cheats = {
        player = {
            instant_blueprint = {
                on_built_entity = {{defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_built}, function(e)
                    if not e.player_index then return end
                    if not util.cheat_enabled('player', 'instant_blueprint', e.player_index) then return end
                    if util.get_player(e).controller_type == defines.controllers.editor then return end
                    local entity = e.created_entity or e.entity
                    local global_table = util.cheat_table('player', 'instant_blueprint', 'global')
                    if util.is_ghost(entity) then
                        -- attempt to revive the ghost
                        local success, revived, proxy = entity.revive{raise_revive=true, return_item_request_proxy=true}
                        if not success then
                            -- if the table is empty, register the on_tick event
                            if #global_table.next_tick_entities == 0 then
                                conditional_event.register('cheats.player.instant_blueprint.next_tick')
                            end
                            -- add the entity to the table
                            table.insert(global_table.next_tick_entities, {tries=1, entity=entity})
                        elseif revived and proxy then
                            -- auto-fulfill the item request proxy, then destroy it
                            local inventory = revived.get_module_inventory() or revived.get_inventory(defines.inventory.fuel)
                            for n,c in pairs(proxy.item_requests) do
                                inventory.insert{name=n, count=c}
                            end
                            proxy.destroy()
                        end
                    end
                end},
                next_tick = {{defines.events.on_tick}, function(e)
                    local global_table = util.cheat_table('player', 'instant_blueprint', 'global')
                    local deregister = true
                    -- check if the table has contents
                    if #global_table.next_tick_entities > 0 then
                        -- for each entity in the table
                        for i,t in pairs(global_table.next_tick_entities) do
                            -- check if the entity is valid
                            if t.entity.valid then
                                -- try to revive the entity and act on the result
                                if t.entity.revive{raise_revive=true} then
                                    global_table.next_tick_entities[i] = nil
                                else
                                    t.tries = t.tries + 1
                                    -- after ten tries, remove the entity from the table
                                    if t.tries >= 10 then
                                        global_table.next_tick_entities[i] = nil
                                    else
                                        deregister = false
                                    end
                                end
                            end
                        end     
                    end
                    -- if all entites have been revived or deregistered, deregister this event
                    if deregister then
                        conditional_event.deregister('cheats.player.instant_blueprint.next_tick')
                    end
                end}
            },
            instant_upgrade = {
                on_marked_for_upgrade = {{defines.events.on_marked_for_upgrade}, function(e)
                    if not e.player_index then return end
                    if not util.cheat_enabled('player', 'instant_upgrade', e.player_index) then return end
                    if util.get_player(e).controller_type == defines.controllers.editor then return end
                    local entity = e.entity
                    local belt_to_ground_type
                    if entity.type == 'underground-belt' then belt_to_ground_type = entity.belt_to_ground_type end
                    entity.surface.create_entity{
                        name = e.target.name,
                        position = entity.position,
                        direction = entity.direction or nil,
                        force = entity.force,
                        fast_replace = true,
                        spill = false,
                        raise_built = true,
                        -- underground belt
                        type = belt_to_ground_type or nil
                    }
                end}
            },
            instant_deconstruction = {
                on_deconstruction = {{defines.events.on_marked_for_deconstruction}, function(e)
                    if not e.player_index then return end
                    if not util.cheat_enabled('player', 'instant_deconstruction', e.player_index) then return end
                    if util.get_player(e).controller_type == defines.controllers.editor then return end
                    local entity = e.entity
                    local global_table = util.cheat_table('player', 'instant_deconstruction', 'global')
                    -- attempt to destroy the entity
                    if not entity.destroy{do_cliff_correction=true, raise_destroy=true} then
                        -- if the table is empty, register the on_tick event
                        if #global_table.next_tick_entities == 0 then
                            conditional_event.register('cheats.player.instant_deconstruction.next_tick')
                        end
                        -- add the entity to the table
                        table.insert(global_table.next_tick_entities, {tries=1, entity=entity})
                    end
                end},
                next_tick = {{defines.events.on_tick}, function(e)
                    local global_table = util.cheat_table('player', 'instant_deconstruction', 'global')
                    local deregister = true
                    -- check if the table has contents
                    if #global_table.next_tick_entities > 0 then
                        -- for each entity in the table
                        for i,t in pairs(global_table.next_tick_entities) do
                            -- check if the entity is valid
                            if t.entity.valid then
                                -- try to destroy the entity and act on the result
                                if t.entity.destroy{do_cliff_correction=true, raise_destroy=true} then
                                    global_table.next_tick_entities[i] = nil
                                else
                                    t.tries = t.tries + 1
                                    -- after ten tries, remove the entity from the table
                                    if t.tries >= 10 then
                                        global_table.next_tick_entities[i] = nil
                                    else
                                        deregister = false
                                    end
                                end
                            end
                        end     
                    end
                    -- if all entites have been revived or deregistered, deregister this event
                    if deregister then
                        conditional_event.deregister('cheats.player.instant_deconstruction.next_tick')
                    end
                end}
            },
            keep_last_item = {
                on_put_item = {{defines.events.on_put_item}, function(e)
                    local player = util.get_player(e)
                    if not util.cheat_enabled('player', 'keep_last_item', player.index) then return end
                    if player.controller_type == defines.controllers.editor then return end
                    local cursor_stack = player.cursor_stack
                    if cursor_stack.valid_for_read and cursor_stack.count == 1 and not (cursor_stack.type == 'blueprint' or cursor_stack.type == 'blueprint-book') then
                        player.get_main_inventory().insert{name=cursor_stack.name, count=cursor_stack.count}
                    end
                end}
            },
            single_stack_limit = {
                on_main_inventory_changed = {{defines.events.on_player_main_inventory_changed}, function(e)
                    local player = util.get_player(e)
                    if not util.cheat_enabled('player', 'single_stack_limit', player.index) then return end
                    if player.controller_type == defines.controllers.editor then return end
                    local inventory = player.get_main_inventory()
                    local prototypes = game.item_prototypes
                    for name,count in pairs(inventory.get_contents()) do
                        local stack_size = prototypes[name].stack_size
                        if stack_size > 1 and count > stack_size then
                            inventory.remove{name=name, count=count-stack_size}
                        end
                    end
                end}
            },
            repair_used_item = {
                on_main_inventory_changed = {{defines.events.on_player_main_inventory_changed}, function(e)
                    if not util.cheat_enabled('player', 'repair_used_item', e.player_index) then return end
                    local player = util.get_player(e)
                    local inventory = player.get_main_inventory()
                    -- check to make sure the inventory exists, to avoid crashing
                    if inventory then
                        -- iterate over every slot in the inventory
                        for i=1,#inventory do
                            -- reset tool durability to max
                            if inventory[i].valid_for_read and inventory[i].durability then
                                inventory[i].durability = game.item_prototypes[inventory[i].name].durability
                            end
                            -- reset magazine ammo to max
                            if inventory[i].valid_for_read and inventory[i].type == 'ammo' then
                                inventory[i].ammo = game.item_prototypes[inventory[i].name].magazine_size
                            end
                        end
                    end
                end},
                on_cursor_stack_changed = {{defines.events.on_player_cursor_stack_changed}, function(e)
                    local player = util.get_player(e)
                    local cursor_stack = player.cursor_stack
                    local global_table = util.cheat_table('player', 'repair_used_item', 'global')
                    -- if the player is holding an ammo magazine or tool
                    if cursor_stack.valid_for_read and (cursor_stack.type == 'ammo' or cursor_stack.type == 'tool' or cursor_stack.type == 'repair-tool') then
                        -- add to global table and register event
                        global_table.cur_players[e.player_index] = true
                        conditional_event.register('cheats.player.repair_used_item.on_tick')
                    else
                        -- if we are about to remove the last player, deregister the event
                        if #global_table.cur_players == 1 then
                            conditional_event.deregister('cheats.player.repair_used_item.on_tick')
                        end
                        -- remove from global table
                        global_table.cur_players[e.player_index] = nil
                    end
                end},
                on_tick = {{defines.events.on_tick}, function(e)
                    local global_table = util.cheat_table('player', 'repair_used_item', 'global')
                    -- for every player in the table
                    for i,_ in pairs(global_table.cur_players) do
                        local player = util.get_player(i)
                        local cursor_stack = player.cursor_stack
                        if cursor_stack.valid_for_read then
                            -- check cursor stack type and add ammo / durability
                            local type = cursor_stack.type
                            if type == 'ammo' then
                                cursor_stack.ammo = game.item_prototypes[cursor_stack.name].magazine_size
                            elseif type == 'tool' or type == 'repair-tool' then
                                cursor_stack.durability = game.item_prototypes[cursor_stack.name].durability
                            end
                        end
                    end
                end}
            },
            instant_request = {
                on_main_inventory_changed = {{defines.events.on_player_main_inventory_changed}, function(e)
                    local player = util.get_player(e)
                    if not util.cheat_enabled('player', 'instant_request', player.index) then return end
                    -- check if the player has a character
                    if not player.character then return end
                    local character = player.character
                    local inventory = player.get_main_inventory()
                    local contents = inventory.get_contents()
                    -- combine the cursor stack with the main inventory contents
                    if player.cursor_stack.valid_for_read then
                        local stack = player.cursor_stack
                        contents[stack.name] = stack.count + (contents[stack.name] or 0)
                    end
                    -- iterate over all request slots
                    local get_slot = character.get_request_slot
                    local insert = inventory.insert
                    for i=1,character.request_slot_count do
                        local request = get_slot(i)
                        if request then
                            -- subtract request from the actual count
                            local diff = request.count - (contents[request.name] or 0)
                            if diff > 0 then
                                insert{name=request.name, count=diff}
                            end
                        end
                    end
                end},
                on_gui_opened = {{defines.events.on_gui_opened}, function(e)
                    -- check if the opened GUI was of the "controller" type
                    if e.gui_type == defines.gui_type.controller then
                        local player = util.get_player(e)
                        if not util.cheat_enabled('player', 'instant_request', player.index) then return end
                        -- check to be sure the player has a character and is controlling it
                        if player.character and player.controller_type == defines.controllers.character then
                            -- insert the player into the active_players table
                            local global_table = util.cheat_table('player', 'instant_request', 'global')
                            local get_slot = player.character.get_request_slot
                            local requests = {}
                            for i=1,player.character.request_slot_count do
                                requests[i] = get_slot(i) or {}
                            end
                            global_table.active_players[player.index] = requests
                            -- register events
                            conditional_event.register('cheats.player.instant_request.on_gui_closed')
                            conditional_event.register('cheats.player.instant_request.on_nth_tick')
                        end
                    end
                end},
                on_gui_closed = {{defines.events.on_gui_closed}, function(e)
                    -- check if the closed GUI was of the 'controller' type
                    if e.gui_type == defines.gui_type.controller then
                        if not util.cheat_enabled('player', 'instant_request', e.player_index) then return end
                        -- remove player from active_players
                        local global_table = util.cheat_table('player', 'instant_request', 'global')
                        global_table.active_players[e.player_index] = nil
                        -- if no active players, deregister events
                        if #global_table.active_players == 0 then
                            conditional_event.deregister('cheats.player.instant_request.on_gui_closed')
                            conditional_event.deregister('cheats.player.instant_request.on_nth_tick')
                        end
                    end
                end},
                on_nth_tick = {{-30}, function(e)
                    local active_players = util.cheat_table('player', 'instant_request', 'global').active_players
                    for i,t in pairs(active_players) do
                        local player = game.players[i]
                        local character = player.character
                        -- perform extra check to be sure the player is still in a valid state
                        if character and player.controller_type == defines.controllers.character then
                            local get_slot = character.get_request_slot
                            -- build request slots
                            local requests = {}
                            for i=1,character.request_slot_count do
                                requests[i] = get_slot(i) or {}
                            end
                            -- check if current status of requests has changed
                            if not table.deep_compare(requests,t) then
                                -- update requests table
                                active_players[i] = requests
                                -- fulfill requests
                                conditional_event.dispatch('cheats.player.instant_request.on_main_inventory_changed', {player_index=i})
                            end
                        end
                    end
                end}
            },
            instant_trash = {
                on_trash_inventory_changed = {{defines.events.on_player_trash_inventory_changed}, function(e)
                    local player = util.get_player(e)
                    if not util.cheat_enabled('player', 'instant_trash', player.index) then return end
                    -- check if the player has a character
                    if not player.character then return end
                    player.character.get_inventory(defines.inventory.character_trash).clear()
                    -- update player requests in case the item was manually transferred
                    conditional_event.dispatch('cheats.player.instant_request.on_main_inventory_changed', {player_index=e.player_index})
                end}
            }
        },
        force = {
            instant_research = {
                on_research_started = {{defines.events.on_research_started}, function(e)
                    local research = e.research
                    local force = research.force
                    if not util.cheat_enabled('force', 'instant_research', force.index) then return end
                    force.research_progress = 1
                end}
            }
        },
        surface = {
            auto_clear_all_entities = {
                on_chunk_generated = {{defines.events.on_chunk_generated}, function(e)
                    local area = e.area
                    local surface = e.surface
                    if not util.cheat_enabled('surface', 'auto_clear_all_entities', surface.index) then return end
                    for _,e in pairs(surface.find_entities(area)) do
                        e.destroy()
                    end
                end}
            },
            auto_fill_with_lab_tiles = {
                on_chunk_generated = {{defines.events.on_chunk_generated}, function(e)
                    local area = e.area
                    local surface = e.surface
                    if not util.cheat_enabled('surface', 'auto_fill_with_lab_tiles', surface.index) then return end
                    surface.destroy_decoratives{area=area}
                    local tiles = {}
                    for y=area.left_top.y,area.right_bottom.y-1 do
                        for x=area.left_top.x,area.right_bottom.x-1 do
                            table.insert(tiles, {name=((x+y)%2==0 and 'lab-dark-1' or 'lab-dark-2'), position={x,y}})
                        end
                    end
                    surface.set_tiles(tiles, false)
                end}
            }
        }
    },
    infinity_wagon = {
        on_tick = {{defines.events.on_tick}, function(e)
            for _,t in pairs(global.wagons) do
                if t.wagon.valid and t.proxy.valid then
                    if t.wagon_name == 'infinity-cargo-wagon' then
                        if t.flip == 0 then
                            t.wagon_inv.clear()
                            for n,c in pairs(t.proxy_inv.get_contents()) do t.wagon_inv.insert{name=n, count=c} end
                            t.flip = 1
                        elseif t.flip == 1 then
                            t.proxy_inv.clear()
                            for n,c in pairs(t.wagon_inv.get_contents()) do t.proxy_inv.insert{name=n, count=c} end
                            t.flip = 0
                        end
                    elseif t.wagon_name == 'infinity-fluid-wagon' then
                        if t.flip == 0 then
                            local fluid = t.proxy_fluidbox[1]
                            t.wagon_fluidbox[1] = fluid and {name=fluid.name, amount=(abs(fluid.amount) * 250), temperature=fluid.temperature} or nil
                            t.flip = 1
                        elseif t.flip == 1 then
                            local fluid = t.wagon_fluidbox[1]
                            t.proxy_fluidbox[1] = fluid and {name=fluid.name, amount=(abs(fluid.amount) / 250), temperature=fluid.temperature} or nil
                            t.flip = 0
                        end
                    end
                    t.proxy.teleport(t.wagon.position)
                end
            end
        end}
    }
}

local function get_object(string)
    local def = events_def
    for _,key in pairs(string.split(string)) do
        def = def[key]
    end
    return def
end

event.on_init(function()
    global.events = {}
end)

event.on_load(function()
    for e,t in pairs(global.events) do
        for def,_ in pairs(t) do
            conditional_event.register(def)
        end
    end
end)

-- handler must be a function reference from the definitions file
function conditional_event.register(def)
    local events = global.events
    local object = get_object(def)
    for i,e in pairs(object[1]) do
        if not events[e] then events[e] = {} end
        if not events[e][def] then
            events[e][def] = true
        end
        event.register(e, object[2])
    end
end

function conditional_event.deregister(def)
    local events = global.events
    local object = get_object(def)
    for i,e in pairs(object[1]) do
        if events[e] == nil then return end
        events[e][def] = nil
        if table_size(events[e]) == 0 then events[e] = nil end
        event.remove(e, object[2])
    end
end

-- dispatch a conditional event function as if the event was actually fired
function conditional_event.dispatch(def, args)
    local object = get_object(def)
    object[2](args)
end

-- only register if nobody else has the cheat active
function conditional_event.cheat_register(obj, cheat_def, event_def)
    local string_table = string.split(event_def)
    if not util.cheat_enabled(string_table[2], string_table[3], nil, obj.index) then
        conditional_event.register(event_def)
    end
end

function conditional_event.cheat_deregister(obj, cheat_def, event_def)
    local string_table = string.split(event_def)
    if not util.cheat_enabled(string_table[2], string_table[3], nil, obj.index) then
        conditional_event.deregister(event_def)
    end
end

return conditional_event