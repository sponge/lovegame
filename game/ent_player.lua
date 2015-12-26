local Entity = require 'game/entity'

local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min

local function setup_physics(s, ent)
  local cv = s.cvars
  ent.gravity = cv.p_gravity.int

  ent.max_speed = cv.p_speed.int
  ent.terminal_velocity = cv.p_terminalvel.int

  ent.accel = cv.p_accel.int
  ent.skid_accel = cv.p_skidaccel.int
  ent.air_accel = cv.p_airaccel.int
  ent.turn_air_accel = cv.p_turnairaccel.int

  ent.air_friction = cv.p_airfriction.int
  ent.ground_friction = cv.p_groundfriction.int

  ent.jump_height = cv.p_jumpheight.int
  ent.speed_jump_bonus = cv.p_speedjumpbonus.int
  ent.pogo_jump_height = cv.p_pogojumpheight.int
  ent.double_jump_height = cv.p_doublejumpheight.int
  ent.early_jump_end_modifier = cv.p_earlyjumpendmodifier.value
  ent.head_bump_modifier = cv.p_headbumpmodifier.value

  ent.wall_slide_speed = cv.p_wallslidespeed.int
  ent.wall_jump_x = cv.p_walljumpx.int
end


local function getAccel(s, ent, dir)
  if s.time < ent.stun_time then
    return 0
  end
  
  if not ent.on_ground then
    if (dir == 'left' and ent.dx > 0) or (dir == 'right' and ent.dx < 0) then
      return ent.turn_air_accel
    else
      return ent.air_accel
    end
  elseif (dir == 'left' and ent.dx > 0) or (dir == 'right' and ent.dx < 0) then
    return ent.skid_accel
  else
    return ent.accel
  end
end

local e = {}

e.init = function(s)
  if love.graphics then
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
  
  if love.audio then
    s.media.snd_jump = love.audio.newSource("base/jump.wav", "static")
    s.media.snd_pogo = love.audio.newSource("base/pogo.wav", "static")
    s.media.snd_wallslide = love.audio.newSource("base/wallslide.wav", "static")
    s.media.snd_wallslide:setLooping(true)
    s.media.snd_skid = love.audio.newSource("base/skid.wav", "static")
    s.media.snd_bump = love.audio.newSource("base/bump.wav", "static")
    s.media.snd_hurt = love.audio.newSource("base/hurt.wav", "static")

  end
end

e.spawn = function(s, ent)
  ent.anim_frame = "stand"
  ent.anim_mirror = false
  ent.on_ground = false
  ent.last_ground_y = ent.y
  ent.can_jump = false
  ent.did_jump = false
  ent.can_double_jump = false
  ent.jump_held = false
  ent.will_pogo = false
  ent.wall_sliding = false
  ent.stun_time = 0
  ent.invuln_time = 0
  ent.attack_length = 0.25
  ent.attack_time = 0
  ent.attack_held = false
  ent.drawx = 5
  ent.drawy = -2
  ent.collision = 'slide'
  ent.accel_type = 0
  ent.coins = 0
  ent.health = 6
  ent.can_take_damage = true
  
  s.bump:add(ent, ent.x, ent.y, ent.w, ent.h)
end

