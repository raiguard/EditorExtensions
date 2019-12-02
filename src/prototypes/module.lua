-- ----------------------------------------------------------------------------------------------------
-- MODULES

local function get_module_icon(icon_ref, tint)
    local obj = data.raw['module'][icon_ref]
    return {{icon=obj.icon, icon_size=obj.icon_size, tint=tint}}
end

local module_template = {
    type = 'module',
    subgroup = 'ee-modules',
    stack_size = 50
}

for _,v in pairs(module_data) do
    for tk,tv in pairs(module_template) do
        v[tk] = tv
    end
    v.icons = get_module_icon(v.icon_ref, v.tint)
    v.icon_ref = nil
    data:extend{v}
end