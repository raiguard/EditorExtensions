-- ----------------------------------------------------------------------------------------------------
-- RAI'S EVENT LIBRARY

--[[
    INTRODUCTION
    Example mod that demonstrates the use of this library: https://github.com/raiguard/SmallFactorioMods/blob/master/EventHandler

    Use this event library by copying it into your mod and requiring it. I usually call it "event" so that the function calls match the below syntax.
        Example: local event = require('scripts/event-lib')

    WARNING: DO NOT USE SCRIPT.ON_EVENT() WHEN USING THIS LIBRARY! PASS ABSOLUTELY ALL EVENTS THROUGH THE LIBRARY!

    Normally, you can only register one handler per event in Factorio's API. This library allows you to circumvent this. When using this library, you can freely
    register multiple handlers to an event, allowing for cleaner code and easier maintainence, avoiding giant if/else chains.

    Additionally, this library includes special filtering for GUI events. These are SEPARATE from vanilla's event filters, and should not be confused. See
    below for more information.

    Another primary feature of this library is easy handling of conditional events. See the conditional events section near the bottom of this file for more
    information on conditional events.

    If you have any questions, don't hesitate to contact me on Twitter (@raiguard_) or on the Factorio forums (Raiguard). Thanks for using my event library!
]]--

-- library
local event = {}
-- holds registered events
local event_registry = {}
-- pass-through handlers for bootstrap events
local bootstrap_handlers = {
    on_init = function()
        event.dispatch{name='on_init'}
    end,
    on_load = function()
        event.dispatch{name='on_load'}
    end,
    on_configuration_changed = function(e)
        e.name = 'on_configuration_changed'
        event.dispatch(e)
    end
}

