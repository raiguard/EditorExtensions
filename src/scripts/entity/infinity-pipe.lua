local infinity_pipe = {}

local constants = require("scripts.constants")

function infinity_pipe.snap(entity, player_settings)
  local own_id = entity.unit_number

  if player_settings.infinity_pipe_crafter_snapping then
    for _, fluidbox in ipairs(entity.fluidbox.get_connections(1)) do
      local owner_type = fluidbox.owner.type
      if constants.ip_crafter_snapping_types[owner_type] then
        for i = 1, #fluidbox do
          local connections = fluidbox.get_connections(i)
          for j = 1, #connections do
            if connections[j].owner.unit_number == own_id then
              local prototype = fluidbox.get_prototype(i)
              if prototype.production_type == "input" then
                local fluid = fluidbox.get_locked_fluid(i)
                if fluid then
                  entity.set_infinity_pipe_filter{name = fluid, percentage = 1, mode = "at-least"}
                  return
                end
              end
            end
          end
        end
      end
    end
  end
end

return infinity_pipe