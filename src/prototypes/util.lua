-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DATA STAGE UTILITIES

local self = table.deepcopy(require('__core__/lualib/util'))

-- tints
self.infinity_tint = {r=1, g=0.5, b=1, a=1}
self.combinator_tint = {r=0.8, g=0.5, b=1, a=1}

-- recursive tinting - tint all sprite definitions in the given table
local function is_sprite_def(array)
  return array.width and array.height and (array.filename or array.stripes or array.filenames)
end
function self.recursive_tint(array, tint)
  tint = tint or self.infinity_tint
  for _,v in pairs (array) do
    if type(v) == "table" then
      if is_sprite_def(v) or v.icon then
        v.tint = tint
      end
      v = self.recursive_tint(v, tint)
    end
  end
  return array
end

-- consolidate icon information into a table to use in 'icons'
function self.extract_icon_info(obj)
  return {icon=obj.icon, icon_size=obj.icon_size, icon_mipmaps=obj.icon_mipmaps}
end

-- data tables
self.infinity_chest_data = {
  ['active-provider'] = {s=0, t={218,115,255}, o='ab'},
  ['passive-provider'] = {s=0, t={255,141,114}, o='ac'},
  ['storage'] = {s=1, t={255,220,113}, o='ad'},
  ['buffer'] = {s=30, t={114,255,135}, o='ae'},
  ['requester'] = {s=30, t={114,236,255}, o='af'}
}
self.tesseract_chest_data = {
  [''] = {t={255,255,255}, o='ba'},
  ['passive-provider'] = {t={255,141,114}, o='bb'},
  ['storage'] = {t={255,220,113}, o='bc'}
}
self.module_data = {
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

-- definitions
-- utilities for prototype creation
self.empty_circuit_wire_connection_points = {
  {wire={},shadow={}},
  {wire={},shadow={}},
  {wire={},shadow={}},
  {wire={},shadow={}}
}
self.empty_sheet = {
  filename = '__core__/graphics/empty.png',
  priority = 'very-low',
  width = 1,
  height = 1,
  frame_count = 1
}

return self