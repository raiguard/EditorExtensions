-- ----------------------------------------------------------------------------------------------------
-- ENTITIES
-- We copy the vanilla definitions instead of creating our own, so many vanilla changes will be immediately reflected in the mod.

-- LOCAL UTILITIES
local empty_sheet = {
    filename = "__core__/graphics/empty.png",
    priority = "very-low",
    width = 1,
    height = 1,
    frame_count = 1,
}

-- INFINITY ACCUMULATOR
do
    local accumulator_types = {'primary-input', 'primary-output', 'secondary-input', 'secondary-output', 'tertiary'}
    local base_entity = table.deepcopy(data.raw['electric-energy-interface']['electric-energy-interface'])
    base_entity.minable.result = 'infinity-accumulator'
    base_entity.picture.layers[1] = apply_infinity_tint(base_entity.picture.layers[1])
    base_entity.picture.layers[1].hr_version = apply_infinity_tint(base_entity.picture.layers[1].hr_version)
    base_entity.localised_description = {'entity-description.infinity-accumulator'}
    local accumulator_icons = {apply_infinity_tint(base_entity.icons[1])}

    for _,t in pairs(accumulator_types) do
        local entity = table.deepcopy(base_entity)
        entity.name = 'infinity-accumulator-' .. t
        entity.icons = accumulator_icons
        entity.energy_source = {type='electric', usage_priority=t, buffer_capacity='500GJ'}
        entity.subgroup = 'ee-electricity'
        entity.order = 'a'
        entity.minable.result = 'infinity-accumulator'
        entity.placeable_by = {item='infinity-accumulator', count=1}
        data:extend{entity}
    end
end

-- INFINITY BEACON
local infinity_beacon = table.deepcopy(data.raw['beacon']['beacon'])
infinity_beacon.name = 'infinity-beacon'
infinity_beacon.icons = {apply_infinity_tint(extract_icon_info(infinity_beacon))}
infinity_beacon.minable.result = 'infinity-beacon'
infinity_beacon.energy_source = {type='void'}
infinity_beacon.allowed_effects = {'consumption', 'speed', 'productivity', 'pollution'}
infinity_beacon.supply_area_distance = 64
infinity_beacon.module_specification = {module_slots=12}
apply_infinity_tint(infinity_beacon.base_picture)
apply_infinity_tint(infinity_beacon.animation)
data:extend{infinity_beacon}

-- INFINITY AND TESSERACT CHESTS
do
    -- modify existing chest sizes
    data.raw['infinity-container']['infinity-chest'].inventory_size = 100
    data.raw['infinity-container']['infinity-chest'].gui_mode = 'all'

    local base_entity = table.deepcopy(data.raw['infinity-container']['infinity-chest'])
    local infinity_chest_picture = table.deepcopy(base_entity.picture)

    for lm,d in pairs(infinity_chest_data) do
        local chest = table.deepcopy(data.raw['logistic-container']['logistic-chest-' .. lm])
        chest.type = 'infinity-container'
        chest.name = 'infinity-chest-' .. lm
        chest.order = d.o
        chest.subgroup = 'ee-inventories'
        chest.icons = {{icon=base_entity.icon, icon_size=base_entity.icon_size, icon_mipmaps=base_entity.icon_mipmaps, tint=d.t}}
        chest.erase_contents_when_mined = true
        chest.picture = table.deepcopy(infinity_chest_picture)
        chest.picture.layers[1].tint = d.t
        chest.picture.layers[1].hr_version.tint = d.t
        chest.animation = nil
        chest.logistic_slots_count = d.s
        chest.minable.result = 'infinity-chest-' .. lm
        chest.render_not_in_network_icon = true
        chest.inventory_size = 100
        chest.next_upgrade = nil
        chest.flags = {'player-creation'}
        data:extend{chest}
    end

    -- tesseract chests
    -- create the chests here to let other mods modify them. increase their inventory size in data-final-fixes
    local compilatron_chest = data.raw['container']['compilatron-chest']
    local comp_chest_picture = table.deepcopy(compilatron_chest.picture)
    comp_chest_picture.layers[1].shift = util.by_pixel(0,-4.25)
    comp_chest_picture.layers[1].hr_version.shift = util.by_pixel(0,-4.25)
    for lm,d in pairs(tesseract_chest_data) do
        local suffix = lm == '' and lm or '-'..lm
        local chest = table.deepcopy(data.raw['infinity-container']['infinity-chest'..suffix])
        chest.name = 'tesseract-chest'..suffix
        chest.order = d.o
        chest.icons = {{icon=compilatron_chest.icon, icon_size=compilatron_chest.icon_size, icon_mipmaps=compilatron_chest.icon_mipmaps, tint=d.t}}
        chest.picture = table.deepcopy(comp_chest_picture)
        chest.picture.layers[1].tint = d.t
        chest.picture.layers[1].hr_version.tint = d.t
        chest.logistic_slots_count = 0
        chest.minable.result = 'tesseract-chest'..suffix
        chest.enable_inventory_bar = false
        chest.flags = {'player-creation', 'hide-alt-info'}
        data:extend{chest}
    end
