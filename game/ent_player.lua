local Entity = require 'game/entity'

local function player_init(s)
  if not love.graphics then return end
  
  s.media.player = love.graphics.newImage("base/player.png")
  s.media.player:setFilter("nearest", "nearest")

  local w, h = s.media.player:getDimensions()
  s.media.player_frames = {
    stand =    love.graphics.newQuad(16*0,  0, 16, h, w, h),
    run1 =     love.graphics.newQuad(16*1,  0, 16, h, w, h),
    run2 =     love.graphics.newQuad(16*2,  0, 16, h, w, h),
    run3 =     love.graphics.newQuad(16*3,  0, 16, h, w, h),
    prejump1 = love.graphics.newQuad(16*4,  0, 16, h, w, h),
    prejump2 = love.graphics.newQuad(16*5,  0, 16, h, w, h),
    prejump3 = love.graphics.newQuad(16*6,  0, 16, h, w, h),
    prejump4 = love.graphics.newQuad(16*7,  0, 16, h, w, h),
    jump =     love.graphics.newQuad(16*8,  0, 16, h, w, h),
    shoot =    love.graphics.newQuad(16*9,  0, 16, h, w, h),
    pogojump = love.graphics.newQuad(16*10, 0, 16, h, w, h),
    pogochrg = love.graphics.newQuad(16*11, 0, 16, h, w, h)
  }
end

local function player_spawn(s, ent)    
  ent.animFrame = "stand"
  ent.animMirror = false
  ent.on_ground = false
  ent.can_jump = false
  ent.jump_held = false
  ent.will_pogo = false
  ent.drawx = 3
  ent.drawy = -2
end

local function player_think(s, ent, dt)
  _, ent.on_ground = s.col:bottomResolve(s, ent, ent.x, ent.y+1, ent.w, ent.h, 0, 1)
  
  if ent.dy ~= 0 then
    on_ground = false
  end
  
  -- gravity
  if ent.on_ground then
    if ent.command.down > 0 and ent.will_pogo then
      ent.dy = -225
    else 
     ent.can_jump = true
     ent.will_pogo = false
    end
  else
    ent.dy = ent.dy + (400*dt)
    ent.can_jump = false
    ent.will_pogo = ent.command.down > 0
  end
  
  if ent.command.button1 == false and ent.jump_held == true then
    ent.jump_held = false
    if ent.dy < 0 then
      ent.dy = math.floor(ent.dy * 0.6)
    end
  end
  
  if ent.command.button1 == true and ent.can_jump == true and ent.jump_held == false then
    ent.dy = -200
    ent.can_jump = false
    ent.jump_held = true
  end
  
  if ent.command.left > 0 then
    ent.dx = ent.dx - (200*dt)
    ent.animMirror = true
  elseif ent.command.right > 0 then
    ent.dx = ent.dx + (200*dt)
    ent.animMirror = false
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
    if collided then
      ent.dy = ent.dy / 2
    end
  end

end

local function player_draw(s, ent)
  local x = nil
  local sx = 1
  
  ent.animFrame = "stand"
  
  if ent.animMirror then
    x = ent.x + ent.w + ent.drawx
    sx = sx * -1
  else
    x = ent.x - ent.drawx
  end
  
  if ent.will_pogo then
    ent.animFrame = "pogojump"
  end
    
  --love.graphics.setColor(255,0,0,255)
  --love.graphics.rectangle("fill", ent.x, ent.y, ent.w, ent.h)
  --love.graphics.setColor(255,255,255,255)
    
  love.graphics.draw(s.media.player, s.media.player_frames[ent.animFrame], x, ent.y + ent.drawy, 0, sx, 1)
end

return { init = player_init, spawn = player_spawn, think = player_think, draw = player_draw }