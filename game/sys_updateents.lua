-- FIXME: hud should filter on entities so we can eventually do boss fights huds and such
local class = require "game/30log"
local tiny = require "game/tiny"

local Entity = require "game/entity"

local UpdateEnts = tiny.system(class "UpdateEnts")

function UpdateEnts:init(gs)
  
end

function UpdateEnts:update(dt)
  self:think(dt)
end

function UpdateEnts:think(dt)
  local gs = self.world.gs
  for k,v in pairs(gs.removedEnts) do gs.removedEnts[k]=nil end
  
  gs.dt = dt
  gs.time = gs.time + dt
  
  local ent = nil
  for i, ent in Entity.iterActive(gs.edata) do
    if gs.ent_handlers[ent.classname].think ~= nil then
      gs.ent_handlers[ent.classname].think(gs, ent, dt)
    end
  end
end

return UpdateEnts