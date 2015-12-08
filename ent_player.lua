local can_jump = false

local function player_think(ent, s, dt)
  
  if love.keyboard.isDown("z") and can_jump == true then
    ent.dy = -1
    can_jump = false
  end
  
  if love.keyboard.isDown("left") then
    ent.dx = ent.dx - (2 * dt)
  elseif love.keyboard.isDown("right") then
    ent.dx = ent.dx + (2 * dt)
  else
    if ent.dx < 0 then
      ent.dx = ent.dx + 2 * dt
    elseif ent.dx > 0 then
      ent.dx = ent.dx - 2 * dt
    end
    
    if ent.dx ~= 0 and math.abs(ent.dx) < 0.1 then
      ent.dx = 0
    end
  end
  
  ent.dx = math.max(-1, math.min(1, ent.dx))
  ent.dy = math.min(2, ent.dy + 2 * dt)
  
  local collided = false
  if ent.dx > 0 then
    ent.x, collided = s.col:rightResolve(s, ent.x + ent.dx, ent.y, ent.w, ent.h)
  elseif ent.dx < 0 then
    ent.x, collided = s.col:leftResolve(s, ent.x + ent.dx, ent.y, ent.w, ent.h)
  end
  
  if collided then
    ent.dx = 0
  end
  
  collided = false
  if ent.dy > 0 then
    ent.y, collided = s.col:bottomResolve(s, ent.x, ent.y + ent.dy, ent.w, ent.h)
    if collided then
      can_jump = true
      ent.dy = 0
    else
      can_jump = false
    end
  elseif ent.dy < 0 then
    ent.y, collided = s.col:topResolve(s, ent.x, ent.y + ent.dy, ent.w, ent.h)
  end

end

local function player_draw(ent)
  love.graphics.setColor(255,0,0,255)
  love.graphics.rectangle("fill", ent.x, ent.y, 16, 32)
  love.graphics.setColor(255,255,255,255)
end

return { think = player_think, draw = player_draw }