end

-- INFINITY HEAT PIPE
-- This is actually the heat interface, we're just changing the name and appearance.
local infinity_heat_pipe = data.raw['heat-interface']['heat-interface']
infinity_heat_pipe.gui_mode = 'all'
infinity_heat_pipe.icons = {apply_infinity_tint(extract_icon_info(data.raw['item']['heat-pipe']))}
infinity_heat_pipe.picture.filename = '__base__/graphics/entity/heat-pipe/heat-pipe-t-1.png'
apply_infinity_tint(infinity_heat_pipe.picture)
infinity_heat_pipe.picture.hr_version = apply_infinity_tint{
    filename = '__base__/graphics/entity/heat-pipe/hr-heat-pipe-t-1.png',
    width = 64,
    height = 64,
    scale = 0.5,
    flags = {'no-crop'}
}

-- INFINITY INSERTER
local infinity_inserter = table.deepcopy(data.raw['inserter']['filter-inserter'])
infinity_inserter.name = 'infinity-inserter'
infinity_inserter.icons = {apply_infinity_tint(extract_icon_info(infinity_inserter))}
infinity_inserter.placeable_by = {item='infinity-inserter', count=1}
infinity_inserter.minable.result = 'infinity-inserter'
infinity_inserter.energy_source = {type='void'}
infinity_inserter.energy_usage = '1W'
infinity_inserter.stack = true
infinity_inserter.filter_count = 5
infinity_inserter.extension_speed = 1
infinity_inserter.rotation_speed = 0.5
for _,k in pairs{'hand_base_picture', 'hand_closed_picture', 'hand_open_picture'} do
    apply_infinity_tint(infinity_inserter[k])
    apply_infinity_tint(infinity_inserter[k].hr_version)
end
apply_infinity_tint(infinity_inserter.platform_picture.sheet)
apply_infinity_tint(infinity_inserter.platform_picture.sheet.hr_version)
data:extend{infinity_inserter}

-- INFINITY LAB
local infinity_lab = table.deepcopy(data.raw['lab']['lab'])
infinity_lab.name = 'infinity-lab'
infinity_lab.icons = {apply_infinity_tint(extract_icon_info(infinity_lab))}
infinity_lab.minable.result = 'infinity-lab'
infinity_lab.energy_source = {type='void'}
infinity_lab.energy_usage = '1W'
infinity_lab.researching_speed = 100
infinity_lab.module_specification = {module_slots=12}
for _,k in pairs{'on_animation', 'off_animation'} do
    -- ScienceCostTweaker mod removes the layers, so check for that
    if infinity_lab[k].layers then
        for i=1,2 do
            apply_infinity_tint(infinity_lab[k].layers[i])
            apply_infinity_tint(infinity_lab[k].layers[i].hr_version)
        end
    else
        apply_infinity_tint(infinity_lab[k])
        if infinity_lab[k].hr_version then apply_infinity_tint(infinity_lab[k].hr_version) end
    end
end
data:extend{infinity_lab}

