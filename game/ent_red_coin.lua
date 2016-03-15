local ffi = require 'ffi'

local Entity = require 'game/entity'
local Tiny = require 'game/tiny'

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

e.init = function(gs)
  if love.graphics then
    gs.media.red_coin = love.graphics.newImage("base/red_coin.png")
    gs.media.red_coin:setFilter("nearest", "nearest")

    gs.media.red_coin_frames = {}
    local f = gs.media.red_coin_frames
    local w, h = gs.media.red_coin:getDimensions()
    for i=0, w/16 do
      f[#f+1] = love.graphics.newQuad(16*i,  0, 16, h, w, h)
    end
  end
  
  if love.audio then
    gs.media.snd_red_coin = love.audio.newSource("base/cleared.wav", "static")
  end
end

e.spawn = function(gs, ent)
  ent.type = ffi.C.ET_PLAYER_TRIGGER
  ent.w = 12
  ent.x = ent.x + 2
  gs.red_coins.sum = gs.red_coins.sum + 1
end

e.think = function(gs, ent, dt)
  
end

e.draw = function(gs, ent)
  local i = (math.floor(gs.time * 8) % 8) + 1
  love.graphics.draw(gs.media.red_coin, gs.media.red_coin_frames[i], ent.x - 2, ent.y, 0, 1, 1)
end

e.collide = function(gs, ent, col)  
  if col.item.classname ~= 'player' then
    return
  end
  
  Tiny.addEntity(gs.world, {event = 'sound', name = 'red_coin'})
  
  gs.red_coins.found = gs.red_coins.found + 1
  
  Tiny.removeEntity(gs.world, ent)
end

return e