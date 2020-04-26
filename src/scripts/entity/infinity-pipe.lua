local infinity_pipe = {}

function infinity_pipe.snap(entity, player_settings)
  local neighbours = entity.neighbours[1]
  local own_fb = entity.fluidbox
  local own_id = entity.unit_number
  -- snap to adjacent assemblers
  if player_settings.infinity_pipe_assembler_snapping then
    for ni=1, #neighbours do
      local neighbour = neighbours[ni]
      if neighbour.type == "assembling-machine" and neighbour.fluidbox then
        local fb = neighbour.fluidbox
        for i=1, #fb do
          local connections = fb.get_connections(i)
          if connections[1] and (connections[1].owner.unit_number == own_id) and (fb.get_prototype(i).production_type == "input") then
            -- set to fill the pipe with the fluid
            entity.set_infinity_pipe_filter{name=own_fb.get_locked_fluid(1), percentage=1, mode="exactly"}
            return -- don't do default snapping
          end
        end
      end
    end
  end
  -- snap to locked fluid
  if player_settings.infinity_pipe_snapping then
    local fluid = own_fb.get_locked_fluid(1)
    if fluid then
      entity.set_infinity_pipe_filter{name=fluid, percentage=0, mode="exactly"}
    end
  end
end

return infinity_pipe