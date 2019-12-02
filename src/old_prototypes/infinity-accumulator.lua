-- ------------------------------------------------------------------------------------------
-- ITEMS

local base_accumulator = data.raw['accumulator']['accumulator']

data:extend{
    {
        type = 'item',
        name = 'infinity-accumulator',
        stack_size = 50,
        icons = {apply_infinity_tint{icon=base_accumulator.icon, icon_size=base_accumulator.icon_size, icon_mipmaps=base_accumulator.icon_mipmaps}},
        place_result = 'infinity-accumulator-primary-output',
        subgroup = 'ee-electricity',
        order = 'a'
    }
}

register_recipes{'infinity-accumulator'}

-- ------------------------------------------------------------------------------------------
-- ENTITIES

local ia_types = {'primary-input', 'primary-output', 'secondary-input', 'secondary-output', 'tertiary'}
local ia_entity = table.deepcopy(data.raw['electric-energy-interface']['electric-energy-interface'])
ia_entity.minable.result = 'infinity-accumulator'
ia_entity.picture.layers[1] = apply_infinity_tint(ia_entity.picture.layers[1])
ia_entity.picture.layers[1].hr_version = apply_infinity_tint(ia_entity.picture.layers[1].hr_version)
ia_entity.localised_description = {'entity-description.infinity-accumulator'}
local ia_icons = data.raw['item']['infinity-accumulator'].icons

for _,t in pairs(ia_types) do
    local ia = table.deepcopy(ia_entity)
    ia.name = 'infinity-accumulator-' .. t
    ia.icons = ia_icons
    ia.energy_source = {type='electric', usage_priority=t, buffer_capacity='500GJ'}
    ia.subgroup = 'ee-electricity'
    ia.order = 'a'
    ia.minable.result = 'infinity-accumulator'
    ia.placeable_by = {item='infinity-accumulator', count=1}
    data:extend{ia}
end