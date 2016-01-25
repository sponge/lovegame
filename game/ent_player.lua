local ffi = require("ffi")

local Entity = require 'game/entity'

local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min

ffi.cdef [[
  typedef struct {
    enum {
      BAD = 0,
      STAND,
      RUN1,
      RUN2,
      RUN3,
      PREJUMP1,
      PREJUMP2,
      PREJUMP3,
      PREJUMP4,
      JUMP,
      SHOOT,
      POGOJUMP,
      POGOCHRG
    };
    
    uint8_t anim_frame;
    bool anim_mirror;
    bool on_ground;
    uint16_t last_ground_y;
    bool did_jump;
    bool can_double_jump;
    bool can_wall_jump;
    bool jump_held;
    bool will_pogo;
    bool will_bounce_enemy;
    bool wall_sliding;
    float stun_time;
    float invuln_time;
    float attack_length;
    float attack_time;
    bool attack_held;
    float accel_type;
    uint16_t coins;
  } ent_player_t;
]]

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

  ent.wall_slide_speed = cv.p_wallslidespeed.int
  ent.wall_jump_x = cv.p_walljumpx.int
end

local function getAccel(s, ent, dir)
  local ed = ent.edata
  
  if s.time < ed.stun_time then
    return 0
  end
  
  if not ed.on_ground then
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
      love.graphics.newQuad(16*0,  0, 16, h, w, h),
      love.graphics.newQuad(16*1,  0, 16, h, w, h),
      love.graphics.newQuad(16*2,  0, 16, h, w, h),
      love.graphics.newQuad(16*3,  0, 16, h, w, h),
      love.graphics.newQuad(16*4,  0, 16, h, w, h),
      love.graphics.newQuad(16*5,  0, 16, h, w, h),
      love.graphics.newQuad(16*6,  0, 16, h, w, h),
      love.graphics.newQuad(16*7,  0, 16, h, w, h),
      love.graphics.newQuad(16*8,  0, 16, h, w, h),
      love.graphics.newQuad(16*9,  0, 16, h, w, h),
      love.graphics.newQuad(16*10, 0, 16, h, w, h),
      love.graphics.newQuad(16*11, 0, 16, h, w, h)
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
    s.media.snd_headbump = love.audio.newSource("base/headbump.wav", "static")
  end
end

e.spawn = function(s, ent)
  ent.edata = ffi.new("ent_player_t")
  local ed = ent.edata
  
  ed.anim_frame = ed.STAND
  ed.anim_mirror = false
  ed.on_ground = false
  ed.last_ground_y = ent.y
  ed.did_jump = false
  ed.can_double_jump = false
  ed.can_wall_jump = false
  ed.jump_held = false
  ed.will_pogo = false
  ed.will_bounce_enemy = false
  ed.wall_sliding = false
  ed.stun_time = 0
  ed.invuln_time = 0
  ed.attack_length = 0.25
  ed.attack_time = 0
  ed.attack_held = false
  ed.accel_type = 0
  ed.coins = 0
  
  ent.drawx = 5
  ent.drawy = -2
  ent.type = 'player'
  ent.collision = {
    enemy = 'cross',
    playertrigger = 'cross',
    world = 'slide',
  }
  ent.can_take_damage = true
  ent.health = 6
  
  s.bump:add(ent, ent.x, ent.y, ent.w, ent.h)
end

