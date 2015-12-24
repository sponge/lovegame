local Entity = require 'game/entity'

local e = {}

e.init = function(s)
  if not love.graphics then return end
  
  s.media.coin_block = love.graphics.newImage("base/coin_block.png")
  s.media.coin_block:setFilter("nearest", "nearest")

  s.media.coin_block_frames = {}
  local f = s.media.coin_block_frames
  local w, h = s.media.coin_block:getDimensions()
  for i=0, 5 do
    f[#f+1] = love.graphics.newQuad(16*i,  0, 16, h, w, h)
  end  
end

e.spawn = function(s, ent)
  ent.collision = 'slide'
  ent.item = 'coin'
  ent.active = true
  s.bump:add(ent, ent.x, ent.y, ent.w, ent.h)
end

e.think = function(s, ent, dt)
  
end

e.draw = function(s, ent)
  local i = ent.active and (math.floor(s.time * 8) % 4) + 1 or 5
  love.graphics.draw(s.media.coin_block, s.media.coin_block_frames[i], ent.x, ent.y, 0, 1, 1)
end

e.collide = function(s, ent, col)
  if col.item.classname ~= 'player' or not ent.active then
    return
  end
  
  if not (col.normal.x == 0 and col.normal.y == 1) then
    return
  end
  
  s.event_cb(s, {type = 'sound', name = 'coin'})
  
  ent.active = false
end

return e