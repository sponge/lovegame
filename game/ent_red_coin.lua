local ffi = require 'ffi'

local Entity = require 'game/entity'

ffi.cdef [[
  typedef struct {
    uint16_t number;
    bool in_use;
    uint8_t class;
    float x, y;
    int w, h, drawx, drawy;
    etype_t type;
  } ent_red_coin_t;
]]

local e = {}

e.init = function(s)
  if love.graphics then
    s.media.red_coin = love.graphics.newImage("base/red_coin.png")
    s.media.red_coin:setFilter("nearest", "nearest")

    s.media.red_coin_frames = {}
    local f = s.media.red_coin_frames
    local w, h = s.media.red_coin:getDimensions()
    for i=0, w/16 do
      f[#f+1] = love.graphics.newQuad(16*i,  0, 16, h, w, h)
    end
  end
  
  if love.audio then
    s.media.snd_red_coin = love.audio.newSource("base/cleared.wav", "static")
  end
end

e.spawn = function(s, ent)
  ent.type = ffi.C.ET_PLAYER_TRIGGER
  ent.w = 12
  ent.x = ent.x + 2
  s.bump:add(ent.number, ent.x, ent.y, ent.w, ent.h)
  s.red_coins.sum = s.red_coins.sum + 1
end

e.think = function(s, ent, dt)
  
end

e.draw = function(s, ent)
  local i = (math.floor(s.time * 8) % 8) + 1
  love.graphics.draw(s.media.red_coin, s.media.red_coin_frames[i], ent.x - 2, ent.y, 0, 1, 1)
end

e.collide = function(s, ent, col)
  local GameFSM = require 'game/gamefsm'
  
  if col.item.classname ~= 'player' then
    return
  end
  
  GameFSM.addEvent(s, {type = 'sound', name = 'red_coin'})
  
  s.red_coins.found = s.red_coins.found + 1
  
  GameFSM.removeEntity(s, ent.number)
end

return e