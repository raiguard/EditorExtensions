--- @param pipe LuaEntity
--- @param combinator LuaEntity
local function copy_from_pipe_to_combinator(pipe, combinator)
  local filter = pipe.get_infinity_pipe_filter()
  if not filter then
    return
  end
  local cb = combinator.get_or_create_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
  --- @type LuaLogisticSection?
  local section
  for _, sec in pairs(cb.sections) do
    if sec.group == "" then
      section = sec
      break
    end
  end
  if not section then
    section = cb.add_section()
  end
  if not section then
    return -- When will this ever happen?
  end
  section.set_slot(1, {
    value = {
      comparator = "=",
      type = "fluid",
      name = filter.name --[[@as string]],
      quality = "normal",
    },
    min = 1,
  })
end

--- @param combinator LuaEntity
--- @param pipe LuaEntity
local function copy_from_combinator_to_pipe(combinator, pipe)
  local cb = combinator.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior?]]
  if not cb then
    return
  end
  local cb = combinator.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior?]]
  if not cb then
    return
  end
  local section = cb.get_section(1)
  if not section then
    return
  end
  local filter = section.filters[1]
  if not filter then
    return
  end
  local value = filter.value
  -- XXX: `filter` will not always have a `type` field.
  if value and prototypes.fluid[value.name] then
    pipe.set_infinity_pipe_filter({ type = "fluid", name = value.name, percentage = 1 })
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
