local GameFSM = require 'game/gamefsm'
local Camera = require "game/camera"

local gs = {}

local spritebatches = {}
local tileInfo = {}

local scene = {}
local playerNum = nil
local camLockY = nil
local canvas = nil

function scene:enter(current, mapname)
  local err = nil
  local level_json, _ = love.filesystem.read(mapname)
  
  gs = GameFSM.init(level_json)
  
  canvas = love.graphics.newCanvas(1920, 1080)
  
  -- load all graphics used in the map
  for _, v in ipairs(gs.l.tilesets) do
    local x, y = nil
    gs.media[v.name] = love.graphics.newImage(v.image)
    gs.media[v.name]:setFilter("nearest", "nearest")
    spritebatches[v.name] = love.graphics.newSpriteBatch(gs.media[v.name], 1024)
    local tw = (v.imagewidth - v.margin) / (v.tilewidth + v.spacing)
    for i = v.firstgid, v.firstgid + v.tilecount do
      x = ( (i-v.firstgid+1) * (v.tilewidth+v.spacing) ) % (v.imagewidth - v.margin) + v.margin
      y = math.floor((i-v.firstgid+1) / tw) * (v.tileheight + v.spacing) + v.margin
      tileInfo[i+1] = { name = v.name, quad = love.graphics.newQuad(x, y, v.tilewidth, v.tileheight, v.imagewidth, v.imageheight) }
    end
  end
  
  playerNum = GameFSM.spawnPlayer(gs)
  
  gs.cam:lookAt(gs.s.entities[playerNum].x, gs.s.entities[playerNum].y)
  camLockY = gs.cam.y

end

function scene:keypressed(key)
  if key == 'escape' then
    game_err('Game exited')
    return
  end
end
function scene:update(dt)
  -- add commands before stepping
  local usercmd = { left = 0, right = 0, up = 0, down = 0, button1 = false, button2 = false, button3 = false }
  usercmd.button1 = love.keyboard.isDown("z") -- jump
  usercmd.button2 = love.keyboard.isDown("x") -- run
  usercmd.button3 = love.keyboard.isDown("c") -- shoot
  usercmd.left = love.keyboard.isDown("left") and 255 or 0
  usercmd.right = love.keyboard.isDown("right") and 255 or 0
  usercmd.up = love.keyboard.isDown("up") and 255 or 0
  usercmd.down = love.keyboard.isDown("down") and 255 or 0
  
  GameFSM.addCommand(gs, playerNum, usercmd)
  GameFSM.step(gs, dt)
end

local smoothFunc = Camera.smooth.damped(3)

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
  
  for _, batch in pairs(spritebatches) do
    love.graphics.draw(batch)
  end
  
  local ent = nil
  for i = 1, #gs.s.entities do
    ent = gs.s.entities[i]
    if ent.draw ~= nil then
      ent.draw(gs, ent)
    end
  end

  gs.cam:detach()
  
  love.graphics.setCanvas()
  
  local winw, winh = love.graphics.getDimensions()
  local sf = winw/winh < width/height and winw/width or winh/height
  love.graphics.draw(canvas, winw/2, winh/2, 0, sf, sf, width/2, height/2)

end

return scene
