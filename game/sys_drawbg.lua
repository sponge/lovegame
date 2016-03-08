local class = require "game/30log"
local tiny = require "game/tiny"

local DrawBackgroundSystem = tiny.system(class "DrawBackgroundSystem")

function DrawBackgroundSystem:init(gs)
  for _, v in ipairs(gs.l.tilesets) do
    -- load all backgrounds used in the map
    if gs.l.properties.background ~= nil then
      gs.media.bg = love.graphics.newImage(gs.l.properties.background)
      gs.media.bg:setFilter("linear", "nearest")
    end
  end
end

function DrawBackgroundSystem:update()
  self:draw()
end

function DrawBackgroundSystem:draw()
  local gs = self.world.gs
  love.graphics.clear(gs.l.backgroundcolor)
  
  cminx, cminy = gs.cam:worldCoords(0,0)
  cmaxx, cmaxy = gs.cam:worldCoords(1920, 1080)

  if gs.media.bg then
    gs.cam:attach()
    local x = cminx * 0.5
    while x < cmaxx do
      love.graphics.draw(gs.media.bg, x, gs.l.height*gs.l.tileheight - gs.media.bg:getHeight())
      x = x + gs.media.bg:getWidth()
    end
    gs.cam:detach()
  end
end

return DrawBackgroundSystem