e.think = function(s, ent, dt)     
  local ed = ent.edata
  setup_physics(s, ent)
  
  ed.on_ground = ent.dy >= 0 and Entity.isTouchingSolid(s, ent, 'down')
  
  -- reset some state if on ground, otherwise gravity
  if ed.on_ground then
    ed.did_jump = false
    ed.can_double_jump = true
    ed.last_ground_y = ent.y
  else
    ent.dy = ent.dy + (ent.gravity*dt)
  end
  
  if s.s.goal_time ~= nil then
    for i in pairs(ent.command) do
      ent.command[i] = false
    end
  end
  
  -- check for wall sliding
  local wasSlide = ed.wall_sliding
  local leftWall = ent.command.left and Entity.isTouchingSolid(s, ent, 'left')
  local rightWall = ent.command.right and Entity.isTouchingSolid(s, ent, 'right')
  ed.wall_sliding = false
  ed.can_wall_jump = not ed.on_ground and (leftWall or rightWall)
  if not ed.on_ground and ent.dy > 0 then
    -- check for a wall in the held direction
    ed.wall_sliding = leftWall or rightWall
  end
  
  if not wasSlide and ed.wall_sliding then
    s.event_cb(s, {type = 'sound', name = 'wallslide'})
  elseif wasSlide and not ed.wall_sliding then
    s.event_cb(s, {type = 'stopsound', name = 'wallslide'})
  end
    
  -- apply wall sliding
  if ed.wall_sliding then
    -- FIXME: transition to slide speed, not instant
    ent.dy = ent.wall_slide_speed
  end
  
  -- check if let go of jump
  if ent.command.jump == false and ed.jump_held == true then
    -- allow a jump next time the ground is touched
    ed.jump_held = false
    -- allow shorter hops by letting go of jumps while going up
    if ent.dy < 0 then
      ent.dy = floor(ent.dy * ent.early_jump_end_modifier)
    end
  end
  
  -- check if the player wants to pogo, but don't let a pogo start on the ground
  if not ed.on_ground and (ent.dy < 0 or not ed.will_pogo) then
    ed.will_pogo = ent.command.down
  end
  
  -- check for pogo jump
  if ed.on_ground and ed.will_pogo then
    ent.dy = ent.pogo_jump_height
    ed.can_double_jump = true
    ed.did_jump = true
    ed.will_pogo = false
    s.event_cb(s, {type = 'sound', name = 'pogo'})
  -- check for other jumps
  elseif ent.command.jump == true and ed.jump_held == false then
    -- check for walljump
    if ed.can_wall_jump then
      ent.dy = ent.double_jump_height
      ent.dx = ent.wall_jump_x * (ent.command.right and -1 or 1)
      ed.stun_time = s.time + 1/10
      ed.jump_held = true
      ed.did_jump = true
      s.event_cb(s, {type = 'sound', name = 'jump'})
    -- check for first jump
    elseif ed.on_ground then
      ent.dy = ent.jump_height + (abs(ent.dx) >= ent.max_speed * 0.25 and ent.speed_jump_bonus or 0)
      ed.jump_held = true
      ed.can_double_jump = true
      ed.did_jump = true
      s.event_cb(s, {type = 'sound', name = 'jump'})
    -- check for second jump
    elseif ed.can_double_jump == true then
      ent.dy = ent.double_jump_height
      ed.can_double_jump = false
      ed.jump_held = true
      ed.did_jump = true
      s.event_cb(s, {type = 'sound', name = 'jump'})
    end
  end
  
  if ent.command.attack == false and ed.attack_held == true and s.time >= ed.attack_time then
    ed.attack_held = false
  end
  
  if ent.command.attack and not ed.attack_held then
    ed.attack_time = s.time + ed.attack_length
    ed.attack_held = true
  end

  -- player wants to move left, check what their accel should be
  local last_accel = ed.accel_type
  if ent.command.left and s.time >= ed.attack_time then
    ed.accel_type = getAccel(s, ent,'left')
    ent.dx = ent.dx - (ed.accel_type*dt)
    ed.anim_mirror = true
  -- player wants to move right
  elseif ent.command.right and s.time >= ed.attack_time then
    ed.accel_type = getAccel(s, ent,'right')
    ent.dx = ent.dx + (ed.accel_type*dt)
    ed.anim_mirror = false
  -- player isn't moving, bring them to stop
  else
    local friction = ed.on_ground and ent.ground_friction or ent.air_friction
    if ent.dx < 0 then
      ent.dx = ent.dx + (friction*dt)
    elseif ent.dx > 0 then
      ent.dx = ent.dx - (friction*dt)
    end
    
    -- stop small floats from creeping you around
    if ent.dx ~= 0 and abs(ent.dx) < 1 then
      ent.dx = 0
    end
    ed.accel_type = 0
  end
  
  if abs(ent.dx) > 60 and last_accel ~= ent.skid_accel and ed.accel_type == ent.skid_accel then
    s.event_cb(s, {type = 'sound', name = 'skid'})
  elseif last_accel == ent.skid_accel and ed.accel_type ~= ent.skid_accel then
    s.event_cb(s, {type = 'stopsound', name = 'skid'})
  end
  
  -- cap intended x/y speed
  local uncappeddy = ent.dy
  ent.dx = max(-ent.max_speed, min(ent.max_speed, ent.dx))
  ent.dy = max(-ent.terminal_velocity, min(ent.terminal_velocity, ent.dy))
  
  -- start the actual move
  local xCollided, yCollided, xCols, yCols = Entity.move(s, ent)
  
  ent.dy = uncappeddy
  
  -- walls always stop momentum
  if xCollided then
    ent.dx = 0
  end
  
  if ed.will_bounce_enemy then
    ent.dy = ed.will_pogo and ent.pogo_jump_height or ent.jump_height
    ent.dy = ent.dy * 0.75
    ed.can_double_jump = true
    ed.will_bounce_enemy = false
  elseif yCollided and ent.dy > 0 and not ed.will_pogo then
    ent.dy = 0
    if ent.dy >= ent.terminal_velocity * 0.75 then
      s.event_cb(s, {type = 'sound', name = 'bump'})
    end  
  elseif yCollided and ent.dy < 0 then
    ent.dy = 0
    s.event_cb(s, {type = 'sound', name = 'headbump'})
  end
  
  if s.time < ed.attack_time then
    local hits, len = s.bump:queryRect(ed.anim_mirror and ent.x - 13 or ent.x + ent.w, ent.y + ent.drawy + 11, 13, 5)
    for i=1, len do
      Entity.hurt(s, hits[i], 1, ent)
    end
  end

