-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MODULES

local util = require('lualib/util')

local function get_module_icon(icon_ref, tint)
  local obj = data.raw['module'][icon_ref]
  return {{icon=obj.icon, icon_size=obj.icon_size, tint=tint}}
end

local module_template = {
  type = 'module',
  subgroup = 'ee-modules',
  stack_size = 50
}

local module_data = {
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

for _,t in pairs(module_data) do
  local module = table.merge{t, module_template}
  module.icons = get_module_icon(module.icon_ref, module.tint)
  module.icon_ref = nil
  data:extend{module}
end