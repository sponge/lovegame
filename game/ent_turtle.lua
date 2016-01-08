local Entity = require 'game/entity'

local e = {}

e.init = function(s)
  if love.graphics then
    s.media.turtle = love.graphics.newImage("base/turtle.png")
    s.media.turtle:setFilter("nearest", "nearest")

    s.media.turtle_frames = {}
    local f = s.media.turtle_frames
    local w, h = s.media.turtle:getDimensions()
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
  ent.type = 'enemy'
  ent.collision = {
    player = 'cross',
    enemy = 'touch',
    world = 'slide',
  }
  ent.can_take_damage = true
  ent.active = true
  ent.in_shell = false
  ent.dead_time = nil
  s.bump:add(ent, ent.x, ent.y, ent.w, ent.h)
  ent.dx = -20
end

e.think = function(s, ent, dt)
  local xCollided, yCollided = Entity.move(s, ent)
  
  -- walls always stop momentum
  if xCollided then
    ent.dx = ent.dx * -1
  end
end

e.draw = function(s, ent)
  local i = (math.floor(s.time * 8) % 2) + 1
  love.graphics.draw(s.media.turtle, s.media.turtle_frames[i], ent.x, ent.y, 0, 1, 1)
end

e.collide = function(s, ent, col)
  if col.item.classname ~= 'player' then
    ent.dx = ent.dx * -1
    return
  end
  
  --s.event_cb(s, {type = 'sound', name = 'turtle'})
  
  s.bump:remove(ent)
  s.s.entities[ent.number] = nil
end

return e