data:extend{
    -- STARTUP SETTINGS
    {
        type = 'int-setting',
        name = 'ee-controller-inventory_size',
        setting_type = 'startup',
        default_value = 150,
        order = 'a'
    },
    {
        type = 'bool-setting',
        name = 'ee-controller-enable_flash_light',
        setting_type = 'startup',
        default_value = true,
        order = 'b'
    },
    {
        type = 'bool-setting',
        name = 'ee-controller-render_as_day',
        setting_type = 'startup',
        default_value = false,
        order = 'c'
    },
    {
        type = 'bool-setting',
        name = 'ee-controller-instant_blueprint_building',
        setting_type = 'startup',
        default_value = true,
        order = 'da'
    },
    {
        type = 'bool-setting',
        name = 'ee-controller-instant_deconstruction',
        setting_type = 'startup',
        default_value = true,
        order = 'db'
    },
    {
        type = 'bool-setting',
        name = 'ee-controller-instant_upgrading',
        setting_type = 'startup',
        default_value = true,
        order = 'dc'
    },
    {
        type = 'bool-setting',
        name = 'ee-controller-instant_rail_planner',
        setting_type = 'startup',
        default_value = true,
        order = 'dd'
    },
    {
        type = 'bool-setting',
        name = 'ee-controller-fill_built_entity_energy_buffers',
        setting_type = 'startup',
        default_value = true,
        order = 'e'
    },
    {
        type = 'bool-setting',
        name = 'ee-controller-show_character_tab_in_controller_gui',
        setting_type = 'startup',
        default_value = true,
        order = 'fa'
    },
    {
        type = 'bool-setting',
        name = 'ee-controller-show_infinity_filters_in_controller_gui',
        setting_type = 'startup',
        default_value = true,
        order = 'fb'
    },
    {
        type = 'bool-setting',
        name = 'ee-tesseract-include-hidden',
        setting_type = 'runtime-global',
        default_value = false,
        order = 'b'
    }
}