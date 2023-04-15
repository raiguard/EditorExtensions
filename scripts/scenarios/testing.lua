-- This file exists only to prevent a crash with pre-1.13.7 testing scenarios.

script.on_configuration_changed(function()
  game.reload_script()
end)

return {}
