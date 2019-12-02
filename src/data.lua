-- ----------------------------------------------------------------------------------------------------
-- EDITOR EXTENSIONS PROTOTYPES

-- UTILITIES
infinity_tint = {r=1, g=0.5, b=1, a=1}
combinator_tint = {r=0.8, g=0.5, b=1, a=1}
function apply_infinity_tint(t, tint)
    t.tint = tint or infinity_tint
    return t
end

infinity_chest_data = {
    ['active-provider'] = {s=0, t={218,115,255}, o='ab'},
    ['passive-provider'] = {s=0, t={255,141,114}, o='ac'},
    ['storage'] = {s=1, t={255,220,113}, o='ad'},
    ['buffer'] = {s=30, t={114,255,135}, o='ae'},
    ['requester'] = {s=30, t={114,236,255}, o='af'}
}
tesseract_chest_data = {
    [''] = {t={255,255,255}, o='ba'},
    ['passive-provider'] = {t={255,141,114}, o='bb'},
    ['storage'] = {t={255,220,113}, o='bc'}
}

function extract_icon_info(obj)
    return {icon=obj.icon, icon_size=obj.icon_size, icon_mipmaps=obj.icon_mipmaps}
end

module_data = {
    {name='super-speed-module', icon_ref='speed-module-3', order='ba', category = 'speed', tier=50, effect={speed={bonus=2.5}}, tint={r=0.5,g=0.5,b=1}},
    {name='super-effectivity-module', icon_ref='effectivity-module-3', order='bb', category='effectivity', tier=50, effect={consumption={bonus=-2.5}},
     tint={r=0.5,g=1,b=0.5}},
    {name='super-productivity-module', icon_ref='productivity-module-3', order='bc', category='productivity', tier=50, effect={productivity={bonus=2.5}},
     tint={r=1,g=0.5,b=0.5}},
    {name='super-clean-module', icon_ref='speed-module-3', order='bd', category='effectivity', tier=50, effect={pollution={bonus=-2.5}}, tint={r=0.5,g=1,b=1}},
    {name='super-slow-module', icon_ref='speed-module', order='ca', category = 'speed', tier=50, effect={speed={bonus=-2.5}}, tint={r=0.5,g=0.5,b=1}},
    {name='super-ineffectivity-module', icon_ref='effectivity-module', order='cb', category = 'effectivity', tier=50, effect={consumption={bonus=2.5}},
     tint={r=0.5,g=1,b=0.5}},
    {name='super-dirty-module', icon_ref='speed-module', order='cc', category='effectivity', tier=50, effect={pollution={bonus=2.5}}, tint={r=0.5,g=1,b=1}}
}

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

-- EDITOR CONTROLLER
local editor_controller = data.raw['editor-controller'].default
for n,t in pairs(settings.startup) do
    if n:match('ee%-controller') then
        editor_controller[n:gsub('ee%-controller%-', '')] = t.value
    end
end

data:extend{
    -- SHORTCUTS
    {
        type = 'shortcut',
        name = 'ee-toggle-map-editor',
        icon = shortcut_sprite('x32.png', 32),
        disabled_icon = shortcut_sprite('x32-white.png', 32),
        small_icon = shortcut_sprite('x24.png', 24),
        disabled_small_icon = shortcut_sprite('x24-white.png', 24),
        action = 'lua',
        associated_control_input = 'ee-toggle-map-editor',
        toggleable = true
    },
    -- CUSTOM INPUTS
    {
        type = 'custom-input',
        name = 'ee-toggle-map-editor',
        key_sequence = 'CONTROL + SHIFT + E',
        action = 'lua'
    },
    {
        type = 'custom-input',
        name = 'ee-mouse-leftclick',
        key_sequence = '',
        linked_game_control = 'open-gui'
    }
}

-- the rest...
require('prototypes/entity')
require('prototypes/equipment')
require('prototypes/item-group')
require('prototypes/item')
require('prototypes/module')
require('prototypes/recipe')
require('prototypes/style')