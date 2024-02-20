local handler = require("__core__.lualib.event_handler")

handler.add_libraries({
  require("__flib__.gui-lite"),

  require("scripts.migrations"),

  require("scripts.aggregate-chest"),
  require("scripts.cheat-mode"),
  require("scripts.debug-world"),
  require("scripts.editor"),
  require("scripts.infinity-accumulator"),
  require("scripts.infinity-loader"),
  require("scripts.infinity-pipe"),
  require("scripts.infinity-wagon"),
  require("scripts.inventory-filters"),
  require("scripts.inventory-sync"),
  require("scripts.linked-belt"),
  require("scripts.super-pump"),
  require("scripts.testing-lab"),

  require("scripts.update-notification"),
})
