local Entity = require 'game/entity'

local e = {}

e.init = function(s)
  if not love.graphics then return end
  
  s.media.coin = love.graphics.newImage("base/coin.png")
  s.media.coin:setFilter("nearest", "nearest")

  s.media.coin_frames = {}
  local f = s.media.coin_frames
  local w, h = s.media.coin:getDimensions()
  for i=0, 8 do
    f[#f+1] = love.graphics.newQuad(16*i,  0, 16, h, w, h)
  end
end

e.spawn = function(s, ent)
  ent.collision = 'cross'
  ent.w = 12
  ent.x = ent.x + 2
  s.bump:add(ent, ent.x, ent.y, ent.w, ent.h)
end

e.think = function(s, ent, dt)
  
end

e.draw = function(s, ent)
  local i = (math.floor(s.time * 8) % 8) + 1
  love.graphics.draw(s.media.coin, s.media.coin_frames[i], ent.x - 2, ent.y, 0, 1, 1)
end

return e