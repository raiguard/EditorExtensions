local math2d = require('__core__/lualib/math2d')
local util = require('__core__/lualib/util')

-- returns true if the table contains the specified value
function table.contains(table, value)
    for k,v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- returns the player and his global table
function util.get_player(obj)
    if type(obj) == 'number' then return game.players[obj], global.players[obj] -- gave the player_index itself
    elseif obj.index then return game.players[obj.index], global.players[obj.index] -- gave a player object
    else return game.players[obj.player_index], global.players[obj.player_index] end -- gave the event table
end

-- just returns the player table
function util.player_table(obj)
    if type(obj) == 'number' then return global.players[obj] -- gave the player_index itself
    elseif obj.index then return global.players[obj.index] -- gave a player object
    else return global.players[obj.player_index] end -- gave the event table
end

-- prints the contents of the event table
function util.debug_print(e)
    print(serpent.block(e))
end

util.constants = {
    -- commonly-used set of events for when an entity is built
    entity_built_events = {
        defines.events.on_built_entity,
        defines.events.on_robot_built_entity,
        defines.events.script_raised_built,
        defines.events.script_raised_revive
    },
    -- commonly-used set of events for when an entity is destroyed
    entity_destroyed_events = {
        defines.events.on_player_mined_entity,
        defines.events.on_robot_mined_entity,
        defines.events.on_entity_died,
        defines.events.script_raised_destroy
    },
    -- close button for frames, as defined in the titlebar submodule
    close_button_def = {
        name = 'close',
        sprite = 'utility/close_white',
        hovered_sprite = 'utility/close_black',
        clicked_sprite = 'utility/close_black'
    },
    -- vectors for neighboring tiles, in order of defines.direction
    neighbor_tile_vectors = {
        [defines.direction.north] = {x=0,y=-1},
        [defines.direction.northeast] = {x=1,y=-1},
        [defines.direction.east] = {x=1,y=-0},
        [defines.direction.southeast] = {x=1,y=1},
        [defines.direction.south] = {x=0,y=1},
        [defines.direction.southwest] = {x=-1,y=1},
        [defines.direction.west] = {x=-1,y=0},
        [defines.direction.northwest] = {x=-1,y=-1}
    }
}

util.area = math2d.bounding_box

util.entity = {}

-- apply the function to each belt neighbor connected to this entity, and return entities for which the function returned true
function util.entity.check_belt_neighbors(entity, func, type_agnostic, return_true)
    local belt_neighbors = entity.belt_neighbours
    local matched_entities = {}
    for _,type in pairs{'inputs', 'outputs'} do
        if not type_agnostic then matched_entities[type] = {} end
        for _,e in ipairs(belt_neighbors[type] or {}) do
            if func(e) then
                if return_true then
                    return true
                end
                table.insert(type_agnostic and matched_entities or matched_entities[type], e)
            end
        end
    end
    return matched_entities
end

-- apply the function to each entity on neighboring tiles, returning entities for which the function returned true
function util.entity.check_neighbors(entity, func, inc_corners, dir_agnostic)
    local matched_entities = {}
    for i=0,7,inc_corners and 1 or 2 do
        if not dir_agnostic then matched_entities[i] = {} end
        local entities = entity.surface.find_entities(util.position.to_tile_area(util.position.add(entity.position, util.constants.neighbor_tile_vectors[i])))
        for _,e in ipairs(entities) do
            if func(e) then
                table.insert(dir_agnostic and matched_entities or matched_entities[i], e)
            end
        end
    end
    return matched_entities
end

util.direction = {}

-- borrowed from STDLIB: returns the next or previous direction
function util.direction.next_direction(direction, reverse, eight_way)
    return (direction + (eight_way and ((reverse and -1) or 1) or ((reverse and -2) or 2))) % 8
end

util.position = math2d.position

function util.position.to_tile_area(pos)
    return {
        left_top = {x=math.floor(pos.x), y=math.floor(pos.y)},
        right_bottom = {x=math.ceil(pos.x), y=math.ceil(pos.y)}
    }
end

util.textfield = {}

function util.textfield.clamp_number_input(element, clamps, last_value)
    local text = element.text
    if text == ''
    or (clamps[1] and tonumber(text) < clamps[1])
    or (clamps[2] and tonumber(text) > clamps[2]) then
        element.style = 'ee_invalid_slider_textfield'
    else
        element.style = 'ee_slider_textfield'
        last_value = text
    end
    return last_value
end

function util.textfield.set_last_valid_value(element, last_value)
    if element.text ~= last_value then
        element.text = last_value
        element.style = 'ee_slider_textfield'
    end
    return element.text
end

return util