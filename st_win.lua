local Console = require "game/console"
local Gamestate = require "gamestate"
local InputManager = require "input"
local st_mainmenu = require "st_mainmenu"

local vid = nil

local gs = {}

function gs:enter()
  collectgarbage("collect")
  
  vid = love.graphics.newVideo("base/youwin.ogv")
  vid:play()
end

function gs:leave()
  vid:pause()
  vid = nil
end

function gs:keypressed(key, code, isrepeat)
  local inputs = InputManager.getInputs()
  if inputs.jump then
    Gamestate.switch(st_mainmenu)
  end
end

function gs:gamepadpressed(pad, button)
  local inputs = InputManager.getInputs()
  if inputs.jump then
    Gamestate.switch(st_mainmenu)
  end
end

function gs:draw()   
  local width, height = love.graphics.getDimensions()
  love.graphics.draw(vid, 0, 0, 0, width/vid:getWidth(), height/vid:getHeight())
  love.graphics.setColor(255, 0, 0, 255)
  love.graphics.printf("YOU WIN!", 0, height*0.2, width/4, "center", 0, 4, 4)
  love.graphics.printf("Press jump to go back to the menu", 0, height*0.3, width, "center", 0, 1, 1)

  love.graphics.setColor(255, 255, 255, 255)
end

return gs