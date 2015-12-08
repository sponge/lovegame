local json = require "dkjson"
local Camera = require "camera"
local TileCollider = require "tilecollider"
local Entity = require "entity"

-- Collision detection function.
-- Checks if a and b overlap.
-- w and h mean width and height.
-- local function CheckCollision(ax1,ay1,aw,ah, bx1,by1,bw,bh)
--   local ax2,ay2,bx2,by2 = ax1 + aw, ay1 + ah, bx1 + bw, by1 + bh
--   return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
-- end

local map_funcs = {

}

local ent_funcs = {
  player = require 'ent_player',
  
  player_start = {
    think = nil,
    draw = nil
  }
}

-- tilecollider functions
local g = function(state, x, y)
  return state.s.worldLayer.data[(y-1)*state.l.width+x]
end

local c = function(state, side, tile, x, y)
  if tile > 0 then
    return true
  end
  
  return false
end

local function init(str_level)
  local err

  local lc = {
    s = {entities = {}, worldLayer = nil}, -- serializable state (network?)
    playerEnt = nil,
    camera = nil,
    l = nil, -- level
    col = nil -- tilecollider
  }

  lc.l, _, err = json.decode(str_level, 1, nil)
  lc.cam = Camera(0, 0, 4)
  
  if err ~= nil then
    game_err("Error while loading map json")
    return
  end
  
  local spawnPoint = nil
  
  for _, layer in ipairs(lc.l.layers) do
    if layer.name == "world" and layer.type == "tilelayer" then
      lc.s.worldLayer = layer
    end
    
    if layer.type == "objectgroup" then
      for _, obj in ipairs(layer.objects) do
        local ent = Entity.new(obj.type, obj.x, obj.y - obj.height, obj.width, obj.height)
        ent.think = map_funcs[obj.properties.think] or ent_funcs[obj.type].think
        ent.draw = map_funcs[obj.properties.draw] or ent_funcs[obj.type].draw
        table.insert(lc.s.entities, ent)
        if ent.className == "player_start" then
          spawnPoint = ent
        end
      end
    end
  end
  
  local player = Entity.new("player", spawnPoint.x, spawnPoint.y, 16, 32)
  player.think = ent_funcs[player.className].think
  player.draw = ent_funcs[player.className].draw
  table.insert(lc.s.entities, player)
  lc.playerEnt = #lc.s.entities
  lc.cam:lookAt(spawnPoint.x, spawnPoint.y)
  
  lc.col = TileCollider(g, lc.l.tilewidth, lc.l.tileheight, c, nil, false)

  return lc
end

local function step(state, dt)
  local ent = nil
  for i = 1, #state.s.entities do
    ent = state.s.entities[i]
    if ent.think ~= nil then
      ent.think(ent, state, dt)
    end
  end
end

-- the module
return { init = init, step = step }