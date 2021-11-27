return function()
  if script.level.level_name ~= "freeplay" then
    return
  end

  local nauvis = game.get_surface("nauvis")
  local map_gen_settings = nauvis.map_gen_settings
  if map_gen_settings.height == 50 and map_gen_settings.width == 50 then
    -- Update surface settings
    nauvis.generate_with_lab_tiles = true
    nauvis.freeze_daytime = true
    nauvis.daytime = 0
    nauvis.show_clouds = false

    -- Regenerate surface
    nauvis.clear(true)

    -- Set flag
    global.flags.in_debug_world = true
  end
end
