local ffi = require('ffi')

local Entity = require 'game/entity'
local Tiny = require 'game/tiny'

ffi.cdef [[
  typedef struct {
    uint16_t number;
    bool in_use;
    uint8_t class;
    float x, y, dx, dy;
    int w, h, drawx, drawy;
    etype_t type;
    bool can_take_damage;
    uint16_t health;
    collisiontype_t collision[ET_MAX];
    bool on_ground;
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
  ent.on_ground = false
  ent.dead_time = 0
  
  ent.y = ent.y + 1
  ent.h = ent.h - 1
  ent.type = ffi.C.ET_ENEMY
  ent.collision[ffi.C.ET_ENEMY] = ffi.C.CT_TOUCH
  ent.collision[ffi.C.ET_WORLD] = ffi.C.CT_SLIDE
  ent.can_take_damage = true
  
  ent.dx = -20
end

e.think = function(s, ent, dt)  
  if ent.dead_time > 0 then
    if s.time > ent.dead_time then
      Tiny.removeEntity(s.world, ent)
    end
    return
  end
  
  ent.on_ground = ent.dy >= 0 and Entity.isTouchingSolid(s, ent, 'down')
  
  ent.dy = not ent.on_ground and 150 or 0
end

e.postcollide = function(s, ent, xCollided, yCollided, xCols, yCols)
  if xCollided then
    ent.dx = ent.dx * -1
  end
end

e.draw = function(s, ent)
  local i = ent.dead_time == 0 and (math.floor(s.time * 8) % 2) + 1 or 3
  love.graphics.draw(s.media.goomba, s.media.goomba_frames[i], ent.x, ent.y, 0, 1, 1)
end

e.collide = function(s, ent, col)
  if col.item.type ~= ffi.C.ET_PLAYER or ent.dead_time > 0 then
    return
  end
  
  Entity.hurt(s, col.item, 1, ent)
end

e.take_damage = function(s, ent, dmg)  
  s.bump:remove(ent)
  ent.dead_time = s.time + 1
  --Tiny.addEntity(s.world, {event = 'sound', name = 'goomba_squish'})  
end

return e