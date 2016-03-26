local ffi = require "ffi"

local CVar = require "game/cvar"
local JSON = require "game/dkjson"
local Entity = require "game/entity"
local EntHandlers = require "game/enthandlers"
local Tiny = require "game/tiny"

ffi.cdef [[
  typedef struct {
    uint16_t number;
    bool in_use;
    uint8_t class;
    uint8_t red_coins_found, red_coins_sum;
    float goal_time;
  } ent_worldstate_t;
]]

local mod = {}

mod.init = function(str_level)
  local err
  
  local gs = {
    entities = {},
    ws = nil,
    player = nil,
    removedEnts = {}, 
    worldLayer = nil,
    tileinfo = {},
    camera = nil,
    l = nil, -- level
    col = nil, -- tilecollider
    bump = nil, -- bump
    world = nil, -- ecs
    dt = nil,
    time = 0,
    media = {},
    cvars = {},
    ent_handlers = EntHandlers,
  }  
  
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
  
  -- FIXME: circular ref, needs to be handled on exit maybe?
  local world = Tiny.world()
  world.gs = gs
  gs.world = world
  
  if err ~= nil then
    return nil, nil, 'Could not parse map JSON'
  end
  
  for _, layer in ipairs(gs.l.layers) do
    -- find the layer named world, this is the layer where everything happens
    if layer.name == "world" and layer.type == "tilelayer" then
      gs.worldLayer = layer
    end
  end
  
  world:add(
    require('game/sys_numberedent')(gs),
    require('game/sys_updatetime')(gs),
    require('game/sys_updateents')(gs),
    require('game/sys_collision')(gs),
    require('game/sys_clientevents')(gs),
    require('game/sys_drawcam')(gs),
    require('game/sys_drawbg')(gs),
    require('game/sys_drawmap')(gs),
    require('game/sys_drawent')(gs),
    require('game/sys_drawhud')(gs)
  )
  
  local ws_ent = Entity.new(gs, 'worldstate')
  gs.ws = ws_ent
    
  -- spawn all objectgroup layers into entities
  for _, layer in ipairs(gs.l.layers) do
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
      local ent = Entity.new(gs, gs.tileinfo[v].tile_entity, ((i-1)%gs.l.width) * gs.l.tilewidth, math.floor(i/gs.l.width)*gs.l.tileheight, gs.l.tilewidth, gs.l.tileheight)
      if gs.ent_handlers[classname].spawn then gs.ent_handlers[classname].spawn(gs, ent) end
    end
  end
  
  -- load all entities we know about (gfx, etc)
  for _,v in pairs(gs.ent_handlers) do
    if v.init then v.init(gs) end
  end

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