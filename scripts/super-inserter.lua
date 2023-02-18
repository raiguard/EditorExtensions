--- @param e BuiltEvent
local function on_entity_built(e)
  local entity = e.created_entity or e.entity or e.destination
  if not entity or not entity.valid or entity.name ~= "ee-super-inserter" then
    return
  end
  local control = entity.get_control_behavior()
  if control then
    return
  end
  -- This is a newly placed inserter, so set control mode to blacklist by default
  entity.inserter_filter_mode = "blacklist"
end

local super_inserter = {}

super_inserter.events = {
  [defines.events.on_built_entity] = on_entity_built,
  [defines.events.on_entity_cloned] = on_entity_built,
  [defines.events.on_robot_built_entity] = on_entity_built,
  [defines.events.script_raised_built] = on_entity_built,
  [defines.events.script_raised_revive] = on_entity_built,
}

return super_inserter
