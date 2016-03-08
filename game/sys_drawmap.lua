local class = require "game/30log"
local tiny = require "game/tiny"
local JSON = require "game/dkjson"

local DrawMapSystem = tiny.system(class "DrawMapSystem")

function DrawMapSystem:init(gs)
  self.spritebatches = {}
  self.tileinfo = {}
  
  -- load all graphics used in the map
  for _, v in ipairs(gs.l.tilesets) do
    local x, y = nil

    if v.source ~= nil then
      local firstgid = v.firstgid
      local tsx_json, _ = love.filesystem.read('base/maps/' .. v.source)
      v, _, err = JSON.decode(tsx_json, 1, nil)
      v.firstgid = firstgid
    end
      
    gs.media[v.name] = love.graphics.newImage("base/maps/tilesets/" .. v.image)
    gs.media[v.name]:setFilter("linear", "nearest")
    self.spritebatches[v.name] = love.graphics.newSpriteBatch(gs.media[v.name], 1024)
    local tw = (v.imagewidth - v.margin) / (v.tilewidth + v.spacing)
    for i = v.firstgid, v.firstgid + v.tilecount do
      x = ( (i-v.firstgid+1) * (v.tilewidth+v.spacing) ) % (v.imagewidth - v.margin) + v.margin
      y = math.floor((i-v.firstgid+1) / tw) * (v.tileheight + v.spacing) + v.margin
      self.tileinfo[i+1] = { name = v.name, quad = love.graphics.newQuad(x, y, v.tilewidth, v.tileheight, v.imagewidth, v.imageheight) }
    end
  end
end

function DrawMapSystem:update()
  self:draw()
end

function DrawMapSystem:draw()
  local gs = self.world.gs
  
  for _, batch in pairs(self.spritebatches) do
    batch:clear()
  end

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
            local tile = self.tileinfo[id]
            self.spritebatches[tile.name]:add(tile.quad, (x-1)*16, (y-1)*16)
          end
        end
      end
    end
    
  end
  
  gs.cam:attach()
  for _, batch in pairs(self.spritebatches) do
    love.graphics.draw(batch)
  end
  gs.cam:detach()
end

return DrawMapSystem