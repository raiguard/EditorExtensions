local table = require('__stdlib__/stdlib/utils/table')

-- ------------------------------------------------------------------------------------------
-- ITEMS

-- infinity pipe
local ip_item = data.raw['item']['infinity-pipe']
ip_item.icons = {apply_infinity_tint(ip_item.icons[1])}
ip_item.subgroup = 'ee-misc'
ip_item.order = 'ba'
ip_item.stack_size = 50
ip_item.flags = {}

-- heat interface
local hp_base = data.raw['item']['heat-pipe']
local hi_item = data.raw['item']['heat-interface']
hi_item.subgroup = 'ee-misc'
hi_item.order = 'ca'
hi_item.stack_size = 50
hi_item.icons = {apply_infinity_tint{icon=hp_base.icon, icon_size=hp_base.icon_size, icon_mipmaps=hp_base.icon_mipmaps}}
hi_item.flags = {}

-- infinity radar
local ir_item = table.deepcopy(data.raw['item']['radar'])
ir_item.name = 'infinity-radar'
ir_item.icons = {apply_infinity_tint{icon=ir_item.icon, icon_size=ir_item.icon_size, icon_mipmaps=ir_item.icon_mipmaps}}
ir_item.place_result = 'infinity-radar'
ir_item.subgroup = 'ee-misc'
ir_item.order = 'da'

-- infinity beacon
local ib_item = table.deepcopy(data.raw['item']['beacon'])
ib_item.name = 'infinity-beacon'
ib_item.icons = {apply_infinity_tint{icon=ib_item.icon, icon_size=ib_item.icon_size, icon_mipmaps=ib_item.icon_mipmaps}}
ib_item.place_result = 'infinity-beacon'
ib_item.subgroup='ee-modules'
ib_item.order = 'aa'

-- infinity lab
local lab_item = table.deepcopy(data.raw['item']['lab'])
lab_item.name = 'infinity-lab'
lab_item.icons = {apply_infinity_tint{icon=lab_item.icon, icon_size=lab_item.icon_size, icon_mipmaps=lab_item.icon_mipmaps}}
lab_item.place_result = 'infinity-lab'
lab_item.subgroup = 'ee-misc'
lab_item.order = 'ea'

-- infinity inserter
local ii_item = table.deepcopy(data.raw['item']['filter-inserter'])
ii_item.name = 'infinity-inserter'
ii_item.icons = {apply_infinity_tint{icon=ii_item.icon, icon_size=ii_item.icon_size, icon_mipmaps=ii_item.icon_mipmaps}}
ii_item.place_result = 'infinity-inserter'
ii_item.subgroup = 'ee-misc'
ii_item.order = 'ab'

-- infinity pump
local p_item = table.deepcopy(data.raw['item']['pump'])
p_item.name = 'infinity-pump'
p_item.icons = {apply_infinity_tint{icon=p_item.icon, icon_size=p_item.icon_size, icon_mipmaps=p_item.icon_mipmaps}}
p_item.place_result = 'infinity-pump'
p_item.subgroup = 'ee-misc'
p_item.order = 'bb'

data:extend{ip_item, hi_item, ir_item, ib_item, lab_item, ii_item, p_item}

local reactor_base = data.raw['item']['fusion-reactor-equipment']
local roboport_base = data.raw['item']['personal-roboport-equipment']

data:extend{
    {
        -- Infinity fusion reactor
        type = 'item',
        name = 'infinity-fusion-reactor-equipment',
        icon_size = 32,
        icons = {apply_infinity_tint{icon=reactor_base.icon, icon_size=reactor_base.icon_size, icon_mipmaps=reactor_base.icon_mipmaps}},
        subgroup = 'ee-equipment',
        order = 'aa',
        placed_as_equipment_result = 'infinity-fusion-reactor-equipment',
        stack_size = 50
    },
    {
        -- Infinity personal roboport
        type = 'item',
        name = 'infinity-personal-roboport-equipment',
        icon_size = 32,
        icons = {apply_infinity_tint{icon=roboport_base.icon, icon_size=roboport_base.icon_size, icon_mipmaps=roboport_base.icon_mipmaps}},
        subgroup = 'ee-equipment',
        order = 'ab',
        placed_as_equipment_result = 'infinity-personal-roboport-equipment',
        stack_size = 50
    }
}

