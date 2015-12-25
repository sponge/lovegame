local CVar = require "game/cvar"
local JSON = require "game/dkjson"
local Camera = require "game/camera"
local TileCollider = require "game/tilecollider"
local Bump = require "game/bump"
local Entity = require "game/entity"
local EntHandlers = require "game/enthandlers"
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

local inited_ents = {}

local filter = function(item, other)
  return other.collision
end

-- tilecollider functions
local g = function(state, x, y)
  if y <= 0 then y = 1 end
  return state.tileinfo[ state.s.worldLayer.data[(y-1)*state.l.width+x] ]
end

local c = function(state, ent, side, tile, x, y, dx, dy)
  if tile.platform then
    return side == 'bottom' and ent.y+ent.h <= (y-1)*state.l.tileheight and ent.y+ent.h+dy > (y-1)*state.l.tileheight
  end
  
  return tile.solid
end

local function init(str_level, event_cb)
  local err
  
  assert(type(event_cb) == 'function', "No callback passed into GameFSM.init")

  local state = {
    s = {entities = {}, worldLayer = nil}, -- serializable state (network?)
    tileinfo = {},
    camera = nil,
    l = nil, -- level
    col = nil, -- tilecollider
    bump = nil, -- bump
    dt = nil,
    time = 0,
    media = {},
    cvars = {},
    event_cb = event_cb,
    bumpfilter = filter,
  }
  
  local cvar_table = {
    {"p_gravity", 375},
    {"p_speed", 170},
    {"p_terminalvel", 300},
    {"p_accel", 150},
    {"p_skidaccel", 420},
    {"p_airaccel", 150},
    {"p_turnairaccel", 230},
    {"p_airfriction", 100},
    {"p_groundfriction", 300},
    {"p_jumpheight", -190},
    {"p_speedjumpbonus", -15},
    {"p_pogojumpheight", -245},
    {"p_doublejumpheight", -145},
    {"p_earlyjumpendmodifier", 0.6},
    {"p_headbumpmodifier", 0.5},
    {"p_wallslidespeed", 45},
    {"p_walljumpx", 100},
  }
  
  for _, v in ipairs(cvar_table) do
    local cvar = CVar.new(v[1], v[2])
    state.cvars[cvar.name] = cvar
  end

  state.l, _, err = JSON.decode(str_level, 1, nil)
  state.cam = Camera(0, 0, 1920/(state.l.tilewidth*24)) -- FIXME:  pass in width?
  
  state.col = TileCollider(g, state.l.tilewidth, state.l.tileheight, c, nil, false)
  state.bump = Bump.newWorld(64)
  
  if err ~= nil then
    game_err("Error while loading map JSON")
    return
  end
    
  EntHandlers.player.init(state)
  
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
        ent.number = #state.s.entities+1
        state.s.entities[ent.number] = ent
        if EntHandlers[ent.classname].spawn then EntHandlers[ent.classname].spawn(state, ent) end
      end
    end
  end
  
  -- spawn tile entities and take them out of the map
  for i,v in ipairs(state.s.worldLayer.data) do
    if state.tileinfo[v] then
      if state.tileinfo[v].tile_entity ~= nil then
        state.s.worldLayer.data[i] = 0
        local classname = state.tileinfo[v].tile_entity        
        local ent = Entity.new(state.tileinfo[v].tile_entity, ((i-1)%state.l.width) * state.l.tilewidth, floor(i/state.l.width)*state.l.tileheight, state.l.tilewidth, state.l.tileheight)
        ent.number = #state.s.entities+1        
        state.s.entities[ent.number] = ent
        if EntHandlers[ent.classname].spawn then EntHandlers[ent.classname].spawn(state, ent) end
      end
    end
  end
  
  for i,v in pairs(EntHandlers) do
    if v.init then v.init(state) end
  end

  return state
end

local function step(state, dt)
  state.dt = dt
  state.time = state.time + dt
  
  local ent = nil
  for i = 1, 1024 do --FIXME: hardcoded value
    ent = state.s.entities[i]
    if ent ~= nil and EntHandlers[ent.classname].think ~= nil then
      EntHandlers[ent.classname].think(state, ent, dt)
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
  ent.number = #state.s.entities+1
  state.s.entities[ent.number] = ent
  if EntHandlers[ent.classname].spawn then EntHandlers[ent.classname].spawn(state, ent) end
  
  state.cam:lookAt(spawnPoint.x, spawnPoint.y)  
  
  return ent.number
end

-- the module
return { init = init, step = step, addCommand = addCommand, spawnPlayer = spawnPlayer }