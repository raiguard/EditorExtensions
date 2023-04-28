local flib_migration = require("__flib__.migration")

if not mods["RecipeBook"] or flib_migration.is_newer_version(mods["RecipeBook"], "4.0.0") then
  return
end

recipe_book.set_exclude(data.raw["recipe-category"]["ee-testing-tool"], true)