--[[
    event.register(id, handler, conditional_name, player_index)
    Info:
        Registers the handler for the given event(s).
    Parameters:
        id :: defines.events, int, string, or array of defines.events, int, string: The event ID(s) to invoke the handler on.
        handler :: function(): The handler to run. Receives an event table as defined in the Factorio documentation.
        conditional_name :: string (optional): The unique conditional name for this handler. Include this if registering the event conditionally.
        player_index :: int (optional): Index of the player for whom this conditional event is being registered. Only include this if you wish to conditionally
        register events on a per-player basis.
    Returns:
        event :: event: Returns an instance of the library to allow for function call chaining.
    Usage:
        -- register an event to run on every tick
        event.register(defines.events.on_tick, function(e) game.print(game.tick) end)
        -- Register something for Nth tick using negative numbers:
        event.register(-10, function(e) game.print('Every 10 ticks') end)
        -- Conditionally register an event for all players
        event.register(defines.events.on_built_entity, function(e) game.print('You built something!') end, 'print_when_built')
        -- Conditionally register an event for a specific player
        event.register(defines.events.on_built_entity, player_built_entity, 'player_built_entity', player_index)
        -- Function call chaining
        event.register(event1, handler1).register(event2, handler2)
]]--
function event.register(id, handler, conditional_name, player_index)
    -- recursive handling of ids
    if type(id) == 'table' then
        for _,n in pairs(id) do
            event.register(n, handler, conditional_name)
        end
        return
    end
    -- create event registry if it doesn't exist
    if not event_registry[id] then
        event_registry[id] = {}
    end
    local registry = event_registry[id]
    -- create master handler if not already created
    if #registry == 0 then
        if type(id) == 'number' and id < 0 then
            script.on_nth_tick(-id, event.dispatch)
        elseif type(id) == 'string' and bootstrap_handlers[id] then
            script[id](bootstrap_handlers[id])
        else
            script.on_event(id, event.dispatch)
        end
    end
    -- make sure the handler has not already been registered
    for i,t in ipairs(registry) do
        -- if it is a conditional event,
        if t.handler == handler and not conditional_name then
            -- remove handler for re-insertion at the bottom
            log('Re-registering existing event ID, moving to bottom')
            table.remove(registry, i)
        end
    end
    -- add the handler to the events table
    table.insert(registry, {handler=handler})
    if conditional_name then
        -- add the conditional_name to the events table as well
        registry[#registry].conditional_name = conditional_name
        local con_registry = global.conditional_event_registry
        if not con_registry[conditional_name] then
            con_registry[conditional_name] = {id={id}, players={player_index}}
        else
            -- check if the ID has already been registered to this event
            for _,id in ipairs(con_registry[conditional_name].id) do
                if id == id then
                    if player_index then
                        -- someone else already registered it, so add our player index to the list
                        table.insert(con_registry[conditional_name].players, player_index)
                    end
                    return event
                end
            end
            -- insert the ID if it didn't exist already
            table.insert(con_registry[conditional_name].id, id)
        end
    end
    return event
end

--[[
    event.deregister(id, handler, conditional_name, player_index)
    Info:
        Deregisters the handler from the given event(s).
    Parameters:
        id :: defines.events, int, string, or array of defines.events, int, string: The event ID(s) to deregister the handler from.
        handler :: function(): The handler to deregister.
        conditional_name :: string (optional): The unique conditional name for this handler.
        player_index :: int (optional): Index of the player from whom this conditional event is being deregistered. Only include this if it was included when
        the handler was registered.
    Returns:
        event :: event: Returns an instance of the library to allow for function call chaining.
    Usage:
        -- Deregister a conditional event from all players.
        event.register(defines.events.on_built_entity, print_when_built, 'print_when_built')
        -- Deregister a conditional event from a specific player.
        event.register(defines.events.on_built_entity, player_built_entity, 'player_built_entity', player_index)
        -- Function call chaining
        event.deregister(event1, handler1, conname1).register(event2, handler2, conname2)
]]--
function event.deregister(id, handler, conditional_name, player_index)
    -- recursive handling of ids
    if type(id) == 'table' then
        for _,n in pairs(id) do
            event.deregister(n, handler, conditional_name)
        end
        return event
    end
    local registry = event_registry[id]
    -- error checking
    if not registry or #registry == 0 then
        log('Tried to deregister an unregistered event of id: '..id)
        return event
    end
    -- remove from conditional event registry if needed
    if conditional_name then
        local con_registry = global.conditional_event_registry[conditional_name]
        for i,p in ipairs(con_registry.players) do
            if p == player_index then
                table.remove(con_registry.players, i)
            end
        end
        if table_size(con_registry.players) == 0 then
            global.conditional_event_registry[conditional_name] = nil
        else
            -- other players still need this conditional event, so don't do anything else
            return event
        end
    end
    -- remove the handler from the events tables
    for i,t in ipairs(registry) do
        if t.handler == handler then
            table.remove(registry, i)
        end
    end
    -- de-register the master handler if it's no longer needed
    if table_size(registry) == 0 then
        if type(id) == 'number' and id < 0 then
            script.on_nth_tick(math.abs(id), nil)
        elseif type(id) == 'string' and bootstrap_handlers[id] then
            script[id](nil)
        else
            script.on_event(id, nil)
        end
    end
    return event
end

--[[
    event.dispatch(e)
    Info:
        Calls all handlers registered to an event. Used internally by the handler, but can also be called manually. This DOES NOT actually raise the event, it
        just calls all the handlers that have been registered to it. If you want to actually raise an event, use event.raise.
        This is the master handler that all events are actually registered to, which then invokes all of the handlers that you register to it.
    Parameters:
        e :: table: Table that will be passed to the handlers. Please be careful to exactly mimick the table as vanilla would provide it!
    Returns:
        event :: event: Returns an instance of the library to allow for function call chaining.
    Usage:
        -- Invoke all handlers for an event
        event.dispatch{name=defines.events.on_built_entity, player_index=1, created_entity=my_entity}
        -- Function call chaining
        event.dispatch(data1).dispatch(data2)
]]--
function event.dispatch(e)
    local id = e.name
    if e.nth_tick then
        id = -e.nth_tick
    end
    if not event_registry[id] then
        if e.input_name and event_registry[e.input_name] then
            id = e.input_name
        else
            error('Event is registered but has no handlers!')
        end
    end
    local con_registry = global.conditional_event_registry
    for _,t in ipairs(event_registry[id]) do
        -- check if any userdata has gone invalid since last iteration
        for _,v in pairs(e) do
            if type(v) == 'table' and v.__self and not v.valid then
                return event
            end
        end
        -- check if we can include players in the list
        if t.conditional_name then
            -- sometimes the conditional event registry goes nil WHILE an event is running, so do an extra check just in case
            e.registered_players = con_registry[t.conditional_name] and con_registry[t.conditional_name].players or {}
        end
        -- call the handler
        t.handler(e)
    end
    return event
end

--[[
    event.raise(id, table)
    Info:
        Raises an event as if it was actually called. Literally just a tie-in for script.raise_event, so it behaves identically.
    Parameters:
        id :: int or string: ID of the event to raise.
        table :: table: Table with extra data. This table will be passed to the event handlers.
    Returns:
        event :: event: Returns an instance of the library to allow for function call chaining.
    Usage:
        -- Raise an event as if it were really called
        event.raise(defines.events.on_built_entity, {player_index=1, created_entity=my_entity, stack=my_stack})
        -- Function call chaining
        event.raise(id1, table1).raise(id2, table2)
]]--
function event.raise(id, table)
    script.raise_event(id, table)
    return event
end

--[[
    event.set_filters(id, filters)
    Info:
        Sets the event filters for the specified event(s).
    Parameters:
        id :: defines.events, int, string, or array of defines.events, int, string: The event ID(s) to set the filters for.
        filters :: table (optional): Table of filters or nil to clear the filters.
    Returns:
        event :: event: Returns an instance of the library to allow for function call chaining.
    Usage:
        -- Set the filters for an event
        event.set_filters(defines.events.on_built_entity, {{filter='ghost_name', name='demo-entity-1'}, {filter='ghost'}})
        -- Function call chaining
        event.set_filters(event1, filters1).set_filters(event2, filters2)
]]--
function event.set_filters(id, filters)
    -- recursive handling of ids
    if type(id) == 'table' then
        for _,n in pairs(id) do
            event.set_filters(n, filters)
        end
        return event
    end
    -- set the filters
    script.set_event_filter(id, filters)
    return event
end

-- shortcut for event.register('on_init', function)
function event.on_init(handler)
    return event.register('on_init', handler)
end

-- shortcut for event.register('on_load', function)
function event.on_load(handler)
    return event.register('on_load', handler)
end

-- shortcut for event.register('on_configuration_changed', function)
function event.on_configuration_changed(handler)
    return event.register('on_configuration_changed', handler)
end

-- shortcut for event.register(-nthTick, function)
function event.on_nth_tick(nthTick, handler, conditional_name, player_index)
    return event.register(-nthTick, handler, conditional_name, player_index)
end

-- --------------------------------------------------
-- GUI EVENTS

--[[
    GUI EVENT FILTERS
    This library implements special filtering for GUI events. The full syntax is {filter_type={filter}}. This can be shortcutted, see below.

    There are four filter types available:
        name: Matches the element's name to the given value. E.g. {name={'my_button'}}
        name_match: Will call the handler if the element's name includes the given text. E.g. {name_inc={'demo_button_'}}
        id: Matches the element's unique ID to the given number. E.g. {id={420}}
        element: Matches the element to the given element. E.g. {element={demo_button}}

    For each filter type, you can specify multiple filters at once, and you could even have multiple filter types for one handler!
        Example: {name_match={'friendzone_button_', 'rejection_button_'}, id={72}}

    The handler will be called if any one of the filters matches the element.

    GUI EVENT SHORTCUTTING
    Most of the time, you will probably only want to call one event for one element at a time, and most of the time you will probably only have one filter. To
    make our lives easier, you can use shortcutting syntax for GUI events:
        1. Omit the "gui_" part of the event name and use that as the function call.
                Example: event.gui.on_click({name={'my_button'}}, handler)
        2. Simply provide the name string, ID number, or element as the filter, instead of a table. The name_match filter type cannot be shortcutted.
                Example: event.gui.on_click('my_button', handler)

    As you can see, this makes the GUI event calls a lot more compact and easier to read.
]]--

-- library
event.gui = {}
-- filter handlers
local gui_event_filters = {
    name = function(element, filter)
        return element.name == filter
    end,
    name_match = function(element, filter)
        return element.name:match(filter)
    end,
    index = function(element, filter)
        return element.index == filter
    end,
    element = function(element, filter)
        return element == filter
    end
}
-- gui event data
local gui_event_data = {}

--[[
    event.gui.register(filters, id, handler, conditional_name, player_index)
    Info:
        Registers the handler for the given gui element(s).
    Parameters:
        filters :: string, int, LuaGuiElement or table of gui filters: The GUI filters. See above for the syntax.
        id :: defines.events, int, string, or array of defines.events, int, string: The event ID(s) to invoke the handler on.
        handler :: function(): The handler to run. Receives an event table as defined in the Factorio documentation.
        conditional_name :: string (optional): The unique conditional name for this handler. Include this if registering the event conditionally.
        player_index :: int (optional): Index of the player for whom this conditional event is being registered. Always include this if registering a GUI event
        conditionally, the library will error if you don't!
    Returns:
        event.gui :: event.gui: Returns an instance of the GUI sublibrary to allow for function call chaining.
    Usage:
        -- Register an on_click function for a specific button
        event.gui.register({name={'demo_button_1'}}, defines.events.on_gui_click, function(e) game.print('pressed demo button!') end)
        -- Conditionally register the same
        event.gui.register({name={'demo_button_1'}}, defines.events.on_gui_click, function(e) game.print('pressed demo button!') end,
        demo_button_clicked', player_index)
        -- Function call chaining
        event.gui.register(filters1, event1, handler1).register(filters2, event2, handler2)
]]--
function event.gui.register(filters, id, handler, conditional_name, player_index)
    -- recursive handling of ids
    if type(id) == 'table' then
        for _,n in pairs(id) do
            event.gui.register(filters, n, handler, conditional_name, player_index)
        end
        return event.gui
    end
    -- convert filter format if shortcutting was used
    if type(filters) == 'string' then
        filters = {name={filters}}
    elseif type(filters) == 'number' then
        filters = {index={filters}}
    elseif filters.valid and filters.gui then
        filters = {element={filters}}
    end
    -- create data table and register master handler if it doesn't exist
    if not gui_event_data[id] then
        gui_event_data[id] = {}
        event.register(id, event.gui.dispatch)
    end
    -- store filters in event data table
    table.insert(gui_event_data[id], {handler=handler, filters=filters})
    -- register conditional event if it is one
    if conditional_name then
        -- add the conditional_name to the data table as well
        gui_event_data[id][#gui_event_data[id]].conditional_name = conditional_name
        assert(player_index, 'Must include player index when registering a conditional event')
        local con_registry = global.conditional_event_registry
        if not con_registry[conditional_name] then
            con_registry[conditional_name] = {id={id}, filters=filters, players={player_index}}
        else
            -- check if the ID has already been registered to this event
            for _,id in ipairs(con_registry[conditional_name].id) do
                if id == id then
                    -- someone else already registered it, so add our player index to the list
                    table.insert(con_registry[conditional_name].players, player_index)
                    return event.gui
                end
            end
            -- insert the ID if it didn't exist already
            table.insert(con_registry[conditional_name].id, id)
        end
    end
    return event.gui
end

--[[
    event.gui.deregister(id, handler, conditional_name, player_index)
    Info:
        Deregisters the handler from all GUI elements.
    Parameters:
        id :: defines.events, int, string, or array of defines.events, int, string: The event ID(s) to deregister the handler from.
        handler :: function(): The handler to deregister.
        conditional_name :: string (optional): The unique conditional name for this handler.
        player_index :: int (optional): Index of the player from whom this conditional event is being deregistered. Only include this if it was included when
        the handler was registered.
    Returns:
        event.gui :: event.gui: Returns an instance of the GUI sublibrary to allow for function call chaining.
    Usage:
        -- Deregister conditional on_click handler
        event.gui.deregister(defines.events.on_gui_click, button_on_click, 'button_on_click', player_index)
        -- Function call chaining
        event.gui.deregister(event1, handler1, conname1, playerindex1).deregister(event2, handler2, conname2, playerindex2)
]]--
function event.gui.deregister(id, handler, conditional_name, player_index)
    -- recursive handling of ids
    if type(id) == 'table' then
        for _,n in pairs(id) do
            event.gui.deregister(n, handler, conditional_name, player_index)
        end
        return event.gui
    end
    -- remove from conditional event registry if needed
    if conditional_name then
        local con_registry = global.conditional_event_registry[conditional_name]
        for i,p in ipairs(con_registry.players) do
            if p == player_index then
                table.remove(con_registry.players, i)
                break
            end
        end
        if table_size(con_registry.players) == 0 then
            global.conditional_event_registry[conditional_name] = nil
        else
            -- other players still need this conditional event, so don't do anything else
            return event.gui
        end
    end
    local data = gui_event_data[id]
    -- remove the data from the data table
    for i,t in ipairs(data) do
        if t.handler == handler then
            table.remove(data, i)
        end
    end
    -- remove data table and deregister master handler if it is empty
    if #data == 0 then
        gui_event_data[id] = nil
        event.deregister(id, event.gui.dispatch)
    end
    return event.gui
end

-- DO NOT CALL THIS FUNCTION, USE EVENT.DISPATCH INSTEAD. THINGS WILL GET WEIRD IF YOU CALL THIS DIRECTLY!
-- dispatches GUI events
function event.gui.dispatch(e)
    local data = gui_event_data[e.name]
    local con_registry = global.conditional_event_registry
    -- check filters
    for _,t in ipairs(data) do
        -- check if any userdata has gone invalid since the last iteration
        for _,v in pairs(e) do
            if type(v) == 'table' and v.__self and not v.valid then
                return
            end
        end
        -- check if we can include players in the list
        if t.conditional_name then
            -- sometimes the conditional event registry goes nil WHILE an event is running, so do an extra check just in case
            e.registered_players = con_registry[t.conditional_name] and con_registry[t.conditional_name].players or {}
        end
        local filters = t.filters
        local dispatched = false
        for name, param in pairs(filters) do
            assert(gui_event_filters[name], 'Invalid GUI event filter \''..name..'\'')
            for _,filter in pairs(param) do
                if gui_event_filters[name](e.element, filter) then
                    t.handler(e)
                    dispatched = true
                    break
                end
            end
            if dispatched == true then
                break
            end
        end
    end
end

-- SHORTCUT FUNCTIONS

-- these GUI events aren't to be used with event.gui, so don't shortcut them either!
local gui_event_blacklist = {on_gui_opened=true, on_gui_closed=true}

-- register shortcut functions
-- shortcut functions are all GUI-related functions that aren't blacklisted, omitting the 'gui' part of the event
-- for example, event.gui.register(filters, defines.events.on_gui_click, handler) -> event.gui.on_click(filters, handler)
for n,i in pairs(defines.events) do
    if string.find(n, 'gui') then
        if not gui_event_blacklist[n] then
            event.gui[string.gsub(n, '_gui', '')] = function(filters, handler, conditional_name, player_index)
                event.gui.register(filters, defines.events[n], handler, conditional_name, player_index)
            end
        end
    end
end

-- --------------------------------------------------
-- CONDITIONAL EVENTS

--[[
    USING CONDITIONAL EVENTS
    Conditional events are a way to decrease overhead in large mods. Only listening for events when you actually need to is much better than always listening
    for them. Normally, conditional events are a pain to deal with, since you need to keep track of which ones you have registered, and re-register them in
    on_load. This library includes measures to help deal with conditional events.

    In all of the event and GUI event functions, there are conditional_name and player_index parameters. The conditional_name parameter must be a unique name
    that references the handler that you registered in that call. Providing a conditional_name parameter tells the library that you are registering the event
    conditionally.

    Every time you use a conditional handler, you must re-register it in on_load to prevent desyncs after a save/load cycle. The library includes a function for
    this called event.load_conditional_handlers(). For every conditional handler that you register, you must add it to a table with its conditional name, and
    pass that through the function in on_load. For example:

        event.on_load(function()
            event.load_conditional_handlers{
                print_when_built = print_when_built_handler,
                player_built_entity = player_built_entity_handler
            }
        end)

    The library will search its global table for the conditional name that you provide, and re-register the handler to its events. If the handler is not
    currently supposed to be registered (if it doesn't find the conditional name in the global table), it will not re-register it. This removes almost all
    requirements for headache-inducing conditional event logic on your side - the library does it all for you!

    There are two kinds of conditional events: 'global' and 'per-player'. 'Global' conditional events are conditionally registered / deregistered regardless
    of players. 'Per-player' conditional events are registered for specific players (for example, GUI events are always per-player). When you provide a
    player_index, the library will register the conditional event for that player. This DOES NOT MEAN that the handler won't be invoked for other players.
    What this does is adds the players for whom it is registered to a list, and the handler will only actually be deregistered when all players no longer need
    it. This offloads all of this logic onto the library, so you don't have to worry about it!
]]--

-- create global table for conditional events
event.on_init(function()
    global.conditional_event_registry = {}
end)

--[[
    event.load_conditional_handlers(data)
    Info:
        For use on on_load: re-registers provided conditional handlers if they need to be.
    Parameters:
        data :: dictionary string -> function: The handlers to re-register. Key is the handler's conditional_name, value is the handler itself.
    Returns:
        event :: event: An instance of the library to allow for function call chaining.
    Usage:
        -- Re-register conditional events in on_load:
        event.load_conditional_handlers{print_when_buiilt=print_when_built_handler, player_built_entity-player_built_entity_handler}
        -- Function call chaining
        event.load_conditional_handlers(handlers1).load_conditional_handlers(handlers2)
]]--
function event.load_conditional_handlers(data)
    for name, handler in pairs(data) do
        local registry = global.conditional_event_registry[name]
        if registry then
            if registry.filters then
                event.gui.register(registry.filters, registry.id, handler)
            else
                event.register(registry.id, handler)
            end
        end
    end
    return event
end

--[[
    event.is_registered(conditional_name, player_index)
    Info:
        Checks to see if the given conditional event is registered or not.
    Parameters:
        conditional_name :: string: The conditional name that should be checked.
    Returns:
        is_registered :: boolean: Whether or not it found the conditional event in the registry.
    Usage:
        -- check if a conditional event is registered
        if event.is_registered('player_built_entity') then game.print('someone registered that event!') end
]]
function event.is_registered(conditional_name)
    return global.conditional_event_registry[conditional_name] and true or false
end

return event