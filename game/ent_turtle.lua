local ffi = require('ffi')

local Entity = require 'game/entity'

ffi.cdef [[
  typedef struct {
    bool on_ground;
    bool active;
    bool in_shell;
    float dead_time;
  } ent_turtle_t;
]]

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
  ed.on_ground = false
  ed.active = true
  ed.in_shell = false
  ed.dead_time = nil
  
  ent.y = ent.y + 1
  ent.h = ent.h - 1
  ent.type = ffi.C.ET_ENEMY
  ent.collision[ffi.C.ET_ENEMY] = ffi.C.CT_TOUCH
  ent.collision[ffi.C.ET_WORLD] = ffi.C.CT_SLIDE
  ent.can_take_damage = true
  
  ent.dx = -20
end

e.think = function(s, ent, dt)

end

e.postcollide = function(s, ent, xCollided, yCollided, xCols, yCols)
  if xCollided then
    ent.dx = ent.dx * -1
  end
end

e.draw = function(s, ent)
  local i = (math.floor(s.time * 8) % 2) + 1
  love.graphics.draw(s.media.turtle, s.media.turtle_frames[i], ent.x, ent.y, 0, 1, 1)
end

e.collide = function(s, ent, col)
  local GameFSM = require 'game/gamefsm'
  
  if col.item.classname ~= 'player' then
    ent.dx = ent.dx * -1
    return
  end
  
  --Tiny.addEntity(s.world, {event = 'sound', name = 'turtle'})
  
  GameFSM.removeEntity(s, ent.number)
end

return e