-- INFINITY LOADER
-- Create everything except the actual loaders here. We create those in data-updates so they can get every belt type.
do
    local loader_base = table.deepcopy(data.raw['underground-belt']['underground-belt'])
    loader_base.icons = {apply_infinity_tint{icon='__EditorExtensions__/graphics/item/infinity-loader.png', icon_size=32, icon_mipmaps=0}}

    local base_loader_path = '__base__/graphics/entity/underground-belt/'

    data:extend{
        -- infinity chest
        {
            type = 'infinity-container',
            name = 'infinity-loader-chest',
            erase_contents_when_mined = true,
            inventory_size = 10,
            flags = {'hide-alt-info'},
            picture = empty_sheet,
            icons = loader_base.icons,
            collision_box = {{-0.05,-0.05},{0.05,0.05}}
        },
        -- logic combinator (what you actually interact with)
        {
            type = 'constant-combinator',
            name = 'infinity-loader-logic-combinator',
            localised_name = {'entity-name.infinity-loader'},
            order = 'a',
            collision_box = loader_base.collision_box,
            selection_box = loader_base.selection_box,
            fast_replaceable_group = 'transport-belt',
            placeable_by = {item='infinity-loader', count=1},
            minable = {result='infinity-loader', mining_time=0.1},
            flags = {'player-creation', 'hidden'},
            item_slot_count = 2,
            sprites = empty_sheet,
            activity_led_sprites = empty_sheet,
            activity_led_light_offsets = {{0,0}, {0,0}, {0,0}, {0,0}},
            circuit_wire_connection_points = {
                {wire={},shadow={}},
                {wire={},shadow={}},
                {wire={},shadow={}},
                {wire={},shadow={}}
            }
        }
    }

    -- create spritesheet for dummy combinator
    local sprite_files = {
        {base_loader_path..'underground-belt-structure-back-patch.png', base_loader_path..'hr-underground-belt-structure-back-patch.png'},
        {'__EditorExtensions__/graphics/entity/infinity-loader.png', '__EditorExtensions__/graphics/entity/hr-infinity-loader.png'},
        {base_loader_path..'underground-belt-structure-front-patch.png', base_loader_path..'hr-underground-belt-structure-front-patch.png'},
    }
    local sprite_x = {south=96*0, west=96*1, north=96*2, east=96*3}
    local sprites = {}
    for k,x in pairs(sprite_x) do
        sprites[k] = {}
        sprites[k].layers = {}
        for i,t in pairs(sprite_files) do
            sprites[k].layers[i] = apply_infinity_tint{
                filename = t[1],
                x = x,
                width = 96,
                height = 96,
                hr_version = apply_infinity_tint{
                    filename = t[2],
                    x = x * 2,
                    width = 192,
                    height = 192,
                    scale = 0.5
                }
            }
        end
    end

    -- dummy combinator (for placement and blueprints)
    local dummy_combinator = table.deepcopy(data.raw['constant-combinator']['infinity-loader-logic-combinator'])
    dummy_combinator.name = 'infinity-loader-dummy-combinator'
    dummy_combinator.localised_description = {'entity-description.infinity-loader'}
    dummy_combinator.selection_box = nil
    dummy_combinator.minable = nil
    dummy_combinator.flags = {'player-creation'}
    dummy_combinator.icons = loader_base.icons
    dummy_combinator.sprites = sprites
    data:extend{dummy_combinator}

    -- inserter
    local filter_inserter = data.raw['inserter']['stack-filter-inserter']
    data:extend{
        {
            type = 'inserter',
            name = 'infinity-loader-inserter',
            icons = {apply_infinity_tint{icon='__EditorExtensions__/graphics/item/infinity-loader.png', icon_size=32}},
            stack = true,
            collision_box = {{-0.1,-0.1}, {0.1,0.1}},
            -- selection_box = {{-0.1,-0.1}, {0.1,0.1}},
            -- selection_priority = 99,
            selectable_in_game = false,
            allow_custom_vectors = true,
            energy_source = {type='void'},
            extension_speed = 1,
            rotation_speed = 0.5,
            energy_per_movement = '0.00001J',
            energy_per_extension = '0.00001J',
            pickup_position = {0, -0.2},
            insert_position = {0, 0.2},
            filter_count = 1,
            draw_held_item = false,
            platform_picture = empty_sheet,
            hand_base_picture = empty_sheet,
            hand_open_picture = empty_sheet,
            hand_closed_picture = empty_sheet,
            -- hand_base_picture = filter_inserter.hand_base_picture,
            -- hand_open_picture = filter_inserter.hand_open_picture,
            -- hand_closed_picture = filter_inserter.hand_closed_picture,
            draw_inserter_arrow = false,
            flags = {'hide-alt-info', 'hidden'}
        }
    }
end

-- INFINITY LOCOMOTIVE
local infinity_locomotive = table.deepcopy(data.raw['locomotive']['locomotive'])
infinity_locomotive.name = 'infinity-locomotive'
infinity_locomotive.icons = {apply_infinity_tint(extract_icon_info(infinity_locomotive))}
infinity_locomotive.max_power = '10MW'
infinity_locomotive.energy_source = {type='void'}
infinity_locomotive.max_speed = 10
infinity_locomotive.reversing_power_modifier = 1
infinity_locomotive.braking_force = 100
infinity_locomotive.minable.result = 'infinity-locomotive'
infinity_locomotive.allow_manual_color = false
infinity_locomotive.color = {r=0, g=0, b=0, a=0.5}
for i=1,2 do
    apply_infinity_tint(infinity_locomotive.pictures.layers[i])
    -- diesel locomotives compatability
    if infinity_locomotive.pictures.layers[i].hr_version then
        apply_infinity_tint(infinity_locomotive.pictures.layers[i].hr_version)
    end
