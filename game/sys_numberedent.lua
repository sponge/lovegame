-- FIXME: hud should filter on entities so we can eventually do boss fights huds and such
local class = require "game/30log"
local Tiny = require "game/tiny"
local Gamestate = require "gamestate"

local EntNumSys = Tiny.processingSystem(class "EntNumSys")

EntNumSys.filter = Tiny.requireAll('number')

function EntNumSys:init(gs)
  gs.entities = {}
end

function EntNumSys:onAdd(ent)
  self.world.gs.entities[ent.number] = ent
end

function EntNumSys:onRemove(ent)
  -- FIXME: this crashes other stuff that depends on gs.entities later (bumpfilter)
  self.world.gs.entities[ent.number] = nil
end

return EntNumSys