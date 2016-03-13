local ffi = require "ffi"

local CVar = require "game/cvar"
local JSON = require "game/dkjson"
local TileCollider = require "game/tilecollider"
local Bump = require "game/bump"
local Entity = require "game/entity"
local EntHandlers = require "game/enthandlers"
local Tiny = require "game/tiny"

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
    item = gs.entities[item]
    other = gs.entities[other]
    if item.collision == ffi.C.ET_WORLD and item.collision[other.type] == ffi.C.ET_WORLD then return nil end
    return col_types[ tonumber(item.collision[other.type]) ]
  end
end

local mod = {}

mod.init = function(str_level)
  local err
  
  local gs = {
    entities = {},
    red_coins = {found = 0, sum = 0},
    player = nil,
    removedEnts = {}, 
    worldLayer = nil,
    tileinfo = {},
    camera = nil,
    goal_time = nil,
    l = nil, -- level
    col = nil, -- tilecollider
    bump = nil, -- bump
    world = nil,
    dt = nil,
    time = 0,
    media = {},
    cvars = {},
    ent_handlers = EntHandlers,
  }  
  
  gs.bumpfilter = newBumpFilter(gs)
  
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
    gs.cvars[cvar.name] = cvar
  end

  gs.l, _, err = JSON.decode(str_level, 1, nil)
  
  gs.col = TileCollider(g, gs.l.tilewidth, gs.l.tileheight, c, nil, false)
  gs.bump = Bump.newWorld(64)
  
  -- FIXME: circular ref, needs to be handled on exit maybe?
  local world = Tiny.world()
  world.gs = gs
  gs.world = world
  
  if err ~= nil then
    return nil, nil, 'Could not parse map JSON'
  end
  
  gs.l.backgroundcolor = parse_color(gs.l.backgroundcolor)
  
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
  
  for _, layer in ipairs(gs.l.layers) do
    if layer.name == "world" and layer.type == "tilelayer" then
      gs.worldLayer = layer
    end
    
    if layer.type == "objectgroup" then
      for _, obj in ipairs(layer.objects) do
        local ent = Entity.new(gs, obj.type, obj.x, obj.y - obj.height, obj.width, obj.height)
        if gs.ent_handlers[obj.type].spawn then gs.ent_handlers[obj.type].spawn(gs, ent) end
      end
    end
  end
  
  -- spawn tile entities and take them out of the map
  for i,v in ipairs(gs.worldLayer.data) do
    if gs.tileinfo[v] and gs.tileinfo[v].tile_entity ~= nil then
      gs.worldLayer.data[i] = 0
      local classname = gs.tileinfo[v].tile_entity        
      local ent = Entity.new(gs, gs.tileinfo[v].tile_entity, ((i-1)%gs.l.width) * gs.l.tilewidth, floor(i/gs.l.width)*gs.l.tileheight, gs.l.tilewidth, gs.l.tileheight)
      if gs.ent_handlers[classname].spawn then gs.ent_handlers[classname].spawn(gs, ent) end
    end
  end
  
  for i,v in pairs(gs.ent_handlers) do
    if v.init then v.init(gs) end
  end
  
  world:add(
    require('game/sys_updatetime')(gs),
    require('game/sys_updateents')(gs),
    require('game/sys_clientevents')(gs),
    require('game/sys_drawcam')(gs),
    require('game/sys_drawbg')(gs),
    require('game/sys_drawmap')(gs),
    require('game/sys_drawent')(gs),
    require('game/sys_drawhud')(gs)
  )

  return gs, world
end

mod.addCommand = function(gs, ent, command)
  ent.command = command
end

mod.spawnPlayer = function(gs)
  local spawnPoint = nil
  
  for ent in pairs(gs.world.entities) do
    if ent.classname == "player_start" then
      spawnPoint = ent
      break
    end
  end
  
  local ent = Entity.new(gs, "player", spawnPoint.x, spawnPoint.y, 8, 22)
  if gs.ent_handlers[ent.classname].spawn then gs.ent_handlers[ent.classname].spawn(gs, ent) end
  
  gs.cam:lookAt(spawnPoint.x, spawnPoint.y)  
  
  return ent
end

mod.removeEntity = function(gs, num)
  local ent = gs.entities[num]
  
  gs.world.removeEntity(gs.world, ent)
  gs.entities[num] = nil
  
  if gs.bump:hasItem(num) then
    gs.bump:remove(num)
  end
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