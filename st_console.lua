local UTF8 = require("utf8")
local Gamestate = require "gamestate"
local Console = require 'game/console'

local scene = {from = nil}

local input = ''
local font = love.graphics.newFont(12)

function scene:enter(from)
  self.from = from
  love.keyboard.setKeyRepeat(true)
end

function scene:leave()
  love.keyboard.setKeyRepeat(false)
end

function scene:textinput(t)
  input = input .. t
end

function scene:keypressed(key, code, isrepeat)
  if key == "return" or key == "kpenter" then
    print("> " .. input)
    Console:command(input)
    input = ''
  elseif key == "backspace" then
    -- get the byte offset to the last UTF-8 character in the string.
    local byteoffset = UTF8.offset(input, -1)

    if byteoffset then
      -- remove the last UTF-8 character.
      -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
      input = string.sub(input, 1, byteoffset - 1)
    end
  end
end

function scene:update(dt)
  if self.from.update ~= nil then
    self.from:update(dt)
  end
end

function scene:draw()
  love.graphics.setFont(font)
  local w, h = love.graphics.getDimensions()
  local con_height = math.floor(h/2)
  
  self.from:draw()
  
  love.graphics.setColor(0,0,0,200)
  love.graphics.rectangle('fill', 0, 0, w, con_height)
  love.graphics.setColor(255,255,255,255)
  
  local x = 10
  local y = con_height - font:getHeight() - 5
  love.graphics.print(">", x, y)
  love.graphics.print(input, x+20, y)
  y = y - font:getHeight() - 5

  for i = #Console.lines, 1, -1 do
    if y < 0 then break end
    love.graphics.print(Console.lines[i], x, y)
    y = y - font:getHeight()
  end
end

return scene