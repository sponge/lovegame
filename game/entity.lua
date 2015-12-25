local entity = {}
entity.__index = entity
entity.__tostring = function(ent) return "Entity: " .. ent.classname end

local function new(classname, x, y, w, h)
  assert(classname and x and y and w and h, "Invalid entity")

	return setmetatable({
      number = nil,
      classname = classname,
      x = x,
      y = y,
      dx = 0,
      dy = 0,
      w = w,
      h = h,
      drawx = 0,
      drawy = 0,
      think = nil,
      draw = nil,
      collide = nil,
      collision = 'cross',
      command = {}
    }, entity)
end

local function isTouchingSolid(s, ent, side)
  local touching = false
  local bumpx, bumpy

  local x = side == 'right' and 1 or 0
  x = side == 'left' and -1 or x
  
  local y = side == 'up' and -1 or 0
  y = side == 'down' and 1 or y
  
  _, touching = s.col:bottomResolve(s, ent, ent.x+x, ent.y+y, ent.w, ent.h, x, y)
  if not touching then
    bumpx, bumpy = s.bump:check(ent, ent.x+x, ent.y+y, s.bumpfilter)
    if side == 'left' or side == 'right' then
      touching = bumpx == ent.x
    else
      touching = bumpy == ent.y
    end
  end
  return touching
end

local function move(s, ent)
  local EntHandlers = require "game/enthandlers"

  local cols, len = nil
  local moves = {x = {0,0}, y={0,0}}
  local entCol, tileCol = false
  local xCollided, yCollided = false
  
  moves.x[1], _, cols, len = s.bump:check(ent, ent.x + (ent.dx*s.dt), ent.y, s.bumpfilter)
  for i=1, len do
    if EntHandlers[ent.classname].collide then EntHandlers[ent.classname].collide(s, ent, cols[i]) end
    if EntHandlers[cols[i].other.classname].collide then EntHandlers[cols[i].other.classname].collide(s, cols[i].other, cols[i]) end
    if cols[i].other.collision ~= 'cross' then
      entCol = true
    end
  end
    
  -- check x first (slopes eventually?)
  if ent.dx > 0 then
    moves.x[2], tileCol = s.col:rightResolve(s, ent, ent.x + (ent.dx*s.dt), ent.y, ent.w, ent.h, ent.dx*s.dt, 0)
    ent.x = math.min(unpack(moves.x))
  elseif ent.dx < 0 then
    moves.x[2], tileCol, cols, len = s.col:leftResolve(s, ent, ent.x + (ent.dx*s.dt), ent.y, ent.w, ent.h, ent.dx*s.dt, 0)
    ent.x = math.max(unpack(moves.x))
  end
  
  xCollided = entCol or tileCol 
  
  -- don't let them move offscreen, but also don't treat the edge as walls
  if ent.x < 0 then
    ent.x = 0
    xCollided = true
  elseif ent.x+ent.w > s.l.width*s.l.tilewidth then
    ent.x = s.l.width*s.l.tilewidth - ent.w
    xCollided = true
  end
  
  s.bump:update(ent, ent.x, ent.y)
  
  -- check y next
  entCol = false
  tileCol = false
  
  _, moves.y[1], cols, len = s.bump:check(ent, ent.x, ent.y + (ent.dy*s.dt), s.bumpfilter)
  for i=1, len do
    if EntHandlers[ent.classname].collide then EntHandlers[ent.classname].collide(s, ent, cols[i]) end
    if EntHandlers[cols[i].other.classname].collide then EntHandlers[cols[i].other.classname].collide(s, cols[i].other, cols[i]) end
    if cols[i].other.collision ~= 'cross' then
      entCol = true
      break
    end
  end
  
  if ent.dy > 0 then
    moves.y[2], tileCol = s.col:bottomResolve(s, ent, ent.x, ent.y + (ent.dy*s.dt), ent.w, ent.h, 0, ent.dy*s.dt)
    ent.y = math.min(unpack(moves.y))
  elseif ent.dy < 0 then
    moves.y[2], tileCol = s.col:topResolve(s, ent, ent.x, ent.y + (ent.dy*s.dt), ent.w, ent.h, 0, ent.dy*s.dt)
    ent.y = math.max(unpack(moves.y))
  end
  
  yCollided = entCol or tileCol

  s.bump:update(ent, ent.x, ent.y)
  
  return xCollided, yCollided
end

-- the module
return setmetatable({new = new, isTouchingSolid = isTouchingSolid, move = move},
	{__call = function(_, ...) return new(...) end})