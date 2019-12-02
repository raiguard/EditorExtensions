-- ------------------------------------------------------------------------------------------
-- ITEMS

local cr_item = table.deepcopy(data.raw['item']['construction-robot'])
cr_item.name = 'infinity-construction-robot'
cr_item.icons = {apply_infinity_tint{icon=cr_item.icon, icon_size=cr_item.icon_size, icon_mipmaps=cr_item.icon_mipmaps}}
cr_item.place_result = 'infinity-construction-robot'
cr_item.subgroup = 'ee-robots'
cr_item.order = 'ba'
cr_item.stack_size = 100

local lr_item = table.deepcopy(data.raw['item']['logistic-robot'])
lr_item.name = 'infinity-logistic-robot'
lr_item.icons = {apply_infinity_tint{icon=lr_item.icon, icon_size=lr_item.icon_size, icon_mipmaps=lr_item.icon_mipmaps}}
lr_item.place_result = 'infinity-logistic-robot'
lr_item.subgroup = 'ee-robots'
lr_item.order = 'bb'
lr_item.stack_size = 100

local ir_item = table.deepcopy(data.raw['item']['roboport'])
ir_item.name = 'infinity-roboport'
ir_item.icons = {apply_infinity_tint{icon=ir_item.icon, icon_size=ir_item.icon_size, icon_mipmaps=ir_item.icon_mipmaps}}
ir_item.place_result = 'infinity-roboport'
ir_item.subgroup = 'ee-robots'
ir_item.order = 'a'
ir_item.stack_size = 50

data:extend{cr_item, lr_item, ir_item}

register_recipes{'infinity-construction-robot', 'infinity-logistic-robot', 'infinity-roboport'}

-- ------------------------------------------------------------------------------------------
-- ENTITIES

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

local cr_entity = table.deepcopy(data.raw['construction-robot']['construction-robot'])
cr_entity.name = 'infinity-construction-robot'
cr_entity.icons = cr_item.icons
set_params(cr_entity)
cr_entity.flags = {'hidden'}

local lr_entity = table.deepcopy(data.raw['logistic-robot']['logistic-robot'])
lr_entity.name = 'infinity-logistic-robot'
lr_entity.icons = lr_item.icons
set_params(lr_entity)
lr_entity.flags = {'hidden'}

local ir_tint_keys = {'base', 'base_patch', 'base_animation', 'door_animation_up', 'door_animation_down', 'recharging_animation'}
local ir_entity = table.deepcopy(data.raw['roboport']['roboport'])
ir_entity.name = 'infinity-roboport'
ir_entity.icons = ir_item.icons
ir_entity.logistics_radius = 200
ir_entity.construction_radius = 400
ir_entity.energy_source = {type='void'}
ir_entity.charging_energy = "1000YW"
ir_entity.minable.result = 'infinity-roboport'

for _,k in pairs(ir_tint_keys) do
    if ir_entity[k].layers then
        for _,k2 in pairs(ir_entity[k].layers) do
            apply_infinity_tint(k2)
            apply_infinity_tint(k2.hr_version)
        end
    else
        ir_entity[k].tint = infinity_tint
        if ir_entity[k].hr_version then ir_entity[k].hr_version.tint = infinity_tint end
    end
end

data:extend{cr_entity, lr_entity, ir_entity}