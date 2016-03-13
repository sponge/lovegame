-- FIXME: hud should filter on entities so we can eventually do boss fights huds and such
local class = require "game/30log"
local tiny = require "game/tiny"

local UpdateTime = tiny.system(class "UpdateTime")

UpdateTime.think = true

function UpdateTime:init(gs)
  
end

function UpdateTime:update(dt)
  local gs = self.world.gs
  
  for k,v in pairs(gs.removedEnts) do gs.removedEnts[k]=nil end
  gs.dt = dt
  gs.time = gs.time + dt
end

return UpdateTime