local infinity_inserter = {}

--- @param entity LuaEntity
function infinity_inserter.snap(entity)
  local control = entity.get_control_behavior()
  if not control then
    -- this is a new inserter, so set control mode to blacklist by default
    entity.inserter_filter_mode = "blacklist"
  end
end

return infinity_inserter
