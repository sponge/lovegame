local GNet = require 'gamenet'
local Smallfolk = require 'smallfolk'
local Console = require 'game/console'
local GameState = require 'gamestate'
local GameFSM = require 'game/gamefsm'
local Camera = require 'game/camera'
local InputManager = require 'input'
local Easing = require 'game/easing'

local st_console = require 'st_console'
local st_debug = require 'st_debug'
local st_levelintro = require 'st_levelintro'

local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min

local gs = {}
local currmap = nil

local spritebatches = {}
local tileInfo = {}

local scene = {}
local playerNum = nil
local camLockY = nil
local canvas = nil

local smoothFunc = Camera.smooth.damped(3)

function scene:enter(current, mapname, mpdata)
  local err = nil
  
  if mpdata ~= nil then
    self.mpdata = mpdata
    gs = mpdata.gs
    playerNum = mpdata.ent_number
    assert(playerNum > 0)
  else
    local level_json, _ = love.filesystem.read(mapname)
  
    currmap = mapname
    gs = GameFSM.init(level_json, require "game/gamefsm_cb")
    
    playerNum = GameFSM.spawnPlayer(gs)
    
    GameState.push(st_levelintro, gs)
    
    for _, v in pairs(gs.cvars) do
      Console:registercvar(v)
    end
  end
  
  currgame = gs -- global for the debugger
  
  canvas = love.graphics.newCanvas(1920, 1080)
  
  -- load all graphics used in the map
  for _, v in ipairs(gs.l.tilesets) do
    local x, y = nil
    gs.media[v.name] = love.graphics.newImage(v.image)
    gs.media[v.name]:setFilter("linear", "nearest")
    spritebatches[v.name] = love.graphics.newSpriteBatch(gs.media[v.name], 1024)
    local tw = (v.imagewidth - v.margin) / (v.tilewidth + v.spacing)
    for i = v.firstgid, v.firstgid + v.tilecount do
      x = ( (i-v.firstgid+1) * (v.tilewidth+v.spacing) ) % (v.imagewidth - v.margin) + v.margin
      y = math.floor((i-v.firstgid+1) / tw) * (v.tileheight + v.spacing) + v.margin
      tileInfo[i+1] = { name = v.name, quad = love.graphics.newQuad(x, y, v.tilewidth, v.tileheight, v.imagewidth, v.imageheight) }
    end
  end
  
  -- load all backgrounds used in the map
  if gs.l.properties.background ~= nil then
    gs.media.bg = love.graphics.newImage(gs.l.properties.background)
    gs.media.bg:setFilter("linear", "nearest")
  end
  
  gs.cam:lookAt(gs.s.entities[playerNum].x, gs.s.entities[playerNum].y)
  camLockY = gs.cam.y
end

function scene:leave()
  for i, v in pairs(spritebatches) do
    spritebatches[i] = nil
  end
  
  for i, v in pairs(gs.media) do
    gs.media[i] = nil
  end
  
  spritebatches = {}
  gs = {}
  currgame = {}
  tileInfo = {}
  canvas = nil
  love.audio.stop()
  if self.mpdata then
    self.mpdata.peer:disconnect()
    GNet.service(self.mpdata)
    self.mpdata = nil
  end
  playerNum = nil
end

function scene:update(dt)
  -- add commands before stepping
  local usercmd = InputManager.getInputs()
  
  if GameState.current() ~= st_console then
    if usercmd.menu then
      gs.event_cb(gs, {type = 'error', message = 'Game exited'})
      return
    end
    
    if not self.mpdata then
      GameFSM.addCommand(gs, playerNum, usercmd)
    else
      self.mpdata.peer:send( string.char(4) .. Smallfolk.dumps(usercmd), 0, "unreliable")
    end
  end
  
  if self.mpdata then
    GNet.service(self.mpdata)
  end
  
  if not self.mpdata or mp_predict.int > 0 then
    GameFSM.step(gs, dt)
  end
end

