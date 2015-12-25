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
  ent.can_take_damage = true
  ent.active = true
  ent.dead_time = nil
  s.bump:add(ent, ent.x, ent.y, ent.w, ent.h)
  ent.dx = -20
end

e.think = function(s, ent, dt)  
  if not ent.active then
    if s.time > ent.dead_time then
      s.s.entities[ent.number] = nil
    end
    return
  end
  
  ent.on_ground = ent.dy >= 0 and Entity.isTouchingSolid(s, ent, 'down')
  
  ent.dy = not ent.on_ground and 150 or 0

  local touching, cols = Entity.isTouchingSolid(s, ent, ent.dx > 0 and 'right' or 'left')
  if touching then
    ent.dx = ent.dx * -1
  end
  if cols ~= nil then
    for i = 1, #cols do  
      if cols[i].other.classname == 'player' and s.ent_handlers[cols[i].other.classname].take_damage then
        s.ent_handlers[cols[i].other.classname].take_damage(s, cols[i].other, 1)
      end
    end
  end

  local xCollided, yCollided = Entity.move(s, ent)
end

e.draw = function(s, ent)
  local i = ent.active and (math.floor(s.time * 8) % 2) + 1 or 3
  love.graphics.draw(s.media.goomba, s.media.goomba_frames[i], ent.x, ent.y, 0, 1, 1)
end

e.collide = function(s, ent, col)
  ent.dx = ent.dx * -1
  
  if col.item.classname ~= 'player' then
    return
  end
  
  if col.normal.x == 0 and col.normal.y == -1 then
    s.ent_handlers[ent.classname].take_damage(s, ent, 1)
  elseif col.item.can_take_damage then
    s.ent_handlers[col.item.classname].take_damage(s, col.item, 1)
  end
  
end

e.take_damage = function(s, ent, dmg)
  s.bump:remove(ent)
  ent.active = false
  ent.dead_time = s.time + 1
  --s.event_cb(s, {type = 'sound', name = 'goomba_squish'})  
end

return e