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

for _,t in pairs(module_data) do
  local module = table.merge{t, module_template}
  module.icons = get_module_icon(module.icon_ref, module.tint)
  module.icon_ref = nil
  data:extend{module}
end