-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EDITOR EXTENSIONS PROTOTYPES

-- UTILITIES
infinity_tint = {r=1, g=0.5, b=1, a=1}
combinator_tint = {r=0.8, g=0.5, b=1, a=1}

local function is_sprite_def(array)
  return array.width and array.height and (array.filename or array.stripes or array.filenames)
end
function recursive_tint(array, tint)
  tint = tint or infinity_tint
  for _,v in pairs (array) do
    if type(v) == "table" then
      if is_sprite_def(v) or v.icon then
        v.tint = tint
      end
      v = recursive_tint(v, tint)
    end
  end
  return array
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
require('prototypes/style')

-- DEBUGGING TOOL
if mods['debugadapter'] then
  data:extend{
    {
    type = 'custom-input',
    name = 'DEBUG-INSPECT-GLOBAL',
    key_sequence = 'CONTROL + SHIFT + ENTER'
    }
  }
end