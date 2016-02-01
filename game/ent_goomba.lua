local ffi = require('ffi')

local Entity = require 'game/entity'

ffi.cdef [[
  typedef struct {
    bool on_ground;
    bool active;
    float dead_time;
  } ent_goomba_t;
]]

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
  local ed = ffi.new("ent_goomba_t")
  s.s.edata[ent.number] = ed
  
  ed.on_ground = false
  ed.active = true
  ed.dead_time = 0
  
  ent.y = ent.y + 1
  ent.h = ent.h - 1
  ent.type = 'enemy'
  ent.collision = {
    player = 'cross',
    enemy = 'touch',
    world = 'slide',
  }
  ent.can_take_damage = true
  
  s.bump:add(ent.number, ent.x, ent.y, ent.w, ent.h)
  ent.dx = -20
end

e.think = function(s, ent, dt)  
  local ed = s.s.edata[ent.number]
  
  if not ed.active then
    if s.time > ed.dead_time then
      s.s.entities[ent.number] = nil
    end
    return
  end
  
  ed.on_ground = ent.dy >= 0 and Entity.isTouchingSolid(s, ent, 'down')
  
  ent.dy = not ed.on_ground and 150 or 0

  local touching, cols = Entity.isTouchingSolid(s, ent, ent.dx > 0 and 'right' or 'left')
  if touching then
    ent.dx = ent.dx * -1
  end

  local xCollided, yCollided = Entity.move(s, ent)
end

e.draw = function(s, ent)
  local ed = s.s.edata[ent.number]
  
  local i = ed.active and (math.floor(s.time * 8) % 2) + 1 or 3
  love.graphics.draw(s.media.goomba, s.media.goomba_frames[i], ent.x, ent.y, 0, 1, 1)
end

e.collide = function(s, ent, col)
  local ed = s.s.edata[ent.number]
  
  if col.item.type ~= 'player' or not ed.active then
    return
  end
  
  Entity.hurt(s, col.item, 1, ent)
end

e.take_damage = function(s, ent, dmg)
  local ed = s.s.edata[ent.number]
  
  s.bump:remove(ent.number)
  ed.active = false
  ed.dead_time = s.time + 1
  --s.event_cb(s, {type = 'sound', name = 'goomba_squish'})  
end

return e