local handler = require("__core__/lualib/event_handler")

handler.add_lib(require("__flib__/gui-lite"))

handler.add_lib(require("__EditorExtensions__/scripts/aggregate-chest"))
handler.add_lib(require("__EditorExtensions__/scripts/cheat-mode"))
handler.add_lib(require("__EditorExtensions__/scripts/debug-world"))
handler.add_lib(require("__EditorExtensions__/scripts/editor"))
handler.add_lib(require("__EditorExtensions__/scripts/infinity-accumulator"))
handler.add_lib(require("__EditorExtensions__/scripts/infinity-loader"))
handler.add_lib(require("__EditorExtensions__/scripts/infinity-pipe"))
handler.add_lib(require("__EditorExtensions__/scripts/inventory-filters"))
handler.add_lib(require("__EditorExtensions__/scripts/inventory-sync"))
handler.add_lib(require("__EditorExtensions__/scripts/super-inserter"))

-- remote.add_interface("EditorExtensions", {
--   --- Get the force that the player is actually on, ignoring the testing lab force.
--   --- @param player LuaPlayer
--   --- @return ForceIdentification
--   get_player_proper_force = function(player)
--     if not player or not player.valid then
--       error("Did not pass a valid LuaPlayer")
--     end
--     if not global.players then
--       return player.force
--     end
--     local player_table = global.players[player.index]
--     if player_table and player_table.normal_state and player.controller_type == defines.controllers.editor then
--       return player_table.normal_state.force
--     else
--       return player.force
--     end
--   end,
-- })
