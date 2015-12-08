local GameFSM = require 'gamefsm'

local lc = {}

local media = {}
local spritebatches = {}
local tileInfo = {}

local gs = {}

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
      tileInfo[i+1] = { name = v.name, quad = love.graphics.newQuad(i * v.tilewidth % v.imagewidth, math.floor(i * v.tilewidth / v.imagewidth) * v.tileheight, v.tilewidth, v.tileheight, v.imagewidth, v.imageheight) }
    end
  end

end

function gs:keyreleased(key)

end

function gs:update(dt)
  GameFSM.step(lc, dt)
end

function gs:draw()
  
  lc.cam:lookAt(lc.s.entities[lc.playerEnt].x, lc.s.entities[lc.playerEnt].y)

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
