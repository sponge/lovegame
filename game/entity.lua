local ffi = require "ffi"
ffi.cdef [[  
  typedef enum {
    ET_WORLD = 0,
    ET_PLAYER,
    ET_PLAYER_TRIGGER,
    ET_ENEMY,
    ET_MAX,
  } etype_t;
  
  typedef enum {
    CT_CROSS = 0,
    CT_TOUCH,
    CT_SLIDE,
    CT_BOUNCE
  } collisiontype_t;
  
  typedef struct {
    bool left, right, up, down, jump, attack, menu;
  } entcommand_t;
]]

name_lookup = {
  [0] = 'bad',
  'coin',
  'coin_block',
  'goal',
  'goomba',
  'player',
  'player_start',
  'red_coin',
  'turtle',
}

class_lookup = {}
for i, v in pairs(name_lookup) do
  class_lookup[v] = i
end

local ent_mt = {
  __index = function(table, key)
    if key == "classname" then
      if table.in_use == false then
        return "ent_bad"
      else
        return name_lookup[table.class]
      end
    end
  end,
  
  __tostring = function(ent) return "Entity: " .. ent.classname end
}

local keys = {'left','right','up','down','jump','attack','menu'}
local entcommand_mt = {
  __pairs = function(t)
    return pairs(keys)
  end,
  
  __ipairs = function(t)
    return ipairs(keys)
  end,
}
ffi.metatype("entcommand_t", entcommand_mt)

local e = {}

e.new = function(s, classname, x, y, w, h)
  assert(classname and x and y and w and h, "Invalid entity")
  assert(class_lookup[classname], "Couldn't find ent id for entity name ".. classname)
  
  local ent = ffi.new('ent_'.. classname ..'_t')
  pcall(ffi.metatype, 'ent_'.. classname ..'_t', ent_mt)

  ent.in_use = true
  ent.class = class_lookup[classname]
  ent.number = #s.edata+1
  lastentnum = #s.edata+1
  ent.x = x
  ent.y = y
  ent.w = w
  ent.h = h
  
  s.edata[#s.edata+1] = ent
  return ent
end

e.isTouchingSolid = function(s, ent, side)
  local touching = false
  local cols = nil
  
  local x = side == 'right' and 1 or 0
  x = side == 'left' and -1 or x
  
  local y = side == 'up' and -1 or 0
  y = side == 'down' and 1 or y
  
  if side == 'left' then
    _, touching = s.col:leftResolve(s, ent, ent.x+x, ent.y+y, ent.w, ent.h, x, y)
  elseif side == 'right' then
    _, touching = s.col:rightResolve(s, ent, ent.x+x, ent.y+y, ent.w, ent.h, x, y)
  elseif side == 'up' then
    _, touching = s.col:topResolve(s, ent, ent.x+x, ent.y+y, ent.w, ent.h, x, y)
  elseif side == 'down' then
    _, touching = s.col:bottomResolve(s, ent, ent.x+x, ent.y+y, ent.w, ent.h, x, y)
  end
  
  if not touching then
    local bumpx, bumpy
    bumpx, bumpy, cols = s.bump:check(ent.number, ent.x+x, ent.y+y, s.bumpfilter)
    touching = ((side == 'left' or side == 'right') and bumpx == ent.x) or ((side == 'up' or side == 'down') and bumpy == ent.y)
  end
  return touching, cols
end

e.move = function(s, ent)
  local xCols, yCols, len = {}, {}, nil
  local moves = {x = {0,0}, y={0,0}}
  local entCol, tileCol = false
  local xCollided, yCollided = false
  
  moves.x[1], _, xCols, len = s.bump:check(ent.number, ent.x + (ent.dx*s.dt), ent.y, s.bumpfilter)
  for i=1, len do
    local col = xCols[i]
    local other = s.edata[col.other]
    col.item = ent
    col.other = other
    if s.ent_handlers[ent.classname].collide then s.ent_handlers[ent.classname].collide(s, ent, col) end
    if s.ent_handlers[other.classname].collide then s.ent_handlers[other.classname].collide(s, other, col) end
    entCol = ent.x == moves.x[1]
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
  
  s.bump:update(ent.number, ent.x, ent.y)
  
  -- check y next
  entCol = false
  tileCol = false
  
  _, moves.y[1], yCols, len = s.bump:check(ent.number, ent.x, ent.y + (ent.dy*s.dt), s.bumpfilter)
  for i=1, len do
    local col = yCols[i]
    local other = s.edata[col.other]
    col.item = ent
    col.other = other
    if s.ent_handlers[ent.classname].collide then s.ent_handlers[ent.classname].collide(s, ent, col) end
    if s.ent_handlers[other.classname].collide then s.ent_handlers[other.classname].collide(s, other, col) end
    entCol = ent.y == moves.y[1]
  end
  
  if ent.dy > 0 then
    moves.y[2], tileCol = s.col:bottomResolve(s, ent, ent.x, ent.y + (ent.dy*s.dt), ent.w, ent.h, 0, ent.dy*s.dt)
    ent.y = math.min(unpack(moves.y))
  elseif ent.dy < 0 then
    moves.y[2], tileCol = s.col:topResolve(s, ent, ent.x, ent.y + (ent.dy*s.dt), ent.w, ent.h, 0, ent.dy*s.dt)
    ent.y = math.max(unpack(moves.y))
  end
  
  yCollided = entCol or tileCol

  s.bump:update(ent.number, ent.x, ent.y)
  
  return xCollided, yCollided, xCols, yCols
end

e.hurt = function(s, ent, amt, inflictor)
  if not ent.can_take_damage then
    return
  end
  
  if s.ent_handlers[ent.classname] == nil or s.ent_handlers[ent.classname].take_damage == nil then
    return
  end
  
  s.ent_handlers[ent.classname].take_damage(s, ent, amt, inflictor)
end

e.iterActive = function(t)
  local i = 0
  return function()
    repeat
      i = i + 1
      if t == nil or t[i] == nil then
        return nil
      end
    until t[i].in_use == true or i > 1023
    
    if i < 1024 then
      return i, t[i]
    end
  end
end
-- the module
return setmetatable(e,
	{__call = function(_, ...) return new(...) end})