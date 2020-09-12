local on_tick = {}

local event = require("__flib__.event")

local infinity_wagon = require("scripts.entity.infinity-wagon")

function on_tick.handler()
  if next(global.wagons) then
    infinity_wagon.flip_inventories()
  else
    event.on_tick(nil)
  end
end

function on_tick.register()
  if next(global.wagons) then
    event.on_tick(on_tick.handler)
  end
end

return on_tick