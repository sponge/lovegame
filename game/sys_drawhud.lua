-- FIXME: hud should filter on entities so we can eventually do boss fights huds and such
local class = require "game/30log"
local tiny = require "game/tiny"

local DrawHUD = tiny.system(class "DrawHUD")

function DrawHUD:init(gs)
end

function DrawHUD:update()
  self:draw()
end

function DrawHUD:draw()
  local gs = self.world.gs
  local winw, winh = 1920, 1080
  
  local player = gs.entities[gs.playerNum]
  local player_edata = gs.edata[gs.playerNum]

  love.graphics.setColor(0,0,0,100)
  love.graphics.rectangle("fill", 90, winh - 60, 320, 60)
  love.graphics.setColor(255,255,255,255)
  
  love.graphics.printf("HEALTH", 100, winh - 50, 100, "center")
  love.graphics.printf("COINS", 200, winh - 50, 100, "center")
  love.graphics.printf("RED COINS", 300, winh - 50, 100, "center")
  love.graphics.printf(player.health, 100, winh - 25, 100, "center")
  love.graphics.printf(player_edata.coins, 200, winh - 25, 100, "center")
  love.graphics.printf(gs.red_coins.found ..' / '.. gs.red_coins.sum, 300, winh - 25, 100, "center")
end

return DrawHUD