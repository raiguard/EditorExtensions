-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RAILUALIB EVENT LIBRARY
-- v1.0.0

-- DOCUMENTATION: https://github.com/raiguard/SmallFactorioMods/wiki/Event-Library-Documentation

-- library
local event = {}
-- holds registered events
local event_registry = {}
-- GUI filter matching functions
local gui_filter_matchers = {
  string = function(element, filter) return element.name:match(filter) end,
  number = function(element, filter) return element.id == filter end,
  table = function(element, filter) return element == filter end
}
-- calls handler functions tied to an event
-- ALL events go through this function
local function dispatch_event(e)
  local id = e.name
  -- set ID for special events
  if e.nth_tick then
    id = -e.nth_tick
  end
  if e.input_name then
    id = e.input_name
  end
  -- error checking
  if not event_registry[id] then
    error('Event is registered but has no handlers!')
  end
  local con_registry = global.conditional_event_registry
  for _,t in ipairs(event_registry[id]) do -- for every handler registered to this event
    -- check if any userdata has gone invalid since last iteration
    for _,v in pairs(e) do
      if type(v) == 'table' and v.__self and not v.valid then
        return event
      end
    end
    -- insert registered players if necessary
    if t.name then
      e.registered_players = con_registry[t.name] and con_registry[t.name].players
    end
    -- check GUI filters if they exist
    local filters = t.gui_filters
    if filters then
      local elem = e.element
      if not elem then
        -- there is no element to filter, so skip calling the handler
        log('Event '..id..' has GUI filters but no GUI element, skipping!')
        goto continue
      end
      for _,filter in ipairs(filters) do
        if gui_filter_matchers[type(filter)](elem, filter) then
          goto call_handler
        end
      end
      -- if we're here, none of the filters matched, so don't call the handler
      goto continue
    end
    ::call_handler::
    -- call the handler
    t.handler(e)
    ::continue::
  end
  return event
end
-- pass-through handlers for special events
local bootstrap_handlers = {
  on_init = function()
    dispatch_event{name='on_init'}
  end,
  on_load = function()
    dispatch_event{name='on_load'}
  end,
  on_configuration_changed = function(e)
    e.name = 'on_configuration_changed'
    dispatch_event(e)
  end
}

-- -----------------------------------------------------------------------------
-- EVENTS

-- registers a handler to run when the event is called
function event.register(id, handler, options)
  options = options or {}
  -- nest GUI filters into an array if they're not already
  local filters = options.gui_filters
  if filters then
    if type(filters) ~= 'table' or filters.gui then
      filters = {filters}
    end
  end
  -- add to conditional event registry if needed
  local name = options.name
  if name then
    local player_index = options.player_index
    local con_registry = global.conditional_event_registry[name]
    if not con_registry then
      global.conditional_event_registry[name] = {id=id, players={player_index}, gui_filters=filters}
    elseif player_index then
      table.insert(con_registry.players, player_index)
      return event -- don't do anything else
    end
  end
  -- register handler
  if type(id) ~= 'table' then id = {id} end
  for _,n in pairs(id) do
    -- create event registry if it doesn't exist
    if not event_registry[n] then
      event_registry[n] = {}
    end
    local registry = event_registry[n]
    -- create master handler if not already created
    if #registry == 0 then
      if type(n) == 'number' and n < 0 then
        script.on_nth_tick(-n, dispatch_event)
      elseif type(n) == 'string' and bootstrap_handlers[n] then
        script[n](bootstrap_handlers[n])
      else
        script.on_event(n, dispatch_event)
      end
    end
    -- make sure the handler has not already been registered
    for i,t in ipairs(registry) do
      -- if it is a conditional event,
      if t.handler == handler and not name then
        -- remove handler for re-insertion at the bottom
        log('Re-registering existing event ID, moving to bottom')
        table.remove(registry, i)
      end
    end
    -- add the handler to the events table
    table.insert(registry, {handler=handler, name=name, gui_filters=filters})
  end
  return event -- function call chaining
end

-- deregisters a handler from the given event
function event.deregister(id, handler, options)
  options = options or {}
  local name = options.name
  local player_index = options.player_index
  -- remove from conditional event registry if needed
  if name then
    local con_registry = global.conditional_event_registry[name]
    if con_registry then
      if player_index then
        for i,pi in ipairs(con_registry.players) do
          if pi == player_index then
            table.remove(con_registry.players, i)
          end
        end
      end
      if #con_registry.players == 0 then
        global.conditional_event_registry[name] = nil
      end
    else
      error('Tried to deregister a conditional event whose data does not exist')
    end
  end
  -- deregister handler
  if type(id) ~= 'table' then id = {id} end
  for _,n in pairs(id) do
    local registry = event_registry[n]
    -- error checking
    if not registry or #registry == 0 then
      log('Tried to deregister an unregistered event of id: '..n)
      return event
    end
    -- remove the handler from the events tables
    for i,t in ipairs(registry) do
      if t.handler == handler then
        table.remove(registry, i)
      end
    end
    -- de-register the master handler if it's no longer needed
    if table_size(registry) == 0 then
      if type(n) == 'number' and n < 0 then
        script.on_nth_tick(math.abs(n), nil)
      elseif type(n) == 'string' and bootstrap_handlers[n] then
        script[n](nil)
      else
        script.on_event(n, nil)
      end
    end
  end
  return event
end

-- raises an event as if it were actually called
function event.raise(id, table)
  script.raise_event(id, table)
  return event
end

-- set or remove event filters
function event.set_filters(id, filters)
  if type(id) ~= 'table' then id = {id} end
  for _,n in pairs(id) do
    script.set_event_filter(n, filters)
  end
  return event
end

-- holds custom event IDs
local custom_id_registry = {}
-- generates or retrieves a custom event ID
function event.generate_id(name)
  if not custom_id_registry[name] then
    custom_id_registry[name] = script.generate_event_name()
  end
  return custom_id_registry[name], event
end

-- -------------------------------------
-- SHORTCUT FUNCTIONS

-- bootstrap events
function event.on_init(handler)
  return event.register('on_init', handler)
end

function event.on_load(handler)
  return event.register('on_load', handler)
end

function event.on_configuration_changed(handler)
  return event.register('on_configuration_changed', handler)
end

function event.on_nth_tick(nthTick, handler, options)
  return event.register(-nthTick, handler, options)
end

-- defines.events
for n,id in pairs(defines.events) do
  event[n] = function(handler, options)
    event.register(id, handler, options)
  end
end

-- -----------------------------------------------------------------------------
-- CONDITIONAL EVENTS

-- create global table for conditional events on init
event.on_init(function()
  global.conditional_event_registry = {}
end)

-- re-registers conditional handlers if they're in the registry
function event.load_conditional_handlers(data)
  for name, handler in pairs(data) do
    local registry = global.conditional_event_registry[name]
    if registry then
        event.register(registry.id, handler, {name=name, gui_filters=registry.gui_filters})
    end
  end
  return event
end

-- returns true if the conditional event is registered
function event.is_registered(name, player_index)
  local registry = global.conditional_event_registry[name]
  if registry then
    if player_index then
      for _,i in ipairs(registry.players) do
        if i == player_index then
          return true
        end
      end
      return false
    end
    return true
  end
  return false
end

-- gets the event IDs from the conditional registry so you don't have to provide them
function event.deregister_conditional(handler, options)
  local con_registry = global.conditional_event_registry[options.name]
  if con_registry then
    event.deregister(con_registry.id, handler, options)
  end
end

return event