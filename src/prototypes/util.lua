-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- UTILITIES
-- Utilities used across EE's data structure

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

function extract_icon_info(obj)
  return {icon=obj.icon, icon_size=obj.icon_size, icon_mipmaps=obj.icon_mipmaps}
end