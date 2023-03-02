local constants = require("__EditorExtensions__/prototypes/constants")
local util = {}

local core_util = require("__core__/lualib/util")

util.by_pixel = core_util.by_pixel

local function is_sprite_def(array)
  return array.icon or array.width and array.height and (array.filename or array.stripes or array.filenames)
end
--- Recursively tint all sprite definitions in the given table.
--- @generic T
--- @param array T
--- @param tint Color|boolean? Set to `false` to remove tints.
--- @return T
function util.recursive_tint(array, tint)
  if tint ~= false then
    tint = tint or constants.infinity_tint
  end
  for _, v in pairs(array) do
    if type(v) == "table" then
      if is_sprite_def(v) then
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

--- Copy and optionally tint a prototype.
--- @generic T
--- @param base T
--- @param mods table<string, any>
--- @param tint Color|boolean? Infinity tint by default, set to `false` to perform no tinting.
--- @return T
function util.copy_prototype(base, mods, tint)
  local base = table.deepcopy(base)
  for key, value in pairs(mods) do
    if key == "icons" and value == "CONVERT" then
      base.icons = { { icon = base.icon, icon_size = base.icon_size, icon_mipmaps = base.icon_mipmaps } }
      base.icon = nil
      base.icon_size = nil
      base.icon_mipmaps = nil
    elseif value == "NIL" then
      base[key] = nil
    else
      base[key] = value
    end
  end
  if tint ~= false then
    util.recursive_tint(base, tint)
  end
  return base
end

-- create spritesheet for dummy combinator
local dummy_sprite_files = {
  {
    "__base__/graphics/entity/underground-belt/underground-belt-structure-back-patch.png",
    "__base__/graphics/entity/underground-belt/hr-underground-belt-structure-back-patch.png",
  },
  {
    "__base__/graphics/entity/linked-belt/linked-belt-structure.png",
    "__base__/graphics/entity/linked-belt/hr-linked-belt-structure.png",
  },
  {

    "__base__/graphics/entity/underground-belt/underground-belt-structure-front-patch.png",
    "__base__/graphics/entity/underground-belt/hr-underground-belt-structure-front-patch.png",
  },
}
local sprite_x = { south = 96 * 0, west = 96 * 1, north = 96 * 2, east = 96 * 3 }
local dummy_sprites = {}
for k, x in pairs(sprite_x) do
  dummy_sprites[k] = {}
  dummy_sprites[k].layers = {}
  for i, t in pairs(dummy_sprite_files) do
    dummy_sprites[k].layers[i] = {
      filename = t[1],
      x = x,
      width = 96,
      height = 96,
      hr_version = {
        filename = t[2],
        x = x * 2,
        width = 192,
        height = 192,
        scale = 0.5,
      },
    }
  end
end

util.loader_dummy_sprites = dummy_sprites

return util
