local Entity = require 'game/entity'

local function init(s)
  
end

local function spawn(s, ent)
  ent.collision = 'slide'
end

local function think(s, ent, dt)
  
end

local function draw(s, ent)
  local x,y,w,h = s.bump:getRect(ent)
  love.graphics.setColor(248,248,0,255)
  love.graphics.rectangle("fill", ent.x, ent.y, ent.w, ent.h)
  love.graphics.setColor(0,255,0,255)
  love.graphics.rectangle("line",x,y,w,h)
  love.graphics.setColor(255,255,255,255)
end

return { init = init, spawn = spawn, think = think, draw = draw }