end

e.collide = function(s, ent, col)
  local ed = ent.edata
  if ed.will_pogo and col.other.type == 'enemy' and col.normal.x == 0 and col.normal.y == -1 then
    Entity.hurt(s, col.other, 1, ent)
    ed.will_bounce_enemy = true
  end
end

e.draw = function(s, ent)
  local ed = ent.edata
  local x = nil
  local sx = 1
  
  ed.anim_frame = ed.STAND
  
  if s.time < ed.attack_time then
    ed.anim_frame = ed.SHOOT
  elseif ed.wall_sliding then
    ed.anim_frame = ed.PREJUMP3
  elseif ed.will_pogo then
    ed.anim_frame = ed.POGOCHRG
  elseif ed.did_jump then
    ed.anim_frame = ed.JUMP
  elseif ed.accel_type == ent.skid_accel then
    ed.anim_frame = ed.PREJUMP2
  elseif ent.dx ~= 0 then
    local i = math.floor(s.time * 8) % 3 + 1
    ed.anim_frame = ent.edata["RUN"..i]
  end
  
  if ed.anim_mirror then
    x = ent.x + ent.w + ent.drawx
    sx = sx * -1
  else
    x = ent.x - ent.drawx
  end
  
  if s.time < ed.invuln_time then
    love.graphics.setColor(255,255,255,100)
  end
  
  love.graphics.draw(s.media.player, s.media.player_frames[ed.anim_frame], x, ent.y + ent.drawy, 0, sx, 1)
  
  if s.time < ed.attack_time then
    local swordx = x+(ed.anim_mirror and -ent.w-4 or 14)
    local swordy = ent.y + ent.drawy + 11
    if ed.anim_mirror then
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
end

e.take_damage = function(s, ent, amount)
  local ed = ent.edata
  
  if s.time < ed.invuln_time then
    return
  end
  
  ed.invuln_time = s.time + 1
  ent.health = ent.health - amount
  
  if ent.health <= 0 then
    s.event_cb(s, {type = 'death', ent = ent.number})
  else
    s.event_cb(s, {type = 'sound', name = 'hurt'})
  end
end

return e