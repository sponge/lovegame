local can_jump = false

local function player_think(ent, s, dt)
  
  if ent.command.button1 == true and can_jump == true then
    ent.dy = -200
    can_jump = false
  end
  
  if ent.command.left > 0 then
    ent.dx = ent.dx - (200*dt)
  elseif ent.command.right > 0 then
    ent.dx = ent.dx + (200*dt)
  else
    if ent.dx < 0 then
      ent.dx = ent.dx + (200*dt)
    elseif ent.dx > 0 then
      ent.dx = ent.dx - (200*dt)
    end
    
    if ent.dx ~= 0 and math.abs(ent.dx) < 0.1 then
      ent.dx = 0
    end
  end
  
  -- gravity
  ent.dy = ent.dy + (400*dt)
  
  ent.dx = math.max(-200, math.min(200, ent.dx))
  ent.dy = math.min(300, ent.dy)
  
  local collided = false
  if ent.dx > 0 then
    ent.x, collided = s.col:rightResolve(s, ent.x + (ent.dx*dt), ent.y, ent.w, ent.h)
  elseif ent.dx < 0 then
    ent.x, collided = s.col:leftResolve(s, ent.x + (ent.dx*dt), ent.y, ent.w, ent.h)
  end
  
  if collided then
    ent.dx = 0
  end
  
  collided = false
  if ent.dy > 0 then
    ent.y, collided = s.col:bottomResolve(s, ent.x, ent.y + (ent.dy*dt), ent.w, ent.h)
    if collided then
      can_jump = true
      ent.dy = 0
    else
      can_jump = false
    end
  elseif ent.dy < 0 then
    ent.y, collided = s.col:topResolve(s, ent.x, ent.y + (ent.dy*dt), ent.w, ent.h)
  end

end

local function player_draw(ent)
  love.graphics.setColor(255,0,0,255)
  love.graphics.rectangle("fill", ent.x, ent.y, 16, 32)
  love.graphics.setColor(255,255,255,255)
end

return { think = player_think, draw = player_draw }