local ffi = require "ffi"

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

-- tilecollider functions
local g = function(state, x, y)
  if y <= 0 then y = 1 end
  return state.tileinfo[ state.worldLayer.data[(y-1)*state.l.width+x] ]
end

local c = function(state, ent, side, tile, x, y, dx, dy)
  if tile.platform then
    return side == 'bottom' and ent.y+ent.h <= (y-1)*state.l.tileheight and ent.y+ent.h+dy > (y-1)*state.l.tileheight
  end
  
  return tile.solid
end

function newBumpFilter(state)
  local gs = state
  return function(item, other)
    item = gs.entities[item]
    other = gs.entities[other]
    local other_type = ffi.string(other.type)
    if item.collision == nil then return nil end
    if item.collision[other_type] == nil then return nil end
    return ffi.string(item.collision[other_type])
  end
end

local mod = {}

mod.init = function(str_level)
  local err
  
  local state = {
    entities = nil,
    edata = {},
    red_coins = {found = 0, sum = 0},
    events = {},
    playerNum = nil,
    removedEnts = {}, 
    worldLayer = nil,
    tileinfo = {},
    camera = nil,
    goal_time = nil,
    l = nil, -- level
    col = nil, -- tilecollider
    bump = nil, -- bump
    dt = nil,
    time = 0,
    media = {},
    cvars = {},
    ent_handlers = EntHandlers,
  }  
  
  state.bumpfilter = newBumpFilter(state)
  state.entities = ffi.new("entity_t[1024]")
  
  local cvar_table = {
    {"p_gravity", 625},
    {"p_speed", 170},
    {"p_terminalvel", 230},
    {"p_accel", 175},
    {"p_skidaccel", 420},
    {"p_airaccel", 190},
    {"p_turnairaccel", 325},
    {"p_airfriction", 100},
    {"p_groundfriction", 300},
    {"p_jumpheight", -290},
    {"p_speedjumpbonus", -45},
    {"p_pogojumpheight", -350},
    {"p_doublejumpheight", -245},
    {"p_earlyjumpendmodifier", 0.5},
    {"p_wallslidespeed", 45},
    {"p_walljumpx", 95},
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
    return nil, 'Could not parse map JSON'
  end
  
  state.l.backgroundcolor = parse_color(state.l.backgroundcolor)
  
  for _, v in ipairs(state.l.tilesets) do
    for i = v.firstgid, v.firstgid + v.tilecount do
      state.tileinfo[i] = TileTypes[v.name][i-v.firstgid]
    end
  end
  
  for _, layer in ipairs(state.l.layers) do
    if layer.name == "world" and layer.type == "tilelayer" then
      state.worldLayer = layer
    end
    
    if layer.type == "objectgroup" then
      for _, obj in ipairs(layer.objects) do
        local ent = Entity.new(state, obj.type, obj.x, obj.y - obj.height, obj.width, obj.height)
        if state.ent_handlers[obj.type].spawn then state.ent_handlers[obj.type].spawn(state, ent) end
      end
    end
  end
  
  -- spawn tile entities and take them out of the map
  for i,v in ipairs(state.worldLayer.data) do
    if state.tileinfo[v] then
      if state.tileinfo[v].tile_entity ~= nil then
        state.worldLayer.data[i] = 0
        local classname = state.tileinfo[v].tile_entity        
        local ent = Entity.new(state, state.tileinfo[v].tile_entity, ((i-1)%state.l.width) * state.l.tilewidth, floor(i/state.l.width)*state.l.tileheight, state.l.tilewidth, state.l.tileheight)
        if state.ent_handlers[classname].spawn then state.ent_handlers[classname].spawn(state, ent) end
      end
    end
  end
  
  for i,v in pairs(state.ent_handlers) do
    if v.init then v.init(state) end
  end

  return state
end

mod.step = function(state, dt)
  for k,v in pairs(state.removedEnts) do state.removedEnts[k]=nil end
  state.events = {}
  
  state.dt = dt
  state.time = state.time + dt
  
  local ent = nil
  for i, ent in Entity.iterActive(state.entities) do
    if state.ent_handlers[ent.classname].think ~= nil then
      state.ent_handlers[ent.classname].think(state, ent, dt)
    end
  end
end

mod.addCommand = function(state, num, command)
  state.entities[num].command = command
end

mod.addEvent = function(state, event)
  state.events[#state.events+1] = event
end

mod.spawnPlayer = function(state)
  local spawnPoint = nil
  for i, ent in Entity.iterActive(state.entities) do
    if ent.classname == "player_start" then
      spawnPoint = ent
      break
    end
  end
  
  local ent = Entity.new(state, "player", spawnPoint.x, spawnPoint.y, 8, 22)
  if state.ent_handlers[ent.classname].spawn then state.ent_handlers[ent.classname].spawn(state, ent) end
  
  state.cam:lookAt(spawnPoint.x, spawnPoint.y)  
  
  return ent.number
end

mod.removeEntity = function(gs, num)
  local ent = gs.entities[num]
  -- FIXME: this maybe shouldnt even be getting called?
  if ent == nil then
    return
  end
  
  if gs.bump:hasItem(num) then
    gs.bump:remove(num)
  end
  gs.entities[ent.number].in_use = false
  gs.removedEnts[#gs.removedEnts+1] = num
end

local removeEntity = mod.removeEntity

mod.mergeState = function(gs, ns)
  gs.time = ns.time
  gs.dt = ns.dt
  
  for k, v in pairs(ns) do
    if type(gs.s[k]) ~= 'table' then
      gs.s[k] = v
    end
  end
  
  if ns.red_coins ~= nil then
    gs.red_coins = ns.red_coins
  end
  
  if ns.entities ~= nil then
    for ent_number = 1, 1023 do -- FIXME: hardcoded value
      local new_ent = ns.entities[ent_number]
      if new_ent == nil then
        if gs.entities[ent_number] ~= nil then
          removeEntity(gs, ent_number)
        end
      else
        if gs.entities[ent_number] == nil then
          local ent = Entity.new(gs, new_ent.classname, new_ent.x, new_ent.y, new_ent.w, new_ent.h)
          if gs.ent_handlers[ent.classname].spawn then gs.ent_handlers[ent.classname].spawn(gs, ent) end
        end
        for k,v in pairs(new_ent) do
          gs.entities[ent_number][k] = v
        end
      end
    end
  end
end

-- the module
return mod