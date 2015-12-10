local function player_spawn(ent, s)
  ent.on_ground = false
  ent.can_jump = false
  ent.jump_held = false
end

local function player_think(ent, s, dt)
  _, ent.on_ground = s.col:bottomResolve(s, ent, ent.x, ent.y + 1, ent.w, ent.h, 0, 1)
  
  -- gravity
  if ent.on_ground then
    ent.can_jump = true
  else
    ent.dy = ent.dy + (400*dt)
    ent.can_jump = false
  end
  
  if ent.command.button1 == false and ent.jump_held == true then
    ent.jump_held = false
    if ent.dy < 0 then
      ent.dy = math.floor(ent.dy * 0.75)
    end
  end
  
  if ent.command.button1 == true and ent.can_jump == true and ent.jump_held == false then
    ent.dy = -200
    ent.can_jump = false
    ent.jump_held = true
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
  
  ent.dx = math.max(-200, math.min(200, ent.dx))
  ent.dy = math.min(300, ent.dy)
  
  local collided = false
  if ent.dx > 0 then
    ent.x, collided = s.col:rightResolve(s, ent, ent.x + (ent.dx*dt), ent.y, ent.w, ent.h, ent.dx*dt, 0)
  elseif ent.dx < 0 then
    ent.x, collided = s.col:leftResolve(s, ent, ent.x + (ent.dx*dt), ent.y, ent.w, ent.h, ent.dx*dt, 0)
  end
  
  if collided then
    ent.dx = 0
  end
  
  collided = false
  if ent.dy > 0 then
    ent.y, collided = s.col:bottomResolve(s, ent, ent.x, ent.y + (ent.dy*dt), ent.w, ent.h, 0, ent.dy*dt)
    if collided then
      ent.dy = 0
    end
  elseif ent.dy < 0 then
    ent.y, collided = s.col:topResolve(s, ent, ent.x, ent.y + (ent.dy*dt), ent.w, ent.h, 0, ent.dy*dt)
  end

end

local function player_draw(ent)
  love.graphics.setColor(255,0,0,255)
  love.graphics.rectangle("fill", ent.x, ent.y, 16, 32)
  love.graphics.setColor(255,255,255,255)
  love.graphics.print(ent.dx, ent.x, ent.y)
  love.graphics.print(ent.dy, ent.x, ent.y + 10)
end

return { spawn = player_spawn, think = player_think, draw = player_draw }