register_recipes{'infinity-pipe', 'heat-interface', 'infinity-radar', 'infinity-beacon', 'infinity-lab', 'infinity-inserter',
    'infinity-pump', 'infinity-fusion-reactor-equipment', 'infinity-personal-roboport-equipment'}


-- ------------------------------------------------------------------------------------------
-- ENTITIES

-- infinity pipe
local ip_entity = data.raw['infinity-pipe']['infinity-pipe']
ip_entity.gui_mode = 'all'
ip_entity.icons = ip_item.icons
for name, picture in pairs(ip_entity.pictures) do
    if name ~= 'high_temperature_flow' and name ~= 'middle_temperature_flow' and name ~= 'low_temperature_flow' and name ~= 'gas_flow' then
        apply_infinity_tint(picture)
        if picture.hr_version then
            apply_infinity_tint(picture.hr_version)
        end
    end
end

-- heat interface
local hi_entity = data.raw['heat-interface']['heat-interface']
hi_entity.gui_mode = 'all'
hi_entity.icons = hi_item.icons
hi_entity.picture.filename = '__base__/graphics/entity/heat-pipe/heat-pipe-t-1.png'
apply_infinity_tint(hi_entity.picture)
hi_entity.picture.hr_version = apply_infinity_tint{
    filename = '__base__/graphics/entity/heat-pipe/hr-heat-pipe-t-1.png',
    width = 64,
    height = 64,
    scale = 0.5,
    flags = {'no-crop'}
}

-- infinity radar
local ir_entity = table.deepcopy(data.raw['radar']['radar'])
ir_entity.name = 'infinity-radar'
ir_entity.icons = ir_item.icons
ir_entity.minable.result = 'infinity-radar'
ir_entity.energy_source = {type='void'}
ir_entity.max_distance_of_sector_revealed = 20
ir_entity.max_distance_of_nearby_sector_revealed = 20
for _,t in pairs(ir_entity.pictures.layers) do
    apply_infinity_tint(t)
    apply_infinity_tint(t.hr_version)
end

-- infinity beacon
local ib_entity = table.deepcopy(data.raw['beacon']['beacon'])
ib_entity.name = 'infinity-beacon'
ib_entity.icons = ib_item.icons
ib_entity.minable.result = 'infinity-beacon'
ib_entity.energy_source = {type='void'}
ib_entity.allowed_effects = {'consumption', 'speed', 'productivity', 'pollution'}
ib_entity.supply_area_distance = 64
ib_entity.module_specification = {module_slots=12}
apply_infinity_tint(ib_entity.base_picture)
apply_infinity_tint(ib_entity.animation)

-- infinity lab
local lab_entity = table.deepcopy(data.raw['lab']['lab'])
lab_entity.name = 'infinity-lab'
lab_entity.icons = lab_item.icons
lab_entity.minable.result = 'infinity-lab'
lab_entity.energy_source = {type='void'}
lab_entity.energy_usage = '1W'
lab_entity.researching_speed = 100
lab_entity.module_specification = {module_slots=12}
for _,k in pairs{'on_animation', 'off_animation'} do
    -- ScienceCostTweaker mod removes the layers, so check for that
    if lab_entity[k].layers then
        for i=1,2 do
            apply_infinity_tint(lab_entity[k].layers[i])
            apply_infinity_tint(lab_entity[k].layers[i].hr_version)
        end
    else
        apply_infinity_tint(lab_entity[k])
        if lab_entity[k].hr_version then apply_infinity_tint(lab_entity[k].hr_version) end
    end
end

-- infinity inserter
local ii_entity = table.deepcopy(data.raw['inserter']['filter-inserter'])
ii_entity.name = 'infinity-inserter'
ii_entity.icons = ii_item.icons
ii_entity.placeable_by = {item='infinity-inserter', count=1}
ii_entity.minable.result = 'infinity-inserter'
ii_entity.energy_source = {type='void'}
ii_entity.energy_usage = '1W'
ii_entity.stack = true
ii_entity.filter_count = 5
ii_entity.extension_speed = 1
ii_entity.rotation_speed = 0.5
for _,k in pairs{'hand_base_picture', 'hand_closed_picture', 'hand_open_picture'} do
    apply_infinity_tint(ii_entity[k])
    apply_infinity_tint(ii_entity[k].hr_version)
