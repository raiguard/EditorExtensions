data:extend{
    {
        type = 'string-setting',
        name = 'im-new-map-behavior',
        setting_type = 'runtime-global',
        default_value = 'Ask',
        allowed_values = {'Ask', 'Yes, cheats on', 'Yes, cheats off', 'Editor-only mode', 'No'},
        order = 'a'
    },
    {
        type = 'bool-setting',
        name = 'im-tesseract-include-hidden',
        setting_type = 'runtime-global',
        default_value = false,
        order = 'b'
    }
}