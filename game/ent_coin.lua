local Entity = require 'game/entity'

local e = {}

e.init = function(s)
  if love.graphics then
    s.media.coin = love.graphics.newImage("base/coin.png")
    s.media.coin:setFilter("nearest", "nearest")

    s.media.coin_frames = {}
    local f = s.media.coin_frames
    local w, h = s.media.coin:getDimensions()
    for i=0, w/16 do
      f[#f+1] = love.graphics.newQuad(16*i,  0, 16, h, w, h)
    end
  end
  
  if love.audio then
    s.media.snd_coin = love.audio.newSource("base/coin.wav", "static")
  end
end

e.spawn = function(s, ent)
  ent.type = 'playertrigger'
  ent.w = 12
  ent.x = ent.x + 2
  s.bump:add(ent.number, ent.x, ent.y, ent.w, ent.h)
end

e.think = function(s, ent, dt)
  
end

e.draw = function(s, ent)
  local i = (math.floor(s.time * 8) % 8) + 1
  love.graphics.draw(s.media.coin, s.media.coin_frames[i], ent.x - 2, ent.y, 0, 1, 1)
end

e.collide = function(s, ent, col)
  local GameFSM = require 'game/gamefsm'
  
  if col.item.classname ~= 'player' then
    return
  end
  
  s.event_cb(s, {type = 'sound', name = 'coin'})
  
  s.s.edata[col.item.number].coins = s.s.edata[col.item.number].coins + 1
  
  GameFSM.removeEntity(s, ent.number)
end

return e