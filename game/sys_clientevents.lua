-- FIXME: hud should filter on entities so we can eventually do boss fights huds and such
local class = require "game/30log"
local tiny = require "game/tiny"

local ClientEvents = tiny.system(class "ClientEvents")

function ClientEvents:init(gs)
end

function ClientEvents:update()
  self:draw()
end

function ClientEvents:draw()
  local gs = self.world.gs
  
  for _, ev in ipairs(gs.events) do
    if ev.type == 'sound' then
      love.audio.stop(gs.media['snd_'.. ev.name])
      love.audio.play(gs.media['snd_'.. ev.name])
    elseif ev.type == 'stopsound' then
      love.audio.stop(gs.media['snd_'.. ev.name])
    elseif ev.type == 'death' then
      GameState.switch(scene, gs.currmap)
    elseif ev.type == 'win' then
      GameState.switch(st_win)
      return
    end
  end
  
  -- FIXME: should this be here? this is client only, events wont get reset but we dont run every system every frame
  gs.events = {}
end

return ClientEvents