local ffi = require 'ffi'
local Entity = require 'game/entity'
local Easing = require 'game/easing'

ffi.cdef [[
  typedef struct {
    bool active;
    float hit_time;
  } ent_coin_block_t;
]]

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
  local ed = ffi.new("ent_coin_block_t")
  s.s.edata[ent.number] = ed
  
  ent.type = 'world'
  ed.active = true
  ed.hit_time = 0
  s.bump:add(ent.number, ent.x, ent.y, ent.w, ent.h)
end

e.think = function(s, ent, dt)
  
end

local DURATION = 0.12

e.draw = function(s, ent)
  local ed = s.s.edata[ent.number]
  
  local i = ed.active and (math.floor(s.time * 8) % 4) + 1 or 5
  local y = (ed.hit_time == 0 or s.time > ed.hit_time + DURATION) and ent.y or Easing.linear(s.time - ed.hit_time, ent.y-4, 4, DURATION)
  
  love.graphics.draw(s.media.coin_block, s.media.coin_block_frames[i], ent.x, y, 0, 1, 1)
end

e.collide = function(s, ent, col)
  local ed = s.s.edata[ent.number]
  
  if col.item.classname ~= 'player' or not ed.active then
    return
  end
  
  if not (col.normal.x == 0 and col.normal.y == 1) then
    return
  end
  
  s.event_cb(s, {type = 'sound', name = 'coin'})
  
  s.s.edata[col.item.number].coins = s.s.edata[col.item.number].coins + 1
  
  ed.active = false
  ed.hit_time = s.time
end

return e