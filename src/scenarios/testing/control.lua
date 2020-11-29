if __DebugAdapter or __Profiler then
  (__DebugAdapter or __Profiler).levelPath("EditorExtensions", "scenarios/testing/")
end

if not script.active_mods["EditorExtensions"] then
  error("Editor Extensions must be active for this scenario to function.")
end

local callbacks = require("__EditorExtensions__.scripts.scenarios.testing")

--[[
  MOD DEVELOPERS:
  To create a custom mod testing scenario, navigate to map editor -> new scenario and choose this scenario as your
  template. Build whatever testing setups you need, then save it to your user scenarios. You can then choose it from
  the new game menu!

  If you need custom scripting (for setting up player defaults, etc.), you can add your own code below. The EE scenario
  controls the following event handlers:
    on_init
    on_configuration_changed
    on_force_created
    on_player_created

  If you need to run code in these events, add callbacks for them to the provided `callbacks` table:

  callbacks.on_init = function() log("init!") end

  All other event handlers may be registered however you like.

  The EE scenario does not use `global`, so feel free to use it if you need it.
]]

-- so the language server doesn't yell at me
callbacks.on_init = nil