end
apply_infinity_tint(ii_entity.platform_picture.sheet)
apply_infinity_tint(ii_entity.platform_picture.sheet.hr_version)

-- infinity pump
local p_entity = table.deepcopy(data.raw['pump']['pump'])
p_entity.name = 'infinity-pump'
p_entity.icons = p_item.icons
p_entity.placeable_by = {item='infinity-pump', count=1}
p_entity.minable = {result='infinity-pump', mining_time=0.1}
p_entity.energy_source = {type='void'}
p_entity.energy_usage = '1W'
p_entity.pumping_speed = 1000
for k,t in pairs(p_entity.animations) do
    apply_infinity_tint(t)
    apply_infinity_tint(t.hr_version)
end

data:extend{ir_entity, ib_entity, lab_entity, ii_entity, p_entity}


-- ------------------------------------------------------------------------------------------
-- EQUIPMENT

-- infinity personal fusion reactor
data:extend{
    {
        type = 'generator-equipment',
        name = 'infinity-fusion-reactor-equipment',
        sprite = apply_infinity_tint{
            filename = "__base__/graphics/equipment/fusion-reactor-equipment.png",
            width = 128,
            height = 128,
            priority = "medium"
        },
        shape = {width=1, height=1, type='full'},
        energy_source = {type='electric', usage_priority='primary-output'},
        power = '1000YW',
        categories = {'armor'}
    }
}

local pr_equipment = table.deepcopy(data.raw['roboport-equipment']['personal-roboport-mk2-equipment'])
pr_equipment.name = 'infinity-personal-roboport-equipment'
pr_equipment.shape = {width=1, height=1, type='full'}
pr_equipment.sprite = apply_infinity_tint(pr_equipment.sprite)
pr_equipment.charging_energy = '1000GJ'
pr_equipment.charging_station_count = 1000
pr_equipment.robot_limit = 1000
pr_equipment.construction_radius = 100
pr_equipment.take_result = 'infinity-personal-roboport-equipment'

data:extend{pr_equipment}


-- ------------------------------------------------------------------------------------------
-- MODULES

local function get_module_icon(icon_ref, tint)
    local obj = data.raw['module'][icon_ref]
    return {{icon=obj.icon, icon_size=obj.icon_size, tint=tint}}
end

local module_template = {
    type = 'module',
    subgroup = 'ee-modules',
    stack_size = 50
}

local modules = {
    {name='super-speed-module', icon_ref='speed-module-3', order='ba', category = 'speed', tier=50, effect={speed={bonus=2.5}}, tint={r=0.5,g=0.5,b=1}},
    {name='super-effectivity-module', icon_ref='effectivity-module-3', order='bb', category='effectivity', tier=50, effect={consumption={bonus=-2.5}}, tint={r=0.5,g=1,b=0.5}},
    {name='super-productivity-module', icon_ref='productivity-module-3', order='bc', category='productivity', tier=50, effect={productivity={bonus=2.5}}, tint={r=1,g=0.5,b=0.5}},
    {name='super-clean-module', icon_ref='speed-module-3', order='bd', category='effectivity', tier=50, effect={pollution={bonus=-2.5}}, tint={r=0.5,g=1,b=1}},
    {name='super-slow-module', icon_ref='speed-module', order='ca', category = 'speed', tier=50, effect={speed={bonus=-2.5}}, tint={r=0.5,g=0.5,b=1}},
    {name='super-ineffectivity-module', icon_ref='effectivity-module', order='cb', category = 'effectivity', tier=50, effect={consumption={bonus=2.5}}, tint={r=0.5,g=1,b=0.5}},
    {name='super-dirty-module', icon_ref='speed-module', order='cc', category='effectivity', tier=50, effect={pollution={bonus=2.5}}, tint={r=0.5,g=1,b=1}}
}

for _,v in pairs(modules) do
    v = table.merge(v, module_template)
    v.icons = get_module_icon(v.icon_ref, v.tint)
    v.icon_ref = nil
    data:extend{v}
    register_recipes{v.name}
end