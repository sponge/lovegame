local Entity = require 'game/entity'
local Easing = require 'game/easing'

local e = {}

e.init = function(s)
  if not love.graphics then return end
  
  s.media.coin_block = love.graphics.newImage("base/coin_block.png")
  s.media.coin_block:setFilter("nearest", "nearest")

  s.media.coin_block_frames = {}
  local f = s.media.coin_block_frames
  local w, h = s.media.coin_block:getDimensions()
  for i=0, w/16 do
    f[#f+1] = love.graphics.newQuad(16*i,  0, 16, h, w, h)
  end  
end

e.spawn = function(s, ent)
  ent.collision = 'slide'
  ent.item = 'coin'
  ent.active = true
  ent.hit_time = nil
  s.bump:add(ent, ent.x, ent.y, ent.w, ent.h)
end

e.think = function(s, ent, dt)
  
end

local DURATION = 0.08

e.draw = function(s, ent)
  local i = ent.active and (math.floor(s.time * 8) % 4) + 1 or 5
  local y = (ent.hit_time == nil or s.time > ent.hit_time + DURATION) and ent.y or Easing.linear(s.time - ent.hit_time, ent.y, -4, DURATION)
  
  love.graphics.draw(s.media.coin_block, s.media.coin_block_frames[i], ent.x, y, 0, 1, 1)
end

e.collide = function(s, ent, col)
  if col.item.classname ~= 'player' or not ent.active then
    return
  end
  
  if not (col.normal.x == 0 and col.normal.y == 1) then
    return
  end
  
  s.event_cb(s, {type = 'sound', name = 'coin'})
  
  col.item.coins = col.item.coins + 1
  
  ent.active = false
  ent.hit_time = s.time
end

return e