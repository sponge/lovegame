local Entity = require 'game/entity'

local e = {}

e.init = function(s)
  if love.graphics then
    s.media.goomba = love.graphics.newImage("base/goomba.png")
    s.media.goomba:setFilter("nearest", "nearest")

    s.media.goomba_frames = {}
    local f = s.media.goomba_frames
    local w, h = s.media.goomba:getDimensions()
    for i=0, w/16 do
      f[#f+1] = love.graphics.newQuad(16*i,  0, 16, h, w, h)
    end
  end
  
  if love.audio then
  
  end
end

e.spawn = function(s, ent)
  ent.on_ground = false
  ent.y = ent.y + 1
  ent.h = ent.h - 1
  ent.collision = 'touch'
  s.bump:add(ent, ent.x, ent.y, ent.w, ent.h)
  ent.dx = -20
end

e.think = function(s, ent, dt)
  ent.on_ground = ent.dy >= 0 and Entity.isTouchingSolid(s, ent, 'down')
  
  ent.dy = not ent.on_ground and 150 or 0
  
  if ent.dx > 0 and Entity.isTouchingSolid(s, ent, 'right') then
    ent.dx = ent.dx * -1
  elseif ent.dx < 0 and Entity.isTouchingSolid(s, ent, 'left') then
    ent.dx = ent.dx * -1
  end

  local xCollided, yCollided = Entity.move(s, ent)
end

e.draw = function(s, ent)
  local i = (math.floor(s.time * 8) % 2) + 1
  love.graphics.draw(s.media.goomba, s.media.goomba_frames[i], ent.x, ent.y, 0, 1, 1)
end

e.collide = function(s, ent, col)
  ent.dx = ent.dx * -1
  
  if col.item.classname ~= 'player' then
    return
  end
  
  if col.normal.x == 0 and col.normal.y == -1 then
    s.bump:remove(ent)
    s.s.entities[ent.number] = nil
    --s.event_cb(s, {type = 'sound', name = 'goomba_squish'})
  end
  
end

return e