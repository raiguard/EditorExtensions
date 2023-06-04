local handler = require("__core__/lualib/event_handler")

handler.add_libraries({
  require("__flib__/gui-lite"),

  require("__EditorExtensions__/scripts/migrations"),

  require("__EditorExtensions__/scripts/aggregate-chest"),
  require("__EditorExtensions__/scripts/cheat-mode"),
  require("__EditorExtensions__/scripts/debug-world"),
  require("__EditorExtensions__/scripts/editor"),
  require("__EditorExtensions__/scripts/infinity-accumulator"),
  require("__EditorExtensions__/scripts/infinity-loader"),
  require("__EditorExtensions__/scripts/infinity-pipe"),
  require("__EditorExtensions__/scripts/infinity-wagon"),
  require("__EditorExtensions__/scripts/inventory-filters"),
  require("__EditorExtensions__/scripts/inventory-sync"),
  require("__EditorExtensions__/scripts/linked-belt"),
  require("__EditorExtensions__/scripts/super-inserter"),
  require("__EditorExtensions__/scripts/super-pump"),
  require("__EditorExtensions__/scripts/testing-lab"),

  require("__EditorExtensions__/scripts/update-notification"),
})
