local transport_belt_connectables = {
	["transport-belt"] = true,
	["underground-belt"] = true,
	["splitter"] = true,
	["loader"] = true,
	["loader-1x1"] = true,
	["linked-belt"] = true,
}

--- Snaps the loader to the transport-belt-connectable entity that it's facing. If `target` is
--- supplied, it will check against that entity, and will not snap if it cannot connect to it.
--- @param entity LuaEntity
--- @param target LuaEntity?
local function snap(entity, target)
	-- Check for a connected belt, then flip and try again, then flip back if failed
	for _ = 1, 2 do
		local connection = entity.belt_neighbours[entity.loader_type .. "s"][1]
		if connection and (not target or connection.unit_number == target.unit_number) then
			break
		end
		-- Flip the direction
		entity.loader_type = entity.loader_type == "output" and "input" or "output"
	end
end

--- Snaps all neighbouring infinity loaders.
--- @param entity LuaEntity
local function snap_belt_neighbours(entity)
	local linked_belt_neighbour
	if entity.type == "linked-belt" then
		linked_belt_neighbour = entity.linked_belt_neighbour
		if linked_belt_neighbour then
			entity.disconnect_linked_belts()
		end
	end

	local to_snap = {}
	for _ = 1, (entity.type == "transport-belt" or entity.type == "linked-belt") and 4 or 2 do
		-- Catalog neighbouring loaders for this rotation
		for _, neighbours in pairs(entity.belt_neighbours) do
			for _, neighbour in ipairs(neighbours) do
				if neighbour.name == "ee-infinity-loader" then
					table.insert(to_snap, neighbour)
				end
			end
		end
		-- Rotate or flip linked belt type
		if entity.type == "linked-belt" then
			entity.linked_belt_type = entity.linked_belt_type == "output" and "input" or "output"
		else
			entity.rotate()
		end
	end

	if linked_belt_neighbour then
		entity.connect_linked_belts(linked_belt_neighbour)
	end

	for _, loader in pairs(to_snap) do
		snap(loader, entity)
	end
end

--- @param entity LuaEntity
--- @param chest LuaEntity?
local function sync_chest_filter(entity, chest)
	if not chest then
		chest = entity.surface.find_entity("ee-infinity-loader-chest", entity.position)
	end
	if not chest then
		entity.destroy()
		return
	end
	local filter = entity.get_filter(1)
	if filter then
		chest.set_infinity_container_filter(1, {
			index = 1,
			name = filter,
			count = game.item_prototypes[filter].stack_size * 5,
			mode = "exactly",
		})
	else
		chest.set_infinity_container_filter(1, nil)
	end
end

--- @param e BuiltEvent
local function on_built(e)
	local entity = e.entity or e.created_entity or e.destination
	if not entity.valid then
		return
	end

	if entity.name == "ee-infinity-loader" then
		-- Create chest
		local chest = entity.surface.create_entity({
			name = "ee-infinity-loader-chest",
			position = entity.position,
			force = entity.force,
			create_build_effect_smoke = false,
			raise_built = true,
		})

		if not chest then
			entity.destroy()
			return
		end

		chest.remove_unfiltered_items = true
		sync_chest_filter(entity, chest)
		snap(entity)

		return
	end

	if transport_belt_connectables[entity.type] then
		snap_belt_neighbours(entity)
		if entity.type == "underground-belt" and entity.neighbours then
			snap_belt_neighbours(entity.neighbours)
		elseif entity.type == "linked-belt" and entity.linked_belt_neighbour then
			snap_belt_neighbours(entity.linked_belt_neighbour)
		end
	end
end

--- @param e DestroyedEvent
local function on_destroyed(e)
	local entity = e.entity
	if not entity.valid or entity.name ~= "ee-infinity-loader" then
		return
	end
	local chest = entity.surface.find_entity("ee-infinity-loader-chest", entity.position)
	if chest then
		chest.destroy({ raise_destroy = true })
	end
end

--- @param e EventData.on_player_rotated_entity
local function on_rotated(e)
	local entity = e.entity
	if not entity.valid then
		return
	end
	if entity.name == "ee-infinity-loader" then
		sync_chest_filter(entity)
	end
	if transport_belt_connectables[entity.type] then
		snap_belt_neighbours(entity)
		if entity.type == "underground-belt" and entity.neighbours then
			snap_belt_neighbours(entity.neighbours)
		end
		-- elseif entity.type == "linked-belt" and entity.linked_belt_neighbour then
		--   snap_belt_neighbours(entity.linked_belt_neighbour)
	end
end

--- @param e EventData.on_entity_settings_pasted
local function on_settings_pasted(e)
	local destination = e.destination
	if not destination.valid or destination.name ~= "ee-infinity-loader" then
		return
	end
	-- TODO: Handle to/from a constant combinator
	sync_chest_filter(destination)
end

--- @param e EventData.on_gui_opened
local function on_gui_opened(e)
	if e.gui_type ~= defines.gui_type.entity then
		return
	end
	local entity = e.entity --[[@as LuaEntity]]
	if entity.name == "ee-infinity-loader" then
		global.infinity_loader_open[e.player_index] = entity
	end
end

--- @param e EventData.on_gui_closed
local function on_gui_closed(e)
	if e.gui_type ~= defines.gui_type.entity then
		return
	end
	local loader = global.infinity_loader_open[e.player_index]
	if loader and loader.valid then
		sync_chest_filter(loader)
		global.infinity_loader_open[e.player_index] = nil
	end
end

local infinity_loader = {}

function infinity_loader.on_init()
	--- @type table<uint, LuaEntity>
	global.infinity_loader_open = {}
end

infinity_loader.events = {
	[defines.events.on_built_entity] = on_built,
	[defines.events.on_entity_cloned] = on_built,
	[defines.events.on_entity_died] = on_destroyed,
	[defines.events.on_entity_settings_pasted] = on_settings_pasted,
	[defines.events.on_gui_closed] = on_gui_closed,
	[defines.events.on_gui_opened] = on_gui_opened,
	[defines.events.on_player_mined_entity] = on_destroyed,
	[defines.events.on_player_rotated_entity] = on_rotated,
	[defines.events.on_robot_built_entity] = on_built,
	[defines.events.on_robot_mined_entity] = on_destroyed,
	[defines.events.script_raised_built] = on_built,
	[defines.events.script_raised_destroy] = on_destroyed,
	[defines.events.script_raised_revive] = on_built,
}

infinity_loader.on_nth_tick = {
	[5] = function()
		for _, loader in pairs(global.infinity_loader_open) do
			sync_chest_filter(loader)
		end
	end,
}

return infinity_loader
