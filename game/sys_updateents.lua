-- FIXME: hud should filter on entities so we can eventually do boss fights huds and such
local class = require "game/30log"
local tiny = require "game/tiny"

local Entity = require "game/entity"

local UpdateEnts = tiny.processingSystem(class "UpdateEnts")
UpdateEnts.think = true

function UpdateEnts:init(gs)

end

function UpdateEnts:filter(ent)
  local gs = self.world.gs
  return ent.classname ~= nil and gs.ent_handlers[ent.classname].think ~= nil
end

function UpdateEnts:process(ent, dt)
  local gs = self.world.gs
  gs.ent_handlers[ent.classname].think(gs, ent, dt)
end

return UpdateEnts