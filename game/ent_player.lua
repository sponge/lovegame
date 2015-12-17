local Entity = require 'game/entity'

local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min

local GRAVITY = 375

local MAX_SPEED = 170
local TERMINAL_VELOCITY = 300

local ACCEL = 150
local SKID_ACCEL = 420
local AIR_ACCEL = 150
local TURN_AIR_ACCEL = 230

local AIR_FRICTION = 100
local GROUND_FRICTION = 300

local JUMP_HEIGHT = -190
local SPEED_JUMP_BONUS = -15
local POGO_JUMP_HEIGHT = -245
local DOUBLE_JUMP_HEIGHT = -145
local EARLY_JUMP_END_MODIFIER = 0.6
local HEAD_BUMP_MODIFIER = 0.5

local WALL_SLIDE_SPEED = 45
local WALL_JUMP_X = 100

local function getAccel(s, ent, dir)
  if s.time < ent.stun_time then
    return 0
  end
  
  if not ent.on_ground then
    if (dir == 'left' and ent.dx > 0) or (dir == 'right' and ent.dx < 0) then
      return TURN_AIR_ACCEL
    else
      return AIR_ACCEL
    end
  elseif (dir == 'left' and ent.dx > 0) or (dir == 'right' and ent.dx < 0) then
    return SKID_ACCEL
  else
    return ACCEL
  end
end

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
  ent.anim_frame = "stand"
  ent.anim_mirror = false
  ent.on_ground = false
  ent.last_ground_y = ent.y
  ent.can_jump = false
  ent.can_double_jump = false
  ent.jump_held = false
  ent.will_pogo = false
  ent.wall_sliding = false
  ent.stun_time = 0
  ent.drawx = 3
  ent.drawy = -2
end

