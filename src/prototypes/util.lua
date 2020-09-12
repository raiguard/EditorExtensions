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
  return obj.icons or {{icon=obj.icon, icon_size=obj.icon_size, icon_mipmaps=obj.icon_mipmaps}}
end

-- generate the localised description of a chest
function util.chest_description(suffix, is_aggregate)
  if is_aggregate then
    return {
      "",
      {"entity-description.ee-aggregate-chest"},
      suffix ~= "" and {"", "\n", {"entity-description.logistic-chest"..suffix}} or "",
      "\n[color=255,57,48]", {"entity-description.ee-performance-warning"}, "[/color]"
    }
  else
    return {
      "",
      {"entity-description.ee-infinity-chest"},
      suffix ~= "" and {"", "\n", {"entity-description.logistic-chest"..suffix}} or ""
    }
  end
end

return util