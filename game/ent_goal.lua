local ffi = require 'ffi'

local Tiny = require 'game/tiny'
local Entity = require 'game/entity'

ffi.cdef [[
  typedef struct {
    uint16_t number;
    bool in_use;
    uint8_t class;
    float x, y;
    int w, h, drawx, drawy;
    etype_t type;
  } ent_goal_t;
]]

local e = {}

e.init = function(s)
  if love.graphics then
    s.media.goal = love.graphics.newImage("base/goal.png")
    s.media.goal:setFilter("nearest", "nearest")
  end
  
  if love.audio then
    s.media.snd_goal = love.audio.newSource("base/goal.mp3", "stream")
  end
end

e.spawn = function(s, ent)
  ent.type = ffi.C.ET_PLAYER_TRIGGER
  ent.y = ent.y + ent.h + 4 -- FIXME: why???
end

e.think = function(s, ent, dt)
  if s.ws.goal_time == 0 then
    return
  end
  
  if s.time >= s.ws.goal_time and s.time - s.dt < s.ws.goal_time then
    Tiny.addEntity(s.world, {event = 'win'})
  end
end

e.draw = function(s, ent)
  love.graphics.draw(s.media.goal, ent.x, ent.y)
end

e.collide = function(s, ent, col)
  if col.item.classname ~= 'player' then
    return
  end
  
  if s.ws.goal_time > 0 then
    return
  end
  
  s.ws.goal_time = s.time + 10
  col.item.can_take_damage = false
  Tiny.addEntity(s.world, {event = 'sound', name = 'goal'})
end

e.take_damage = function(s, ent, dmg)

end

return e