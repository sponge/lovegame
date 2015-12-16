local Strictness = require "game/strictness"
if arg and arg[#arg] ~= "-debug" then
  if not Strictness.is_strict(_G) then Strictness.strict(_G) end
end

local JSON = require "game/dkjson"
local Camera = require "game/camera"
local TileCollider = require "game/tilecollider"
local Entity = require "game/entity"
local TileTypes = require "game/tiletypes"

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
  player = require 'game/ent_player',
  
  player_start = {
    init = nil,
    spawn = nil,
    think = nil,
    draw = nil
  }
}

-- tilecollider functions
local g = function(state, x, y)
  return TileTypes[ state.s.worldLayer.data[(y-1)*state.l.width+x] ]
end

local c = function(state, ent, side, tile, x, y, dx, dy)
  if tile.platform then
    return side == 'bottom' and ent.y+ent.h <= (y-1)*state.l.tileheight and ent.y+ent.h+dy > (y-1)*state.l.tileheight
  end
  
  return tile.solid
end

local function init(str_level)
  local err

  local state = {
    s = {entities = {}, worldLayer = nil}, -- serializable state (network?)
    camera = nil,
    l = nil, -- level
    col = nil, -- tilecollider
    dt = nil,
    time = 0,
    media = {},
  }

  state.l, _, err = JSON.decode(str_level, 1, nil)
  state.cam = Camera(0, 0, 1920/(16*24)) -- FIXME: use tile sizes correctly, pass in width?
  
  if err ~= nil then
    game_err("Error while loading map JSON")
    return
  end
  
  ent_funcs.player.init(state)
  
  for _, layer in ipairs(state.l.layers) do
    if layer.name == "world" and layer.type == "tilelayer" then
      state.s.worldLayer = layer
    end
    
    if layer.type == "objectgroup" then
      for _, obj in ipairs(layer.objects) do
        local ent = Entity.new(obj.type, obj.x, obj.y - obj.height, obj.width, obj.height)
        ent.number = #state.s.entities
        ent.think = map_funcs[obj.properties.think] or ent_funcs[obj.type].think
        ent.draw = map_funcs[obj.properties.draw] or ent_funcs[obj.type].draw
        table.insert(state.s.entities, ent)
        if ent_funcs[obj.type].spawn then ent_funcs[obj.type].spawn(state, ent) end
      end
    end
  end
  
  state.col = TileCollider(g, state.l.tilewidth, state.l.tileheight, c, nil, false)

  return state
end

local function step(state, dt)
  state.dt = dt
  state.time = state.time + dt
  
  local ent = nil
  for i = 1, #state.s.entities do
    ent = state.s.entities[i]
    if ent.think ~= nil then
      ent.think(state, ent, dt)
    end
  end
end

local function addCommand(state, num, command)
  state.s.entities[num].command = command
end

local function spawnPlayer(state)
  local spawnPoint = nil
  for _, ent in ipairs(state.s.entities) do
    if ent.classname == "player_start" then
      spawnPoint = ent
      break
    end
  end
  
  local ent = Entity.new("player", spawnPoint.x, spawnPoint.y, 10, 22)
  ent.number = #state.s.entities
  ent.think = ent_funcs[ent.classname].think
  ent.draw = ent_funcs[ent.classname].draw
  state.s.entities[ent.number] = ent
  if ent_funcs[ent.classname].spawn then ent_funcs[ent.classname].spawn(state, ent) end
  
  state.cam:lookAt(spawnPoint.x, spawnPoint.y)  
  
  return ent.number
end

-- the module
return { init = init, step = step, addCommand = addCommand, spawnPlayer = spawnPlayer }