e.think = function(s, ent, dt)     
  setup_physics(s, ent)
  
  ent.on_ground = ent.dy >= 0 and Entity.isTouchingSolid(s, ent, 'down')
  
  -- reset some state if on ground, otherwise gravity
  if ent.on_ground then
    ent.can_jump = true
    ent.did_jump = false
    ent.can_double_jump = true
    ent.last_ground_y = ent.y
  else
    ent.dy = ent.dy + (ent.gravity*dt)
    ent.can_jump = false
  end
  
  if s.s.goal_time ~= nil then
    for i in pairs(ent.command) do
      ent.command[i] = false
    end
  end
  
  -- check for wall sliding
  local wasSlide = ent.wall_sliding
  ent.wall_sliding = false
  if not ent.on_ground and ent.dy > 0 then
    -- check for a wall in the held direction
    ent.wall_sliding = (ent.command.left and Entity.isTouchingSolid(s, ent, 'left')) and 'left' or false
    ent.wall_sliding = (ent.command.right and Entity.isTouchingSolid(s, ent, 'right')) and 'right' or ent.wall_sliding
  end
  
  if not wasSlide and ent.wall_sliding then
    s.event_cb(s, {type = 'sound', name = 'wallslide'})
  elseif wasSlide and not ent.wall_sliding then
    s.event_cb(s, {type = 'stopsound', name = 'wallslide'})
  end
    
  -- apply wall sliding
  if ent.wall_sliding then
    -- FIXME: transition to slide speed, not instant
    ent.dy = ent.wall_slide_speed
  end
  
  -- check if let go of jump
  if ent.command.jump == false and ent.jump_held == true then
    -- allow a jump next time the ground is touched
    ent.jump_held = false
    -- allow shorter hops by letting go of jumps while going up
    if ent.dy < 0 then
      ent.dy = floor(ent.dy * ent.early_jump_end_modifier)
    end
  end
  
  -- check if the player wants to pogo, but don't let a pogo start on the ground
  if not ent.on_ground then
    ent.will_pogo = ent.command.down
  end
  
  -- check for pogo jump
  if ent.on_ground and ent.will_pogo then
    ent.dy = ent.pogo_jump_height
    ent.can_jump = true
    ent.can_double_jump = true
    ent.did_jump = true
    s.event_cb(s, {type = 'sound', name = 'pogo'})
  -- check for other jumps
  elseif ent.command.jump == true and ent.jump_held == false then
    -- check for walljump
    if ent.wall_sliding then
      ent.dy = ent.jump_height
      ent.dx = ent.wall_jump_x * (ent.command.right and -1 or 1)
      ent.stun_time = s.time + 1/10
      ent.jump_held = true
      ent.did_jump = true
      s.event_cb(s, {type = 'sound', name = 'jump'})
    -- check for first jump
    elseif ent.can_jump == true then
      ent.dy = ent.jump_height + (abs(ent.dx) >= ent.max_speed * 0.25 and ent.speed_jump_bonus or 0)
      ent.can_jump = false
      ent.jump_held = true
      ent.can_double_jump = true
      ent.did_jump = true
      s.event_cb(s, {type = 'sound', name = 'jump'})
    -- check for second jump
    elseif ent.can_double_jump == true then
      ent.dy = ent.double_jump_height
      ent.can_double_jump = false
      ent.jump_held = true
      ent.did_jump = true
      s.event_cb(s, {type = 'sound', name = 'jump'})
    end
  end
  
  if ent.command.attack == false and ent.attack_held == true and s.time >= ent.attack_time then
    ent.attack_held = false
  end
  
  if ent.command.attack and not ent.attack_held then
    ent.attack_time = s.time + ent.attack_length
    ent.attack_held = true
  end

  -- player wants to move left, check what their accel should be
  local last_accel = ent.accel_type
  if ent.command.left and s.time >= ent.attack_time then
    ent.accel_type = getAccel(s, ent,'left')
    ent.dx = ent.dx - (ent.accel_type*dt)
    ent.anim_mirror = true
  -- player wants to move right
  elseif ent.command.right and s.time >= ent.attack_time then
    ent.accel_type = getAccel(s, ent,'right')
    ent.dx = ent.dx + (ent.accel_type*dt)
    ent.anim_mirror = false
  -- player isn't moving, bring them to stop
  else
    local friction = ent.on_ground and ent.ground_friction or ent.air_friction
    if ent.dx < 0 then
      ent.dx = ent.dx + (friction*dt)
    elseif ent.dx > 0 then
      ent.dx = ent.dx - (friction*dt)
    end
    
    -- stop small floats from creeping you around
    if ent.dx ~= 0 and abs(ent.dx) < 1 then
      ent.dx = 0
    end
    ent.accel_type = 0
  end
  
  if abs(ent.dx) > 60 and last_accel ~= ent.skid_accel and ent.accel_type == ent.skid_accel then
    s.event_cb(s, {type = 'sound', name = 'skid'})
  elseif last_accel == ent.skid_accel and ent.accel_type ~= ent.skid_accel then
    s.event_cb(s, {type = 'stopsound', name = 'skid'})
  end
  
  -- cap intended x/y speed
  ent.dx = max(-ent.max_speed, min(ent.max_speed, ent.dx))
  ent.dy = min(ent.terminal_velocity, ent.dy)
  
  -- start the actual move
  local xCollided, yCollided = Entity.move(s, ent)
  
  -- walls always stop momentum
  if xCollided then
    ent.dx = 0
  end
  
  -- stop them if they fall onto something solid
  if yCollided and ent.dy > 0 then
    if not ent.will_pogo and ent.dy >= ent.terminal_velocity * 0.75 then
      s.event_cb(s, {type = 'sound', name = 'bump'})
    end
    ent.dy = 0
  -- conserve some momentum (note this will get hit for several frames after first collision)
  elseif yCollided and ent.dy < 0 then
    ent.dy = ent.dy * ent.head_bump_modifier
  end
  
  if s.time < ent.attack_time then
    local hits, len = s.bump:queryRect(ent.anim_mirror and ent.x - 13 or ent.x + ent.w, ent.y + ent.drawy + 11, 13, 5)
    for i=1, len do
      if hits[i].can_take_damage then
        s.ent_handlers[hits[i].classname].take_damage(s, hits[i], 1)
      end
    end
  end

