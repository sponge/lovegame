local class = require "game/30log"
local tiny = require "game/tiny"

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

local DrawBackgroundSystem = tiny.system(class "DrawBackgroundSystem")

function DrawBackgroundSystem:init(gs)
  for _, v in ipairs(gs.l.tilesets) do
    -- load all backgrounds used in the map
    if gs.l.properties.background ~= nil then
      gs.media.bg = love.graphics.newImage(gs.l.properties.background)
      gs.media.bg:setFilter("linear", "nearest")
    end
  end
  
  gs.l.backgroundcolor = parse_color(gs.l.backgroundcolor)
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