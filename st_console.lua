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
  if key == "pageup" then
    if love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt") then
      Console.scroll_offset = 1
    else
      Console.scroll_offset = math.max(1, Console.scroll_offset - 6)
    end
  elseif key == "pagedown" then
    if love.keyboard.isDown("lalt") or love.keyboard.isDown("lalt") then
      Console.scroll_offset = #Console.lines
    else
      Console.scroll_offset = math.min(#Console.lines, Console.scroll_offset + 6)
    end
  elseif key == "up" then
    input = Console:movehistory(-1)
  elseif key == "down" then
    input = Console:movehistory(1)
  elseif key == "return" or key == "kpenter" then
    print("> " .. input)
    Console:command(input)
    if #input > 0 then
      Console:addhistory(input)
      Console.history_pos = #Console.history+1
    end
    input = ''
  elseif key == "backspace" and (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")) then
    for i= #input - 1, 1, -1 do
      if (string.sub(input, i, i) == " ") then
        input = string.sub(input, 1, i)
        break
      end
      
      if i == 1 then
        input = ''
      end
    end
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
  love.graphics.print("> ", x, y)
  local xofs = font:getWidth("> ")
  love.graphics.print(input, x+xofs, y)
  xofs = xofs + font:getWidth(input)
  if love.timer.getTime()*2 % 2 > 1 then
    love.graphics.print('|', x+xofs, y-2)
  end
  
  y = y - font:getHeight() - 5
  
  if Console.scroll_offset ~= #Console.lines then
    local caratW = font:getWidth("^ ")
    local caratX = x
    love.graphics.setColor(255, 0, 0, 255)
    while caratX < w do
      love.graphics.print("^ ", caratX, y+5)
      caratX = caratX + caratW
    end
    y = y - font:getHeight()
    love.graphics.setColor(255, 255, 255, 255)
  end

  for i = Console.scroll_offset, 1, -1 do
    if y < 0 then break end
    love.graphics.print(Console.lines[i], x, y)
    y = y - font:getHeight()
  end
end

return scene