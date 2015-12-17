local Strictness = require "game/strictness"
if arg and arg[#arg] ~= "-debug" then
  if not Strictness.is_strict(_G) then Strictness.strict(_G) end
end

local JSON = require "game/dkjson"
local Camera = require "game/camera"
local TileCollider = require "game/tilecollider"
local Entity = require "game/entity"
local TileTypes = require "game/tiletypes"

local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min

local function parse_color(col)
    local rgb = {}
    for pair in string.gmatch(col, "[^#].") do
        local i = tonumber(pair, 16)
        if i then
            table.insert(rgb, i)
        end
    end
    while #rgb < 4 do
        table.insert(rgb, 255)
    end
    return rgb
end

local map_funcs = {

}

local ent_funcs = {
  player_start = {
    init = nil,
    spawn = nil,
    think = nil,
    draw = nil
  },
  
  player = require 'game/ent_player',
  coin = require 'game/ent_coin',
  coin_block = require 'game/ent_coin_block',
}

-- tilecollider functions
local g = function(state, x, y)
  --if x <= 0 then return TileTypes.__oob end
  --if x > state.l.width then return TileTypes.__oob end
  if y <= 0 then y = 1 end
  return state.tileinfo[ state.s.worldLayer.data[(y-1)*state.l.width+x] ]
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
    tileinfo = {},
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
  
  state.l.backgroundcolor = parse_color(state.l.backgroundcolor)
  
  for _, v in ipairs(state.l.tilesets) do
    for i = v.firstgid, v.firstgid + v.tilecount do
      state.tileinfo[i] = TileTypes[v.name][i-v.firstgid]
    end
  end
  
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
  
  -- spawn tile entities and take them out of the map
  for i,v in ipairs(state.s.worldLayer.data) do
    if state.tileinfo[v] then
      if state.tileinfo[v].tile_entity ~= nil then
        state.s.worldLayer.data[i] = 0
        local classname = state.tileinfo[v].tile_entity
        local ent = Entity.new(state.tileinfo[v].tile_entity, (i%state.l.width) * state.l.tilewidth, floor(i/state.l.width)*state.l.tileheight, state.l.tilewidth, state.l.tileheight)
        ent.number = #state.s.entities
        ent.think = ent_funcs[classname].think
        ent.draw = ent_funcs[classname].draw
        table.insert(state.s.entities, ent)
        if ent_funcs[classname].spawn then ent_funcs[classname].spawn(state, ent) end
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