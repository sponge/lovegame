local Gamestate = require "gamestate"
local InputManager = require "input"

local scene = {}

function scene:enter(from, gs)
  collectgarbage("collect")
  self.time_in_scene = 0
  self.gs = gs
end

function scene:leave()
  self.gs = nil
end

function scene:keypressed(key, code, isrepeat)
  local inputs = InputManager.getInputs()
  if inputs.jump then
    Gamestate.pop()
  end
end

function scene:gamepadpressed(pad, button)
  local inputs = InputManager.getInputs()
  if inputs.jump then
    Gamestate.pop()
  end
end

function scene:update(dt)
  self.time_in_scene = self.time_in_scene + dt
  if self.time_in_scene > 5 then
    Gamestate.pop()
    return
  end
end

function scene:draw()   
  local width, height = love.graphics.getDimensions()
  love.graphics.clear(39, 35, 66, 255)
  love.graphics.setColor(209, 201, 32, 255)
  love.graphics.rectangle("fill", 0, height*0.25, width, height*0.5)

  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.printf(self.gs.l.properties.title, 0, height*0.4, width/4, "center", 0, 4, 4)
  love.graphics.printf("a level by", 0, height*0.49, width, "center", 0, 1, 1)
  love.graphics.printf(self.gs.l.properties.author, 0, height*0.5, width/3, "center", 0, 3, 3)

  love.graphics.setColor(255, 255, 255, 255)
end

return scene