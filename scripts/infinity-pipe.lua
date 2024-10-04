--- @param pipe LuaEntity
--- @param combinator LuaEntity
local function copy_from_pipe_to_combinator(pipe, combinator)
  local filter = pipe.get_infinity_pipe_filter()
  if not filter then
    return
  end
  local cb = combinator.get_or_create_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
  cb.set_signal(1, {
    signal = { type = "fluid", name = filter.name },
    count = 1,
  })
end

--- @param combinator LuaEntity
--- @param pipe LuaEntity
local function copy_from_combinator_to_pipe(combinator, pipe)
  local cb = combinator.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior?]]
  if not cb then
    return
  end
  local signal = cb.get_signal(1)
  if signal.signal and signal.signal.type == "fluid" then
    pipe.set_infinity_pipe_filter({ type = "fluid", name = signal.signal.name, percentage = 1 })
  else
    pipe.set_infinity_pipe_filter(nil)
  end
end

--- @param e EventData.on_entity_settings_pasted
local function on_entity_settings_pasted(e)
  local source, destination = e.source, e.destination
  if not source.valid or not destination.valid then
    return
  end
  local source_is_pipe, destination_is_pipe = source.type == "infinity-pipe", destination.type == "infinity-pipe"
  if source_is_pipe and destination.name == "constant-combinator" then
    copy_from_pipe_to_combinator(source, destination)
  elseif source.name == "constant-combinator" and destination_is_pipe then
    copy_from_combinator_to_pipe(source, destination)
  end
end

local infinity_pipe = {}

infinity_pipe.events = {
  [defines.events.on_entity_settings_pasted] = on_entity_settings_pasted,
}

return infinity_pipe
