local function shortcut_sprite(suffix, size)
    return {
        filename = '__EditorExtensions__/graphics/shortcut-bar/map-editor-'..suffix,
        priority = 'extra-high-no-scale',
        size = size,
        scale = 1,
        mipmap_count = 2,
        flags = {'icon'}
    }
end
-- MAP EDITOR SHORTCUT
data:extend{
    -- shortcut
    {
        type = 'shortcut',
        name = 'im-toggle-map-editor',
        icon = shortcut_sprite('x32.png', 32),
        disabled_icon = shortcut_sprite('x32-white.png', 32),
        small_icon = shortcut_sprite('x24.png', 24),
        disabled_small_icon = shortcut_sprite('x24-white.png', 24),
        action = 'lua',
        associated_control_input = 'im-toggle-map-editor',
        toggleable = true
    },
    -- custom input
    {
        type = 'custom-input',
        name = 'im-toggle-map-editor',
        key_sequence = 'CONTROL + SHIFT + E',
        action = 'lua'
    }
}