function scene:draw()
  local width, height = canvas:getDimensions()
  
  love.graphics.setCanvas(canvas)
  love.graphics.clear(gs.l.backgroundcolor)
  
  local player = gs.s.entities[playerNum]
  
  if math.abs(player.last_ground_y - camLockY) > 48 then
    camLockY = player.last_ground_y
  end
  
  gs.cam:lockX(player.x + math.floor(player.dx/2), smoothFunc)
  gs.cam:lockY(camLockY, smoothFunc)
  gs.cam:lockWindow(player.x, player.y, width/2 - 100, width/2 + 100, 100, height - 300)
  
  local cminx, cminy = gs.cam:worldCoords(0,0)
  local cmaxx, cmaxy = gs.cam:worldCoords(width, height)
  
  if cminx <= 0 then
    gs.cam:move(math.abs(cminx), 0)
  elseif cmaxx > gs.l.width * gs.l.tilewidth then
    gs.cam:move(0 - (cmaxx - (gs.l.width * gs.l.tilewidth)), 0)
  end
  
  if cminy <= 0 then
    gs.cam:move(0, math.abs(cminy))
  elseif cmaxy > gs.l.height * gs.l.tileheight then
    gs.cam:move(0, 0 - (cmaxy - (gs.l.height * gs.l.tileheight)))
  end
  
  cminx, cminy = gs.cam:worldCoords(0,0)
  cmaxx, cmaxy = gs.cam:worldCoords(width, height)
    
  for _, batch in pairs(spritebatches) do
    batch:clear()
  end
  
  gs.cam:attach()
  
  for _, layer in pairs(gs.l.layers) do
    local minx = math.max(1, math.floor(cminx/16) )
    local maxx = math.min(layer.width, math.ceil(cmaxx/16) )
    local miny = math.max(1, math.floor(cminy/16) )
    local maxy = math.min(layer.height, math.ceil(cmaxy/16) )
    
    if layer.type == "tilelayer" then
      for x = minx, maxx do
        for y = miny, maxy do
          local id = layer.data[(y-1)*layer.width+x]
          if id > 0 then
            local tile = tileInfo[id]
            spritebatches[tile.name]:add(tile.quad, (x-1)*16, (y-1)*16)
          end
        end
      end
    end
    
  end
  
  if gs.media.bg then
    local x = cminx * 0.5
    while x < cmaxx do
      love.graphics.draw(gs.media.bg, x, gs.l.height*gs.l.tileheight - gs.media.bg:getHeight())
      x = x + gs.media.bg:getWidth()
    end
  end
  
  for _, batch in pairs(spritebatches) do
    love.graphics.draw(batch)
  end
  
  local ent = nil
  for i = 1, 1024 do --FIXME: hardcoded value
    ent = gs.s.entities[i]
    if ent ~= nil and gs.ent_handlers[ent.classname].draw ~= nil then
      gs.ent_handlers[ent.classname].draw(gs, ent)
      if ent.dbg then
        love.graphics.setColor(255,0,0,255)
        love.graphics.rectangle("fill", ent.x, ent.y, ent.w, ent.h)
        love.graphics.setColor(255,255,255,255)
        if type(ent.dbg) ~= 'boolean' then
          love.graphics.print(tostring(ent.dbg), ent.x, ent.y)
        end
      end
    end
  end

  gs.cam:detach()
  
  love.graphics.setCanvas()
  
  local winw, winh = love.graphics.getDimensions()
  local sf = winw/winh < width/height and winw/width or winh/height
  local x, xoff = winw/2, width/2
  if GameState.current() == st_debug then
    x, xoff = 0
  end
  
  local y = winh/2
  if gs.s.goal_time ~= nil and gs.time + 1.5 >= gs.s.goal_time then
    y = Easing.inBack(gs.time - gs.s.goal_time + 1.5, winh/2, winh/2, 0.6)
  end
  
  love.graphics.draw(canvas, x, y, 0, sf, sf, xoff, height/2)
  
  love.graphics.setColor(0,0,0,100)
  love.graphics.rectangle("fill", 90, winh - 60, 320, 60)
  love.graphics.setColor(255,255,255,255)
  
  love.graphics.printf("HEALTH", 100, winh - 50, 100, "center")
  love.graphics.printf("COINS", 200, winh - 50, 100, "center")
  love.graphics.printf("RED COINS", 300, winh - 50, 100, "center")
  love.graphics.printf(player.health, 100, winh - 25, 100, "center")
  love.graphics.printf(player.coins, 200, winh - 25, 100, "center")
  love.graphics.printf(gs.s.red_coins.found ..' / '.. gs.s.red_coins.sum, 300, winh - 25, 100, "center")

end

return scene
