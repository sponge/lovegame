local Gamestate = require "gamestate"

local gs = {}

function gs:enter()
  collectgarbage("collect")
end

function gs:leave()

end

function gs:update()   

end

return gs