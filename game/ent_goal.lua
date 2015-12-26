local Entity = require 'game/entity'

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
  ent.collision = "cross"
  ent.goal_time = 0
  ent.y = ent.y + ent.h + 4 -- FIXME: why???
  
  s.bump:add(ent, ent.x, ent.y, ent.w, ent.h)
end

e.think = function(s, ent, dt)
  if s.s.goal_time == nil then
    return
  end
  
  if s.time >= s.s.goal_time and s.time - s.dt < s.s.goal_time then
    s.event_cb(s, {type = 'win'})
  end
end

e.draw = function(s, ent)
  love.graphics.draw(s.media.goal, ent.x, ent.y)
end

e.collide = function(s, ent, col) 
  if col.item.classname ~= 'player' then
    return
  end
  
  if s.s.goal_time ~= nil then
    return
  end
  
  s.s.goal_time = s.time + 10
  s.event_cb(s, {type = 'sound', name = 'goal'})
end

e.take_damage = function(s, ent, dmg)

end

return e