end

e.collide = function(s, ent, col)
  if col.other.classname == 'goomba' and col.normal.x == 0 and col.normal.y == -1 then
    ent.dy = 2 * (ent.will_pogo and ent.pogo_jump_height or ent.jump_height)
  end
end

e.draw = function(s, ent)
  local x = nil
  local sx = 1
  
  ent.anim_frame = "stand"
  
  if s.time < ent.attack_time then
    ent.anim_frame = "shoot"
  elseif ent.wall_sliding then
    ent.anim_frame = "prejump3"
  elseif ent.will_pogo then
    ent.anim_frame = "pogochrg"
  elseif ent.did_jump then
    ent.anim_frame = "jump"
  elseif ent.accel_type == ent.skid_accel then
    ent.anim_frame = "prejump2"
  elseif ent.dx ~= 0 then
    local i = math.floor(s.time * 8) % 3 + 1
    ent.anim_frame = "run"..i
  end
  
  if ent.anim_mirror then
    x = ent.x + ent.w + ent.drawx
    sx = sx * -1
  else
    x = ent.x - ent.drawx
  end
  
  if ent.dbg then
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("fill", ent.x, ent.y, ent.w, ent.h)
    love.graphics.setColor(255,255,255,255)
  end
  
  if s.time < ent.invuln_time then
    love.graphics.setColor(255,255,255,100)
  end
  
  love.graphics.draw(s.media.player, s.media.player_frames[ent.anim_frame], x, ent.y + ent.drawy, 0, sx, 1)
  
  if s.time < ent.attack_time then
    local swordx = x+(ent.anim_mirror and -ent.w-4 or 14)
    local swordy = ent.y + ent.drawy + 11
    if ent.anim_mirror then
      love.graphics.polygon("fill", swordx, swordy, swordx-13, swordy + 2.5, swordx, swordy+5)
      love.graphics.setColor(90,90,90,255)
      love.graphics.polygon("line", swordx, swordy, swordx-13, swordy + 2.5, swordx, swordy +5)
    else
      love.graphics.polygon("fill", swordx, swordy, swordx+13, swordy + 2.5, swordx, swordy +5)
      love.graphics.setColor(90,90,90,255)
      love.graphics.polygon("line", swordx, swordy, swordx+13, swordy + 2.5, swordx, swordy +5)
    end
  end
  
  love.graphics.setColor(255,255,255,255)
  
  if ent.dbg then
    love.graphics.print(ent.dbg, ent.x, ent.y)
  end
end

e.take_damage = function(s, ent, amount)
  if s.s.goal_time ~= nil then
    return
  end
  
  if s.time < ent.invuln_time then
    return
  end
  
  ent.invuln_time = s.time + 1
  ent.health = ent.health - amount
  
  if ent.health <= 0 then
    s.event_cb(s, {type = 'death', ent = ent.number})
  else
    s.event_cb(s, {type = 'sound', name = 'hurt'})
  end
end

return e