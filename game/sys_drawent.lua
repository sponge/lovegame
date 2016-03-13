-- FIXME: this should be a processing system that reads entities from the world instead of gs.entities
local class = require "game/30log"
local tiny = require "game/tiny"
local Entity = require "game/entity"

local DrawEntities = tiny.processingSystem(class "DrawEntities")
DrawEntities.draw = true

function DrawEntities:init(gs)
end

function DrawEntities:filter(ent)
  local gs = self.world.gs
  return gs.ent_handlers[ent.classname].draw ~= nil
end

function DrawEntities:process(ent, dt)
  local gs = self.world.gs
  gs.cam:attach()

  gs.ent_handlers[ent.classname].draw(gs, ent)
  
  if ent.dbg then
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("fill", ent.x, ent.y, ent.w, ent.h)
    love.graphics.setColor(255,255,255,255)
    if type(ent.dbg) ~= 'boolean' then
      love.graphics.print(tostring(ent.dbg), ent.x, ent.y)
    end
  end

  gs.cam:detach()
end

return DrawEntities