end
data:extend{infinity_locomotive}

-- INFINITY PIPE
-- This already exists, we're just changing the color
local infinity_pipe = data.raw['infinity-pipe']['infinity-pipe']
infinity_pipe.gui_mode = 'all'
infinity_pipe.icons = {apply_infinity_tint(infinity_pipe.icons[1])}
for name, picture in pairs(infinity_pipe.pictures) do
    if name ~= 'high_temperature_flow' and name ~= 'middle_temperature_flow' and name ~= 'low_temperature_flow' and name ~= 'gas_flow' then
        apply_infinity_tint(picture)
        if picture.hr_version then
            apply_infinity_tint(picture.hr_version)
        end
    end
end

-- INFINITY POWER POLES
do
    local infinity_power_pole = table.deepcopy(data.raw['electric-pole']['big-electric-pole'])
    infinity_power_pole.name = 'infinity-electric-pole'
    infinity_power_pole.icons = {apply_infinity_tint(extract_icon_info(infinity_power_pole))}
    infinity_power_pole.subgroup = 'ee-electricity'
    infinity_power_pole.order = 'ba'
    infinity_power_pole.minable.result = 'infinity-electric-pole'
    for _,t in pairs(infinity_power_pole.pictures.layers) do
        apply_infinity_tint(t)
        apply_infinity_tint(t.hr_version)
    end
    infinity_power_pole.maximum_wire_distance = 64

    local infinity_substation = table.deepcopy(data.raw['electric-pole']['substation'])
    infinity_substation.name = 'infinity-substation'
    infinity_substation.icons = {apply_infinity_tint(extract_icon_info(infinity_substation))}
    infinity_substation.subgroup = 'ee-electricity'
    infinity_substation.order = 'bb'
    infinity_substation.minable.result = 'infinity-substation'
    for _,t in pairs(infinity_substation.pictures.layers) do
        apply_infinity_tint(t)
        apply_infinity_tint(t.hr_version)
    end
    infinity_substation.maximum_wire_distance = 64
    infinity_substation.supply_area_distance = 64

    data:extend{infinity_power_pole, infinity_substation}
end

-- INFINITY PUMP
local infinity_pump = table.deepcopy(data.raw['pump']['pump'])
infinity_pump.name = 'infinity-pump'
infinity_pump.icons = {apply_infinity_tint(extract_icon_info(infinity_pump))}
infinity_pump.placeable_by = {item='infinity-pump', count=1}
infinity_pump.minable = {result='infinity-pump', mining_time=0.1}
infinity_pump.energy_source = {type='void'}
infinity_pump.energy_usage = '1W'
infinity_pump.pumping_speed = 1000
for k,t in pairs(infinity_pump.animations) do
    apply_infinity_tint(t)
    apply_infinity_tint(t.hr_version)
end
data:extend{infinity_pump}

-- INFINITY RADAR
local infinity_radar = table.deepcopy(data.raw['radar']['radar'])
infinity_radar.name = 'infinity-radar'
infinity_radar.icons = {apply_infinity_tint(extract_icon_info(infinity_radar))}
infinity_radar.minable.result = 'infinity-radar'
infinity_radar.energy_source = {type='void'}
infinity_radar.max_distance_of_sector_revealed = 20
infinity_radar.max_distance_of_nearby_sector_revealed = 20
for _,t in pairs(infinity_radar.pictures.layers) do
    apply_infinity_tint(t)
    apply_infinity_tint(t.hr_version)
end
data:extend{infinity_radar}

-- INFINITY ROBOPORT
local infinity_roboport = table.deepcopy(data.raw['roboport']['roboport'])
infinity_roboport.name = 'infinity-roboport'
infinity_roboport.icons = {apply_infinity_tint(extract_icon_info(infinity_roboport))}
infinity_roboport.logistics_radius = 200
infinity_roboport.construction_radius = 400
infinity_roboport.energy_source = {type='void'}
infinity_roboport.charging_energy = "1000YW"
infinity_roboport.minable.result = 'infinity-roboport'
for _,k in pairs{'base', 'base_patch', 'base_animation', 'door_animation_up', 'door_animation_down', 'recharging_animation'} do
    if infinity_roboport[k].layers then
        for _,k2 in pairs(infinity_roboport[k].layers) do
            apply_infinity_tint(k2)
            apply_infinity_tint(k2.hr_version)
        end
    else
        infinity_roboport[k].tint = infinity_tint
        if infinity_roboport[k].hr_version then infinity_roboport[k].hr_version.tint = infinity_tint end
    end
