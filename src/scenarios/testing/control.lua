if __DebugAdapter or __Profiler then
  (__DebugAdapter or __Profiler).levelPath("EditorExtensions", "scenarios/testing/")
end

if script.active_mods["EditorExtensions"] then
  require("__EditorExtensions__.scripts.scenarios.testing")
else
  error("Editor Extensions must be active for this scenario to function.")
end
