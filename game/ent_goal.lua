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
  ent.type = "playertrigger"
  ent.y = ent.y + ent.h + 4 -- FIXME: why???
  
  s.bump:add(ent.number, ent.x, ent.y, ent.w, ent.h)
end

e.think = function(s, ent, dt)
  if s.goal_time == nil then
    return
  end
  
  if s.time >= s.goal_time and s.time - s.dt < s.goal_time then
    local GameFSM = require 'game/gamefsm'
    GameFSM.addEvent(s, {type = 'win'})
  end
end

e.draw = function(s, ent)
  love.graphics.draw(s.media.goal, ent.x, ent.y)
end

e.collide = function(s, ent, col)
  local GameFSM = require 'game/gamefsm'

  if col.item.classname ~= 'player' then
    return
  end
  
  if s.goal_time ~= nil then
    return
  end
  
  s.goal_time = s.time + 10
  col.item.can_take_damage = false
  GameFSM.addEvent(s, {type = 'sound', name = 'goal'})
end

e.take_damage = function(s, ent, dmg)

end

return e