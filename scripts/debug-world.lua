local util = require("__EditorExtensions__/scripts/util")

--- @param surface LuaSurface
local function setup_surface(surface)
  surface.generate_with_lab_tiles = true
  surface.show_clouds = false
  surface.freeze_daytime = true
  surface.daytime = 0
  surface.clear(true)
end

--- @param force LuaForce
local function setup_force(force)
  force.max_successful_attempts_per_tick_per_construction_queue = 30
  force.max_failed_attempts_per_tick_per_construction_queue = 10
  force.research_all_technologies()
  if util.in_testing_scenario() then
    force.rechart()
  end
end

--- @param player LuaPlayer
local function setup_player(player)
  player.cheat_mode = true
  local start_in_editor = player.mod_settings["ee-start-in-editor"]
  if start_in_editor and start_in_editor.value then
    player.toggle_map_editor()
  end
  if util.in_debug_world() then
    local items = remote.call("freeplay", "get_created_items")
    remote.call("freeplay", "set_created_items", {})
    remote.call("freeplay", "set_respawn_items", {})
    for name, count in pairs(items) do
      player.remove_item({ name = name, count = count })
    end
  end
end

--- @param e EventData.on_force_created
local function on_force_created(e)
  if not util.in_debug_world() and not util.in_testing_scenario() then
    return
  end
  setup_force(e.force)
end

--- @param e EventData.on_player_created
local function on_player_created(e)
  if not util.in_debug_world() and not util.in_testing_scenario() then
    return
  end
  local player = game.get_player(e.player_index)
  if player then
    setup_player(player)
  end
end

--- @param e EventData.on_surface_cleared
local function on_surface_cleared(e)
  if not util.in_debug_world() then
    return
  end
  local surface = game.get_surface(e.surface_index)
  if not surface then
    return
  end
  surface.create_entity({
    name = "ee-infinity-accumulator-primary-output",
    position = { -24, -24 },
    force = game.forces.player,
    create_build_effect_smoke = false,
  })
  surface.create_entity({
    name = "ee-super-substation",
    position = { -22, -24 },
    force = game.forces.player,
    create_build_effect_smoke = false,
  })
end

local function on_init()
  if not util.in_debug_world() and not util.in_testing_scenario() then
    return
  end
  for _, force in pairs(game.forces) do
    setup_force(force)
  end
  for _, player in pairs(game.players) do
    setup_player(player)
  end

  if util.in_debug_world() then
    local nauvis = game.get_surface("nauvis")
    if nauvis then
      setup_surface(nauvis)
    end
  end
end

local debug_world = {}

debug_world.on_init = on_init

debug_world.events = {
  [defines.events.on_force_created] = on_force_created,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_surface_cleared] = on_surface_cleared,
}

return debug_world
