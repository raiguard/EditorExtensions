if (__DebugAdapter or __Profiler) then
  (__DebugAdapter or __Profiler).levelPath("EditorExtensions", "scenarios/testing/")
end

local event = require("__flib__.event")

local radius = 200
local function setup_force(force)
  force.chart("nauvis", {{-radius, -radius}, {radius, radius}})
  force.research_all_technologies()
end

event.on_init(function()
  if remote.interfaces["kr-crash-site"] then
    remote.call("kr-crash-site", "crash_site_enabled", false)
  end

  for _, force in pairs(game.forces) do
    setup_force(force)
  end
end)

event.on_force_created(function(e)
  setup_force(e.force)
end)

remote.add_interface("EditorExtensions_TestingScenario", {})