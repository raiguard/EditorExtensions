-- ----------------------------------------------------------------------------------------------------
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

local personal_roboport = table.deepcopy(data.raw['roboport-equipment']['personal-roboport-mk2-equipment'])
personal_roboport.name = 'infinity-personal-roboport-equipment'
personal_roboport.shape = {width=1, height=1, type='full'}
personal_roboport.sprite = apply_infinity_tint(personal_roboport.sprite)
personal_roboport.charging_energy = '1000GJ'
personal_roboport.charging_station_count = 1000
personal_roboport.robot_limit = 1000
personal_roboport.construction_radius = 100
personal_roboport.take_result = 'infinity-personal-roboport-equipment'
data:extend{personal_roboport}