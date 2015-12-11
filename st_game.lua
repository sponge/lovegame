local GameFSM = require 'game/gamefsm'

local lc = {}

local media = {}
local spritebatches = {}
local tileInfo = {}

local gs = {}
local playerNum = nil

function gs:enter()
  local err = nil
  local level_json, _ = love.filesystem.read("base/maps/testlevel.json")
  
  lc = GameFSM.init(level_json)
  
  -- load all graphics used in the map
  for _, v in ipairs(lc.l.tilesets) do
    media[v.name] = love.graphics.newImage(v.image)
    media[v.name]:setFilter("nearest", "nearest")
    spritebatches[v.name] = love.graphics.newSpriteBatch(media[v.name], 1024)
    local lastgid = v.firstgid + v.tilecount
    for i = v.firstgid, lastgid do
      tileInfo[i+1] = { name = v.name, quad = love.graphics.newQuad((i-v.firstgid+1) * v.tilewidth % v.imagewidth, math.floor((i-v.firstgid+1) * v.tilewidth / v.imagewidth) * v.tileheight, v.tilewidth, v.tileheight, v.imagewidth, v.imageheight) }
    end
  end
  
  playerNum = GameFSM.spawnPlayer(lc)

end

function gs:keyreleased(key)

end

function gs:update(dt)
  -- add commands before stepping
  local usercmd = { left = 0, right = 0, up = 0, down = 0, button1 = false, button2 = false, button3 = false }
  usercmd.button1 = love.keyboard.isDown("z") -- jump
  usercmd.button2 = love.keyboard.isDown("x") -- run
  usercmd.button3 = love.keyboard.isDown("c") -- shoot
  usercmd.left = love.keyboard.isDown("left") and 255 or 0
  usercmd.right = love.keyboard.isDown("right") and 255 or 0
  usercmd.up = love.keyboard.isDown("up") and 255 or 0
  usercmd.down = love.keyboard.isDown("down") and 255 or 0
  
  GameFSM.addCommand(lc, playerNum, usercmd)
  GameFSM.step(lc, dt)
end

function gs:draw()
  
  lc.cam:lookAt(lc.s.entities[playerNum].x, lc.s.entities[playerNum].y)
  
  love.graphics.setColor(168,168,168,255)
  local width, height = love.graphics.getDimensions()
  love.graphics.rectangle("fill", 0, 0, width, height)
  
  love.graphics.setColor(255,255,255,255)
  
  local cminx, cminy = lc.cam:worldCoords(0,0)
  local cmaxx, cmaxy = lc.cam:worldCoords(width, height)
  
  if cminx <= 0 then
    lc.cam:move(math.abs(cminx), 0)
  elseif cmaxx > lc.l.width * lc.l.tilewidth then
    lc.cam:move(0 - (cmaxx - (lc.l.width * lc.l.tilewidth)), 0)
  end
  
  if cminy <= 0 then
    lc.cam:move(0, math.abs(cminy))
  elseif cmaxy > lc.l.height * lc.l.tileheight then
    lc.cam:move(0, 0 - (cmaxy - (lc.l.height * lc.l.tileheight)), 0)
  end
  
  cminx, cminy = lc.cam:worldCoords(0,0)
  cmaxx, cmaxy = lc.cam:worldCoords(width, height)
    
  for _, batch in pairs(spritebatches) do
    batch:clear()
  end
  
  lc.cam:attach()
  
  for _, layer in pairs(lc.l.layers) do
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
  for i = 1, #lc.s.entities do
    ent = lc.s.entities[i]
    if ent.draw ~= nil then
      ent.draw(ent)
    end
  end

  lc.cam:detach()

end

return gs
