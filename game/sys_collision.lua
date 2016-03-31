local ffi = require "ffi"
local JSON = require "game/dkjson"
local class = require "game/30log"
local Tiny = require "game/tiny"
local TileCollider = require "game/tilecollider"
local Bump = require "game/bump"

local Entity = require "game/entity"

-- tilecollider functions
local g = function(gs, x, y)
  if y <= 0 then y = 1 end
  return gs.tileinfo[ gs.worldLayer.data[(y-1)*gs.l.width+x] ]
end

local c = function(gs, ent, side, tile, x, y, dx, dy)
  if tile.platform then
    return side == 'bottom' and ent.y+ent.h <= (y-1)*gs.l.tileheight and ent.y+ent.h+dy > (y-1)*gs.l.tileheight
  end
  
  return tile.solid
end

function newBumpFilter(state)
  local col_types = {}
  col_types[0] = 'cross'
  col_types[1] = 'touch'
  col_types[2] = 'slide'
  col_types[3] = 'bounce'
  
  local gs = state
  return function(item, other)
    if item == nil or other == nil then return nil end -- FIXME: this breaks when removing an ent in sys_numberedent system. should it?
    if item.collision == ffi.C.ET_WORLD and item.collision[other.type] == ffi.C.ET_WORLD then return nil end
    return col_types[ tonumber(item.collision[other.type]) ]
  end
end

local CollisionSystem = Tiny.processingSystem(class "CollisionSystem")
CollisionSystem.think = true
CollisionSystem.filter = Tiny.requireAll('x', 'y', 'w', 'h')

function CollisionSystem:init(gs)
  gs.col = TileCollider(g, gs.l.tilewidth, gs.l.tileheight, c, nil, false)
  gs.bump = Bump.newWorld(64)
  gs.bumpfilter = newBumpFilter(gs)
  
  local mt = {
    __index = function (table, key)
      return {
        num = key,
        solid = true,
        platform = false
      }
    end
  }
  setmetatable(gs.tileinfo, mt)
  
  for _, v in ipairs(gs.l.tilesets) do
    if v.source ~= nil then
      local firstgid = v.firstgid
      local tsx_json, _ = love.filesystem.read('base/maps/' .. v.source)
      v, _, err = JSON.decode(tsx_json, 1, nil)
      v.firstgid = firstgid
    end
    
    if v.tileproperties then
      for k, tile in pairs(v.tileproperties) do
        tile.num = tonumber(k)
        if tile.num > 0 then
          tile.num = tile.num + v.firstgid
        end
        for tilepropkey, tilepropval in pairs(tile) do
          if tilepropval == 'true' then tile[tilepropkey] = true end
          if tilepropval == 'false' then tile[tilepropkey] = false end
        end
        gs.tileinfo[tile.num] = tile
      end
    end
  end
end

function CollisionSystem:process(ent, dt)
  local gs = self.world.gs
  
  if not ent.dx or not ent.dy then
    return
  end

  local cols, colLen = {}, 0
  local newX, newY = ent.x, ent.y
  local destX, destY = ent.x + (ent.dx*gs.dt), ent.y + (ent.dy*gs.dt)
  local moves = {x = {0,0}, y={0,0}}
  
  if not gs.bump:hasItem(ent) then
    return
  end
  
  moves.x[1], moves.y[1], cols, colLen = gs.bump:check(ent, destX, destY, gs.bumpfilter)
  for i=1, colLen do
    local col = cols[i]
    if gs.ent_handlers[ent.classname].collide then gs.ent_handlers[ent.classname].collide(gs, ent, col) end
    if gs.ent_handlers[col.other.classname].collide then gs.ent_handlers[col.other.classname].collide(gs, col.other, col) end
  end
    
  if ent.dx > 0 then
    moves.x[2] = gs.col:rightResolve(gs, ent, destX, ent.y, ent.w, ent.h, ent.dx*gs.dt, 0)
    newX = math.min(unpack(moves.x))
  elseif ent.dx < 0 then
    moves.x[2] = gs.col:leftResolve(gs, ent, destX, ent.y, ent.w, ent.h, ent.dx*gs.dt, 0)
    newX = math.max(unpack(moves.x))
  end
  
  if ent.dy > 0 then
    moves.y[2] = gs.col:bottomResolve(gs, ent, ent.x, destY, ent.w, ent.h, 0, ent.dy*gs.dt)
    newY = math.min(unpack(moves.y))
  elseif ent.dy < 0 then
    moves.y[2] = gs.col:topResolve(gs, ent, ent.x, destY, ent.w, ent.h, 0, ent.dy*gs.dt)
    newY = math.max(unpack(moves.y))
  end
  
  local xCollided = ent.x + (ent.dx*gs.dt) ~= newX
  local yCollided = ent.y + (ent.dy*gs.dt) ~= newY
  
  ent.x = newX
  ent.y = newY
  
  -- don't let them move offscreen, but also don't treat the edge as walls
  if ent.x < 0 then
    ent.x = 0
    xCollided = true
  elseif ent.x+ent.w > gs.l.width*gs.l.tilewidth then
    ent.x = gs.l.width*gs.l.tilewidth - ent.w
    xCollided = true
  end

  gs.bump:update(ent, ent.x, ent.y)

  if gs.ent_handlers[ent.classname].postcollide ~= nil then
    gs.ent_handlers[ent.classname].postcollide(gs, ent, xCollided, yCollided)
  end
end

function CollisionSystem:onAdd(ent)
  if ent.type then
    self.world.gs.bump:add(ent, ent.x, ent.y, ent.w, ent.h)
  end
end

function CollisionSystem:onRemove(ent)
  Tiny.removeEntity(self.world, ent)
  
  if self.world.gs.bump:hasItem(ent) then
    self.world.gs.bump:remove(ent)
  end
end  

return CollisionSystem