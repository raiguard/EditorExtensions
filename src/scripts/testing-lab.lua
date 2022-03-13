local constants = require("scripts.constants")

local testing_lab = {}

--- @param player LuaPlayer
--- @param player_table table
--- @param ts_setting? string
function testing_lab.toggle(player, player_table, ts_setting)
  local key = ts_setting == constants.testing_lab_setting.personal and player.index or "shared"
  local testing_surface_name = "EE_TESTSURFACE_" .. key
  local testing_force_name = "EE_TESTFORCE_" .. key
  local in_editor = player.controller_type == defines.controllers.editor

  -- VERIFY INFO

  -- If the surface is invalid in any way, or its name does not match our lab's name, or the force is invalid
  if
    not player_table.lab_state
    or not player_table.lab_state.surface
    or not player_table.lab_state.surface.valid
    or (string.find(player_table.lab_state.surface.name, "EE_TESTSURFACE_") and player_table.lab_state.surface.name ~= testing_surface_name)
    or not player_table.lab_state.force
    or not player_table.lab_state.force.valid
  then
    local testing_surface = game.get_surface(testing_surface_name)
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

    local force = game.forces[testing_force_name]
    if not game.forces[testing_force_name] then
      if table_size(game.forces) == 64 then
        player.print(
          "Cannot create a testing lab force. Factorio only supports up to 64 forces at once. Please use a shared lab."
        )
        return
      end

      force = game.create_force(testing_force_name)
      force.research_all_technologies()
    end

    player_table.lab_state = { force = force, position = { x = 0, y = 0 }, surface = testing_surface }
  end

  if in_editor then
    player_table.normal_state = {
      force = player.force,
      position = player.position,
      surface = player.surface,
    }
  else
    player_table.lab_state = {
      force = game.forces[testing_force_name],
      position = player.position,
      surface = game.get_surface(testing_surface_name),
    }
  end

  local to_state = in_editor and player_table.lab_state or player_table.normal_state

  if to_state and to_state.surface.valid and to_state.force.valid then
    player.force = to_state.force
    player.teleport(to_state.position, to_state.surface)
  end
end

return testing_lab
