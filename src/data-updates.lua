-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EDITOR EXTENSIONS PROTOTYPES - UPDATES

-- INFINITY LOADER
local loader_base = table.deepcopy(data.raw['underground-belt']['underground-belt'])
loader_base.icons = {apply_infinity_tint{icon='__EditorExtensions__/graphics/item/infinity-loader.png', icon_size=32}}
for n,t in pairs(loader_base.structure) do
  apply_infinity_tint(t.sheet)
  apply_infinity_tint(t.sheet.hr_version)
  if n ~= 'back_patch' and n ~= 'front_patch' then
    t.sheet.filename = '__EditorExtensions__/graphics/entity/infinity-loader.png'
    t.sheet.hr_version.filename = '__EditorExtensions__/graphics/entity/hr-infinity-loader.png'
  end
end

local belt_patterns = {
  -- factorioextended plus transport: https://mods.factorio.com/mod/FactorioExtended-Plus-Transport
  ['%-?transport%-belt%-to%-ground'] = '',
  -- vanilla and 99% of mods
  ['%-?underground%-belt'] = ''
}

local function create_loader(base_underground)
  local entity = table.deepcopy(data.raw['underground-belt'][base_underground])
  -- adjust pictures and icon
  entity.structure = loader_base.structure
  entity.icons = loader_base.icons
  -- get name
  local suffix = entity.name
  for pattern, replacement in pairs(belt_patterns) do
    suffix = suffix:gsub(pattern, replacement)
  end
  entity.name = 'infinity-loader-loader' .. (suffix ~= '' and '-'..suffix or '')
  -- other data
  entity.type = 'loader'
  entity.next_upgrade = nil
  entity.max_distance = 0
  entity.order = 'a'
  entity.selectable_in_game = false
  entity.filter_count = 0
  entity.belt_distance = 0
  entity.belt_length = 0.6
  entity.container_distance = 0
  data:extend{entity}
end

for n,_ in pairs(table.deepcopy(data.raw['underground-belt'])) do
  create_loader(n)
end