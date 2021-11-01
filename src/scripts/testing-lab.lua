local constants = require("scripts.constants")

local testing_lab = {}

---@type LuaPlayer
function testing_lab.toggle(player, player_table, ts_setting)
  local key = ts_setting == constants.testing_lab_setting.personal and player.index or "shared"
  local testing_surface_name = "EE_TESTSURFACE_"..key

  local last_surface_data = player_table.last_surface

  local in_editor = player.controller_type == defines.controllers.editor

  if in_editor then
    -- If the surface is invalid in any way, or its name does not match our lab's name, or the force is invalid
    if not last_surface_data
      or not last_surface_data.surface
      or not last_surface_data.surface.valid
      or (
        string.find(last_surface_data.surface.name, "EE_TESTSURFACE_")
        and last_surface_data.surface.name ~= testing_surface_name
      )
      or not last_surface_data.force
      or not last_surface_data.force.valid
    then
      local testing_surface = game.surfaces[testing_surface_name]
      if not testing_surface then
        testing_surface = game.create_surface(testing_surface_name, constants.empty_map_gen_settings)
        if not testing_surface then
          player.print("Could not create test surface")
          return
        end
        -- Lab conditions
        testing_surface.generate_with_lab_tiles = true
        testing_surface.freeze_daytime = true
        testing_surface.show_clouds = false
        testing_surface.daytime = 0

      end

      local force_name = "EE_TESTFORCE_"..key
      local force = game.forces[force_name]
      if not game.forces[force_name] then
        if table_size(game.forces) < 64 then
          player.print("Cannot create a testing lab force. Factorio only supports up to 64 forces at once. Please use a shared lab.")
          return
        end

        force = game.create_force(force_name)
        force.research_all_technologies()
      end

      last_surface_data = {force = force, position = {x = 0, y = 0}, surface = testing_surface}
      player_table.last_surface = last_surface_data
    end
  end

  local current_surface_data = {
    force = player.force,
    position = player.position,
    surface = player.surface,
  }

  if not in_editor
    and player.surface.name ~= testing_surface_name
    and not string.find(player.surface.name, "EE_TESTSURFACE_")
  then
    -- Swap the two table references
    local temp = last_surface_data
    last_surface_data = current_surface_data
    current_surface_data = temp
  else
    player.teleport(last_surface_data.position, last_surface_data.surface)
    player.force = last_surface_data.force
  end

  player_table.last_surface = current_surface_data
end

return testing_lab
