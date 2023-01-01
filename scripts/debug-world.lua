--- @param surface LuaSurface
--- @param skip_clear boolean?
local function set_infinite(surface, skip_clear)
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
local function set_lab(surface, skip_clear)
	surface.generate_with_lab_tiles = true
	surface.freeze_daytime = true
	surface.daytime = 0
	surface.show_clouds = false
	if not skip_clear then
		surface.clear(true)
	end
end

local function on_init()
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

		local needs_clear = false
		if settings.global["ee-debug-world-research-all"].value then
			game.forces.player.research_all_technologies()
		end
		if settings.global["ee-debug-world-lab-tiles"].value then
			needs_clear = true
			set_lab(nauvis, true)
		end
		if settings.global["ee-debug-world-infinite"].value then
			needs_clear = true
			set_infinite(nauvis, true)
		end
		if needs_clear then
			nauvis.clear(true)
		end
	end
end

--- @param e EventData.on_console_command
local function on_console_command(e)
	if e.command ~= "cheat" or not game.console_command_used then
		return
	end

	local player = game.get_player(e.player_index)
	if not player then
		return
	end

	if e.parameters == "lab" then
		set_lab(player.surface)
	end
end

local debug_world = {}

debug_world.on_init = on_init

debug_world.events = {
	[defines.events.on_console_command] = on_console_command,
}

return debug_world
