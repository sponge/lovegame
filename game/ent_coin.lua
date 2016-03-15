local ffi = require 'ffi'

local Tiny = require 'game/tiny'

ffi.cdef [[
  typedef struct {
    uint16_t number;
    bool in_use;
    uint8_t class;
    float x, y;
    int w, h, drawx, drawy;
    etype_t type;
  } ent_coin_t;
]]

local Entity = require 'game/entity'

local e = {}

e.init = function(s)
  if love.graphics then
    s.media.coin = love.graphics.newImage("base/coin.png")
    s.media.coin:setFilter("nearest", "nearest")

    s.media.coin_frames = {}
    local f = s.media.coin_frames
    local w, h = s.media.coin:getDimensions()
    for i=0, w/16 do
      f[#f+1] = love.graphics.newQuad(16*i,  0, 16, h, w, h)
    end
  end
  
  if love.audio then
    s.media.snd_coin = love.audio.newSource("base/coin.wav", "static")
  end
end

e.spawn = function(s, ent)
  ent.type = ffi.C.ET_PLAYER_TRIGGER
  ent.w = 12
  ent.x = ent.x + 2
end

e.think = function(s, ent, dt)
  
end

e.draw = function(s, ent)
  local i = (math.floor(s.time * 8) % 8) + 1
  love.graphics.draw(s.media.coin, s.media.coin_frames[i], ent.x - 2, ent.y, 0, 1, 1)
end

e.collide = function(gs, ent, col)
  local GameFSM = require 'game/gamefsm'
  
  if col.item.classname ~= 'player' then
    return
  end
  
  Tiny.addEntity(gs.world, {event = 'sound', name = 'coin'})
  
  gs.entities[col.item.number].coins = gs.entities[col.item.number].coins + 1
  
  Tiny.removeEntity(gs.world, ent)
end

return e