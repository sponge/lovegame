local ffi = require 'ffi'

local Entity = require 'game/entity'
local Tiny= require 'game/tiny'

local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min

ffi.cdef [[

  typedef struct {
    uint16_t number;
    bool in_use;
    uint8_t class;
    float x, y;
    int w, h;
  } ent_player_start_t;
  
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
    
    uint16_t number;
    bool in_use;
    uint8_t class;
    float x, y, dx, dy, uncapped_dy;
    int w, h, drawx, drawy;
    etype_t type;
    bool can_take_damage;
    uint16_t health;
    collisiontype_t collision[ET_MAX];
    entcommand_t command;
    
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
    
    int16_t gravity;
    int16_t max_speed;
    int16_t terminal_velocity;
    int16_t accel;
    int16_t skid_accel;
    int16_t air_accel;
    int16_t turn_air_accel;
    int16_t air_friction;
    int16_t ground_friction;
    int16_t jump_height;
    int16_t speed_jump_bonus;
    int16_t pogo_jump_height;
    int16_t double_jump_height;
    float early_jump_end_modifier;
    int16_t wall_slide_speed;
    int16_t wall_jump_x;
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
  ent.anim_frame = ent.STAND
  ent.anim_mirror = false
  ent.on_ground = false
  ent.last_ground_y = ent.y
  ent.did_jump = false
  ent.can_double_jump = false
  ent.can_wall_jump = false
  ent.jump_held = false
  ent.will_pogo = false
  ent.will_bounce_enemy = false
  ent.wall_sliding = false
  ent.stun_time = 0
  ent.invuln_time = 0
  ent.attack_length = 0.25
  ent.attack_time = 0
  ent.attack_held = false
  ent.accel_type = 0
  ent.coins = 0
  
  ent.drawx = 5
  ent.drawy = -2
  ent.type = ffi.C.ET_PLAYER
  ent.collision[ffi.C.ET_WORLD] = ffi.C.CT_SLIDE
  ent.can_take_damage = true
  ent.health = 6
end

e.think = function(s, ent, dt) 
  setup_physics(s, ent)
  
  ent.on_ground = ent.dy >= 0 and Entity.isTouchingSolid(s, ent, 'down')
  
  -- reset some state if on ground, otherwise gravity
  if ent.on_ground then
    ent.did_jump = false
    ent.can_double_jump = true
    ent.last_ground_y = ent.y
  else
    ent.dy = ent.dy + (ent.gravity*dt)
  end
  
  if s.goal_time ~= nil then
    for _, v in ipairs(ent.command) do
      ent.command[v] = false
    end
  end
  
  -- check for wall sliding
  local wasSlide = ent.wall_sliding
  local leftWall = ent.command.left and Entity.isTouchingSolid(s, ent, 'left')
  local rightWall = ent.command.right and Entity.isTouchingSolid(s, ent, 'right')
  ent.wall_sliding = false
  ent.can_wall_jump = not ent.on_ground and (leftWall or rightWall)
  if not ent.on_ground and ent.dy > 0 then
    -- check for a wall in the held direction
    ent.wall_sliding = leftWall or rightWall
  end
  
  if not wasSlide and ent.wall_sliding then
    Tiny.addEntity(s.world, {event = 'sound', name = 'wallslide'})
  elseif wasSlide and not ent.wall_sliding then
    Tiny.addEntity(s.world, {event = 'stopsound', name = 'wallslide'})
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
  if not ent.on_ground and (ent.dy < 0 or not ent.will_pogo) then
    ent.will_pogo = ent.command.down
  end
  
  -- check for pogo jump
  if ent.on_ground and ent.will_pogo then
    ent.dy = ent.pogo_jump_height
    ent.can_double_jump = true
    ent.did_jump = true
    ent.will_pogo = false
    Tiny.addEntity(s.world, {event = 'sound', name = 'pogo'})
  -- check for other jumps
  elseif ent.command.jump == true and ent.jump_held == false then
    -- check for walljump
    if ent.can_wall_jump then
      ent.dy = ent.double_jump_height
      ent.dx = ent.wall_jump_x * (ent.command.right and -1 or 1)
      ent.stun_time = s.time + 1/10
      ent.jump_held = true
      ent.did_jump = true
      Tiny.addEntity(s.world, {event = 'sound', name = 'jump'})
    -- check for first jump
    elseif ent.on_ground then
      ent.dy = ent.jump_height + (abs(ent.dx) >= ent.max_speed * 0.25 and ent.speed_jump_bonus or 0)
      ent.jump_held = true
      ent.can_double_jump = true
      ent.did_jump = true
      Tiny.addEntity(s.world, {event = 'sound', name = 'jump'})
    -- check for second jump
    elseif ent.can_double_jump == true then
      ent.dy = ent.double_jump_height
      ent.can_double_jump = false
      ent.jump_held = true
      ent.did_jump = true
      Tiny.addEntity(s.world, {event = 'sound', name = 'jump'})
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
    Tiny.addEntity(s.world, {event = 'sound', name = 'skid'})
  elseif last_accel == ent.skid_accel and ent.accel_type ~= ent.skid_accel then
    Tiny.addEntity(s.world, {event = 'stopsound', name = 'skid'})
  end
  
  -- cap intended x/y speed
  ent.uncapped_dy = ent.dy
  ent.dx = max(-ent.max_speed, min(ent.max_speed, ent.dx))
  ent.dy = max(-ent.terminal_velocity, min(ent.terminal_velocity, ent.dy))
end

e.collide = function(s, ent, col)
  if ent.will_pogo and col.other.type == ffi.C.ET_ENEMY and col.normal.x == 0 and col.normal.y == -1 then
    Entity.hurt(s, col.other, 1, ent)
    ent.will_bounce_enemy = true
  end
end

e.postcollide = function(s, ent, xCollided, yCollided, xCols, yCols)
  ent.dy = ent.uncapped_dy
  
  -- walls always stop momentum
  if xCollided then
    ent.dx = 0
  end
  
  if ent.will_bounce_enemy then
    ent.dy = ent.will_pogo and ent.pogo_jump_height or ent.jump_height
    ent.dy = ent.dy * 0.75
    ent.can_double_jump = true
    ent.will_bounce_enemy = false
  elseif yCollided and ent.dy > 0 and not ent.will_pogo then
    ent.dy = 0
    if ent.dy >= ent.terminal_velocity * 0.75 then
      Tiny.addEntity(s.world, {event = 'sound', name = 'bump'})
    end  
  elseif yCollided and ent.dy < 0 then
    ent.dy = 0
    Tiny.addEntity(s.world, {event = 'sound', name = 'headbump'})
  end
  
  if s.time < ent.attack_time then
    local hits, len = s.bump:queryRect(ent.anim_mirror and ent.x - 13 or ent.x + ent.w, ent.y + ent.drawy + 11, 13, 5)
    for i=1, len do
      Entity.hurt(s, hits[i], 1, ent)
    end
  end  
end

e.draw = function(s, ent)
  local x = nil
  local sx = 1
  
  ent.anim_frame = ent.STAND
  
  if s.time < ent.attack_time then
    ent.anim_frame = ent.SHOOT
  elseif ent.wall_sliding then
    ent.anim_frame = ent.PREJUMP3
  elseif ent.will_pogo then
    ent.anim_frame = ent.POGOCHRG
  elseif ent.did_jump then
    ent.anim_frame = ent.JUMP
  elseif ent.accel_type == ent.skid_accel then
    ent.anim_frame = ent.PREJUMP2
  elseif ent.dx ~= 0 then
    local i = math.floor(s.time * 8) % 3 + 1
    ent.anim_frame = ent["RUN"..i]
  end
  
  if ent.anim_mirror then
    x = ent.x + ent.w + ent.drawx
    sx = sx * -1
  else
    x = ent.x - ent.drawx
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
end

e.take_damage = function(s, ent, amount)  
  if s.time < ent.invuln_time then
    return
  end
  
  ent.invuln_time = s.time + 1
  ent.health = ent.health - amount
  
  if ent.health <= 0 then
    Tiny.addEntity(s.world, {event = 'death', ent = ent.number})
  else
    Tiny.addEntity(s.world, {event = 'sound', name = 'hurt'})
  end
end

return e