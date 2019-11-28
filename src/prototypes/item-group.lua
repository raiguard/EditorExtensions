local function add_group(name, order)
    data:extend{
        {
            type = 'item-subgroup',
            group = 'im-tools',
            name = name,
            order = order
        }
    }
end

add_group('im-inventories', 'a')
add_group('im-misc', 'b')
add_group('im-electricity', 'c')
add_group('im-trains', 'd')
add_group('im-robots', 'e')
add_group('im-modules', 'f')
add_group('im-equipment', 'g')

data:extend {
    {
        type = 'item-group',
        name = 'im-tools',
        order = 'zzzzz',
        icon = '__EditorExtensions__/graphics/gui/crafting-group.png',
        icon_size = 128
    }
}