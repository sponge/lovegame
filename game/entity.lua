local ffi = require "ffi"
local Tiny = require "game/tiny"

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
    float time;
    bool left, right, up, down, jump, attack, menu;
  } entcommand_t;
]]

name_lookup = {
  [0] = 'bad',
  'worldstate',
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
  assert(classname, "Invalid entity")
  assert(class_lookup[classname], "Couldn't find ent id for entity name ".. classname)
  
  local ent = ffi.new('ent_'.. classname ..'_t')
  pcall(ffi.metatype, 'ent_'.. classname ..'_t', ent_mt)
  
  local num
  for i = 1, #s.entities+1 do
    if s.entities[i] == nil then
      num = i
      break
    end
  end

  ent.in_use = true
  ent.class = class_lookup[classname]
  ent.number = num
  
  if ent.x and ent.y and ent.w and ent.h then
    ent.x = x
    ent.y = y
    ent.w = w
    ent.h = h
  end
  
  Tiny.add(s.world, ent)
  
  Tiny.refresh(s.world)

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
    bumpx, bumpy, cols = s.bump:check(ent, ent.x+x, ent.y+y, s.bumpfilter)
    touching = ((side == 'left' or side == 'right') and bumpx == ent.x) or ((side == 'up' or side == 'down') and bumpy == ent.y)
  end
  return touching, cols
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

-- the module
return setmetatable(e,
	{__call = function(_, ...) return new(...) end})