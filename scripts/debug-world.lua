local debug_world = {}

function debug_world.init()
  if script.level.level_name ~= "freeplay" then
    return
  end

  local nauvis = game.get_surface("nauvis")
  if not nauvis then
    return
  end
  local map_gen_settings = nauvis.map_gen_settings
  if map_gen_settings.height == 50 and map_gen_settings.width == 50 then
    -- Set flag
    global.in_debug_world = true

    if settings.global["ee-debug-world-research-all"].value then
      game.forces.player.research_all_technologies()
    end
    if settings.global["ee-debug-world-lab-tiles"].value then
      debug_world.lab(nauvis, true)
    end
    if settings.global["ee-debug-world-infinite"].value then
      debug_world.infinite(nauvis)
    end
    nauvis.clear(true)
  end
end

--- @param surface LuaSurface
--- @param skip_clear boolean?
function debug_world.infinite(surface, skip_clear)
  local mapgen = surface.map_gen_settings
  mapgen.height = 0
  mapgen.width = 0
  surface.map_gen_settings = mapgen
  if not skip_clear then
    surface.clear(true)
  end
end

--- @param surface LuaSurface
--- @param skip_clear boolean?
function debug_world.lab(surface, skip_clear)
  surface.generate_with_lab_tiles = true
  surface.freeze_daytime = true
  surface.daytime = 0
  surface.show_clouds = false
  if not skip_clear then
    surface.clear(true)
  end
end

return debug_world
