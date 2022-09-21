local constants = require("prototypes.constants")
local util = {}

local core_util = require("__core__.lualib.util")

util.by_pixel = core_util.by_pixel

-- recursive tinting - tint all sprite definitions in the given table
local function is_sprite_def(array)
  return array.width and array.height and (array.filename or array.stripes or array.filenames)
end
function util.recursive_tint(array, tint)
  if tint ~= false then
    tint = tint or constants.infinity_tint
  end
  for _, v in pairs(array) do
    if type(v) == "table" then
      if is_sprite_def(v) or v.icon then
        if tint == false then
          v.tint = nil
        else
          v.tint = tint
        end
      end
      v = util.recursive_tint(v, tint)
    end
  end
  return array
end

-- consolidate icon information into a table to use in "icons"
function util.extract_icon_info(obj, skip_cleanup)
  local icons = obj.icons or { { icon = obj.icon, icon_size = obj.icon_size, icon_mipmaps = obj.icon_mipmaps } }
  icons[1].icon_size = icons[1].icon_size or obj.icon_size
  if not skip_cleanup then
    obj.icon = nil
    obj.icon_size = nil
    obj.icon_mipmaps = nil
  end
  return icons
end

-- generate the localised description of a chest
function util.chest_description(suffix, is_aggregate)
  if is_aggregate then
    return {
      "",
      { "entity-description.ee-aggregate-chest" },
      suffix ~= "" and { "", "\n", { "entity-description.logistic-chest" .. suffix } } or "",
      "\n[color=255,57,48]",
      { "entity-description.ee-performance-warning" },
      "[/color]",
    }
  else
    return {
      "",
      { "entity-description.ee-infinity-chest" },
      suffix ~= "" and { "", "\n", { "entity-description.logistic-chest" .. suffix } } or "",
    }
  end
end

return util