local function player_think(s, ent, dt)
  _, ent.on_ground = s.col:bottomResolve(s, ent, ent.x, ent.y+1, ent.w, ent.h, 0, 1)
  -- we may be passing through a platform
  if ent.dy < 0 then
    ent.on_ground = false
  end
  
  -- reset some state if on ground, otherwise gravity
  if ent.on_ground then
    ent.can_jump = true
    ent.can_double_jump = true
    ent.last_ground_y = ent.y
  else
    ent.dy = ent.dy + (GRAVITY*dt)
    ent.can_jump = false
  end
  
  -- check for wall sliding
  if not ent.on_ground and ent.dy > 0 then
    -- check for a wall in the held direction
    if ent.command.left > 0 then
      _, ent.wall_sliding = s.col:leftResolve(s, ent, ent.x-1, ent.y, ent.w, ent.h, -1, 0)
      ent.wall_sliding = ent.wall_sliding and 'left' or false
    elseif ent.command.right > 0 then
      _, ent.wall_sliding = s.col:rightResolve(s, ent, ent.x+1, ent.y, ent.w, ent.h, 1, 0)
      ent.wall_sliding = ent.wall_sliding and 'right' or false

    else
      ent.wall_sliding = false
    end
  else
    ent.wall_sliding = false
  end
    
  -- apply wall sliding
  if ent.wall_sliding then
    -- FIXME: transition to slide speed, not instant
    ent.dy = WALL_SLIDE_SPEED
  end
  
  -- check if let go of jump
  if ent.command.button1 == false and ent.jump_held == true then
    -- allow a jump next time the ground is touched
    ent.jump_held = false
    -- allow shorter hops by letting go of jumps while going up
    if ent.dy < 0 then
      ent.dy = floor(ent.dy * EARLY_JUMP_END_MODIFIER)
    end
  end
  
  -- check if the player wants to pogo, but don't let a pogo start on the ground
  if not ent.on_ground then
    ent.will_pogo = ent.command.down > 0
  end
  
  -- check for pogo jump
  if ent.on_ground and ent.will_pogo then
    ent.dy = POGO_JUMP_HEIGHT
    ent.can_jump = true
    ent.can_double_jump = true
  -- check for other jumps
  elseif ent.command.button1 == true and ent.jump_held == false then
    -- check for walljump
    if ent.wall_sliding then
      ent.dy = JUMP_HEIGHT
      ent.dx = WALL_JUMP_X * (ent.command.right > 0 and -1 or 1)
      ent.stun_time = s.time + 1/10
      ent.jump_held = true
    -- check for first jump
    elseif ent.can_jump == true then
      ent.dy = JUMP_HEIGHT + (abs(ent.dx) >= MAX_SPEED * 0.25 and SPEED_JUMP_BONUS or 0)
      ent.can_jump = false
      ent.jump_held = true
      ent.can_double_jump = true
    -- check for second jump
    elseif ent.can_double_jump == true then
      ent.dy = DOUBLE_JUMP_HEIGHT
      ent.can_double_jump = false
      ent.jump_held = true
    end
  end
  
  -- player wants to move left, check what their accel should be
  if ent.command.left > 0 then
    ent.dx = ent.dx - (getAccel(s, ent,'left')*dt)
    ent.anim_mirror = true
  -- player wants to move right
  elseif ent.command.right > 0 then
    ent.dx = ent.dx + (getAccel(s, ent,'right')*dt)
    ent.anim_mirror = false
  -- player isn't moving, bring them to stop
  else
    local friction = ent.on_ground and GROUND_FRICTION or AIR_FRICTION
    if ent.dx < 0 then
      ent.dx = ent.dx + (friction*dt)
    elseif ent.dx > 0 then
      ent.dx = ent.dx - (friction*dt)
    end
    
    -- stop small floats from creeping you around
    if ent.dx ~= 0 and abs(ent.dx) < 1 then
      ent.dx = 0
    end
  end
  
  -- cap intended x/y speed
  ent.dx = max(-MAX_SPEED, min(MAX_SPEED, ent.dx))
  ent.dy = min(TERMINAL_VELOCITY, ent.dy)
  
  -- start the actual move
  
  -- check x first (slopes eventually?)
  local collided = false
  if ent.dx > 0 then
    ent.x, collided = s.col:rightResolve(s, ent, ent.x + (ent.dx*dt), ent.y, ent.w, ent.h, ent.dx*dt, 0)
  elseif ent.dx < 0 then
    ent.x, collided = s.col:leftResolve(s, ent, ent.x + (ent.dx*dt), ent.y, ent.w, ent.h, ent.dx*dt, 0)
  end
  
  -- don't conserve any movement in x on a collision
  if collided then
    ent.dx = 0
  end
  
  -- don't let them move offscreen, but also don't treat the edge as walls
  if ent.x < 0 then
    ent.x = 0
    ent.dx = 0
  elseif ent.x+ent.w > s.l.width*s.l.tilewidth then
    ent.x = s.l.width*s.l.tilewidth - ent.w
    ent.dx = 0
  end
  
  -- check y next
  collided = false
  if ent.dy > 0 then
    ent.y, collided = s.col:bottomResolve(s, ent, ent.x, ent.y + (ent.dy*dt), ent.w, ent.h, 0, ent.dy*dt)
    -- stop them if they fall onto something solid
    if collided then
      ent.dy = 0
    end
  elseif ent.dy < 0 then
    ent.y, collided = s.col:topResolve(s, ent, ent.x, ent.y + (ent.dy*dt), ent.w, ent.h, 0, ent.dy*dt)
    -- conserve some momentum (note this will get hit for several frames after first collision)
    if collided then
      ent.dy = ent.dy * HEAD_BUMP_MODIFIER
    end
  end

end

local function player_draw(s, ent)
  local x = nil
  local sx = 1
  
  ent.anim_frame = "stand"
  
  if ent.anim_mirror then
    x = ent.x + ent.w + ent.drawx
    sx = sx * -1
  else
    x = ent.x - ent.drawx
  end
  
  if ent.will_pogo then
    ent.anim_frame = "pogojump"
  end
  
  if ent.dbg then
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("fill", ent.x, ent.y, ent.w, ent.h)
    love.graphics.setColor(255,255,255,255)
  end
  
  love.graphics.draw(s.media.player, s.media.player_frames[ent.anim_frame], x, ent.y + ent.drawy, 0, sx, 1)
  
  if ent.wall_sliding then
    local x = ent.wall_sliding == 'right' and ent.x + ent.w or ent.x - 2
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("fill", x, ent.y, 2, ent.h)
    love.graphics.setColor(255,255,255,255)
  end
  
  if ent.dbg then
    love.graphics.print(ent.dbg, ent.x, ent.y)
  end
end

return { init = player_init, spawn = player_spawn, think = player_think, draw = player_draw }