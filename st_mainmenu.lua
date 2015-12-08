local Gamestate = require "gamestate"

local gs = {error = nil}

function gs:leave()
  gs.error = nil
end

function gs:draw()
  local width, height = love.graphics.getDimensions()
  love.graphics.print("Press Enter to continue", width/2, height/2)
  if gs.error ~= nil then
    love.graphics.print(gs.error, width/2, height/2 + 30)
  end
end

function gs:keyreleased(key, code)
  if key == "return" then
    Gamestate.switch(s_game)
  end
end

return gs