end
data:extend{infinity_roboport}

-- INFINITY ROBOTS
do
    local tint_keys = {'idle', 'in_motion', 'working', 'idle_with_cargo', 'in_motion_with_cargo'}
    local modifiers = {
        speed = 100,
        max_energy = '0kJ',
        energy_per_tick = '0kJ',
        energy_per_move = '0kJ',
        min_to_charge = 0,
        max_to_charge = 0,
        speed_multiplier_when_out_of_energy = 1
    }
    local function set_params(e)
        for _,k in pairs(tint_keys) do
            if e[k] then
                apply_infinity_tint(e[k])
                apply_infinity_tint(e[k].hr_version)
            end
        end
        for k,v in pairs(modifiers) do e[k] = v end
    end

    local construction_robot = table.deepcopy(data.raw['construction-robot']['construction-robot'])
    construction_robot.name = 'infinity-construction-robot'
    construction_robot.icons = {apply_infinity_tint(extract_icon_info(construction_robot))}
    set_params(construction_robot)
    construction_robot.flags = {'hidden'}

    local logistic_robot = table.deepcopy(data.raw['logistic-robot']['logistic-robot'])
    logistic_robot.name = 'infinity-logistic-robot'
    logistic_robot.icons = {apply_infinity_tint(extract_icon_info(logistic_robot))}
    set_params(logistic_robot)
    logistic_robot.flags = {'hidden'}

    data:extend{construction_robot, logistic_robot, infinity_roboport}
end

-- INFINITY WAGONS
do
    local cargo_wagon = table.deepcopy(data.raw['cargo-wagon']['cargo-wagon'])
    cargo_wagon.name = 'infinity-cargo-wagon'
    cargo_wagon.icons = {apply_infinity_tint(extract_icon_info(cargo_wagon))}
    cargo_wagon.inventory_size = 100
    cargo_wagon.minable.result = 'infinity-cargo-wagon'
    for _,t in pairs(cargo_wagon.pictures.layers) do
        apply_infinity_tint(t)
        apply_infinity_tint(t.hr_version)
    end
    for _,t in pairs(cargo_wagon.horizontal_doors.layers) do
        apply_infinity_tint(t)
        apply_infinity_tint(t.hr_version)
    end
    for _,t in pairs(cargo_wagon.vertical_doors.layers) do
        apply_infinity_tint(t)
        apply_infinity_tint(t.hr_version)
    end

    local fluid_wagon = table.deepcopy(data.raw['fluid-wagon']['fluid-wagon'])
    fluid_wagon.name = 'infinity-fluid-wagon'
    fluid_wagon.icons = {apply_infinity_tint(extract_icon_info(fluid_wagon))}
    fluid_wagon.minable.result = 'infinity-fluid-wagon'
    for _,t in pairs(fluid_wagon.pictures.layers) do
        apply_infinity_tint(t)
        apply_infinity_tint(t.hr_version)
    end

    -- non-interactable chest and pipe
    local infinity_wagon_chest = table.deepcopy(data.raw['infinity-container']['infinity-chest'])
    infinity_wagon_chest.name = 'infinity-wagon-chest'
    infinity_wagon_chest.icons = {apply_infinity_tint(extract_icon_info(infinity_wagon_chest))}
    infinity_wagon_chest.picture = empty_sheet
    infinity_wagon_chest.collision_mask = {'layer-15'}
    infinity_wagon_chest.selection_box = nil
    infinity_wagon_chest.selectable_in_game = false
    infinity_wagon_chest.flags = {'hide-alt-info', 'hidden'}

    local infinity_wagon_pipe = table.deepcopy(data.raw['infinity-pipe']['infinity-pipe'])
    infinity_wagon_pipe.name = 'infinity-wagon-pipe'
    infinity_wagon_pipe.icons = {apply_infinity_tint(infinity_wagon_pipe.icons[1])}
    infinity_wagon_pipe.collision_mask = {'layer-15'}
    infinity_wagon_pipe.selection_box = nil
    infinity_wagon_pipe.selectable_in_game = false
    infinity_wagon_pipe.order = 'a'
    infinity_wagon_pipe.flags = {'hide-alt-info', 'hidden'}

    for k,t in pairs(infinity_wagon_pipe.pictures) do
        infinity_wagon_pipe.pictures[k] = empty_sheet
    end

    data:extend{cargo_wagon, fluid_wagon, infinity_wagon_chest, infinity_wagon_pipe}
end