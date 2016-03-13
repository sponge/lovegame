-- FIXME: this should be a processing system that reads entities from the world instead of gs.entities
local class = require "game/30log"
local tiny = require "game/tiny"
local Entity = require "game/entity"
local Camera = require "game/camera"

local DrawCam = tiny.system(class "DrawCam")

local smoothFunc = Camera.smooth.damped(3)

function DrawCam:init(gs)
  self.camLockY = nil
  gs.cam = Camera(0, 0, 1920/(gs.l.tilewidth*24)) -- FIXME:  pass in width?
end

function DrawCam:update()
  self:draw()
end

function DrawCam:draw()
  local gs = self.world.gs
  local width, height = 1920, 1080
  
  assert(gs.player, "player ent is nil!")
  
  if self.camLockY == nil or math.abs(gs.player.last_ground_y - self.camLockY) > 48 then
    self.camLockY = gs.player.last_ground_y
  end
  
  gs.cam:lockX(gs.player.x + math.floor(gs.player.dx/2), smoothFunc)
  gs.cam:lockY(self.camLockY, smoothFunc)
  gs.cam:lockWindow(gs.player.x, gs.player.y, width/2 - 100, width/2 + 100, 100, height - 300)
  
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
end

return DrawCam