local util = table.deepcopy(require("__core__.lualib.util"))

-- tints
util.infinity_tint = {r=1, g=0.5, b=1, a=1}
util.equipment_background_color = {r=0.5, g=0.25, b=0.5, a=1}

-- recursive tinting - tint all sprite definitions in the given table
local function is_sprite_def(array)
  return array.width and array.height and (array.filename or array.stripes or array.filenames)
end
function util.recursive_tint(array, tint)
  tint = tint or util.infinity_tint
  for _, v in pairs(array) do
    if type(v) == "table" then
      if is_sprite_def(v) or v.icon then
        v.tint = tint
      end
      v = util.recursive_tint(v, tint)
    end
  end
  return array
end

-- consolidate icon information into a table to use in "icons"
function util.extract_icon_info(obj)
  return {icon=obj.icon, icon_size=obj.icon_size, icon_mipmaps=obj.icon_mipmaps}
end

-- generate the localised description of a chest
function util.chest_description(suffix, is_aggregate)
  if is_aggregate then
    return {"", {"entity-description.ee-aggregate-chest"}, suffix ~= "" and {"", "\n", {"entity-description.logistic-chest"..suffix}} or "",
      "\n[color=255,57,48]", {"entity-description.ee-aggregate-chest-warning"}, "[/color]"}
  else
    return {"", {"entity-description.ee-infinity-chest"}, suffix ~= "" and {"", "\n", {"entity-description.logistic-chest"..suffix}} or ""}
  end
end

-- data tables
util.infinity_chest_data = {
  {t={255,255,225}, o="aa"},
  {lm="active-provider", s=0, t={218,115,255}, o="ab"},
  {lm="passive-provider", s=0, t={255,141,114}, o="ac"},
  {lm="storage", s=1, t={255,220,113}, o="ad"},
  {lm="buffer", s=30, t={114,255,135}, o="ae"},
  {lm="requester", s=30, t={114,236,255}, o="af"}
}
util.aggregate_chest_data = {
  {t={255,255,225}, o="ba"},
  {lm="passive-provider", t={255,141,114}, o="bb"}
}
util.module_data = {
  {name="ee-super-speed-module", icon_ref="speed-module-3", order="ba", category = "speed", tier=50, effect={speed={bonus=2.5}}, tint={r=0.5,g=0.5,b=1}},
  {name="ee-super-effectivity-module", icon_ref="effectivity-module-3", order="bb", category="effectivity", tier=50, effect={consumption={bonus=-2.5}},
    tint={r=0.5,g=1,b=0.5}},
  {name="ee-super-productivity-module", icon_ref="productivity-module-3", order="bc", category="productivity", tier=50, effect={productivity={bonus=2.5}},
    tint={r=1,g=0.5,b=0.5}},
  {name="ee-super-clean-module", icon_ref="speed-module-3", order="bd", category="effectivity", tier=50, effect={pollution={bonus=-2.5}}, tint={r=0.5,g=1,b=1}},
  {name="ee-super-slow-module", icon_ref="speed-module", order="ca", category = "speed", tier=50, effect={speed={bonus=-2.5}}, tint={r=0.5,g=0.5,b=1}},
  {name="ee-super-ineffectivity-module", icon_ref="effectivity-module", order="cb", category = "effectivity", tier=50, effect={consumption={bonus=2.5}},
    tint={r=0.5,g=1,b=0.5}},
  {name="ee-super-dirty-module", icon_ref="speed-module", order="cc", category="effectivity", tier=50, effect={pollution={bonus=2.5}}, tint={r=0.5,g=1,b=1}}
}

-- definitions
util.empty_circuit_wire_connection_points = {
  {wire={},shadow={}},
  {wire={},shadow={}},
  {wire={},shadow={}},
  {wire={},shadow={}}
}
util.empty_sheet = {
  filename = "__core__/graphics/empty.png",
  priority = "very-low",
  width = 1,
  height = 1,
  frame_count = 1
}
util.infinity_chest_icon = {
  icon = "__EditorExtensions__/graphics/item/infinity-chest.png",
  icon_size = 64,
  icon_mipmaps = 4
}
util.aggregate_chest_icon = {
  icon = "__EditorExtensions__/graphics/item/aggregate-chest.png",
  icon_size = 64,
  icon_mipmaps = 4
}

return util