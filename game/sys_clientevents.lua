-- FIXME: hud should filter on entities so we can eventually do boss fights huds and such
local class = require "game/30log"
local Tiny = require "game/tiny"

local ClientEvents = Tiny.processingSystem(class "ClientEvents")
ClientEvents.draw = true
ClientEvents.nocache = true

ClientEvents.filter = Tiny.requireAll('event')

function ClientEvents:init(gs)
end

function ClientEvents:process(ev, dt)
  local gs = self.world.gs
  
  if ev.event == 'sound' then
    love.audio.stop(gs.media['snd_'.. ev.name])
    love.audio.play(gs.media['snd_'.. ev.name])
  elseif ev.event == 'stopsound' then
    love.audio.stop(gs.media['snd_'.. ev.name])
  elseif ev.event == 'death' then
    GameState.switch(scene, gs.currmap)
  elseif ev.event == 'win' then
    GameState.switch(st_win)
    return
  end
  
  Tiny.removeEntity(gs.world, ev)
end

return ClientEvents