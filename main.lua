if arg and arg[#arg] ~= "-debug" then
  local Strictness = require "game/strictness"
else
  require("mobdebug").start()
end

require("errhand")

-- globals
_, game_err, socket, currgame, con = nil

local is_server = false
for i, v in ipairs(arg) do
  if v == '-server' then
    is_server = true
    break
  end
end

local Console = require 'game/console'
con = Console -- global for lovebird

Console:init()

local write = io.write
local origprint = print
print = function(...)
   write("[", love.timer.getTime(), "] ")
   origprint(...)
   Console:addline(...)
end

if is_server then
  require "server"
else
  --require("mobdebug").off()
  if Strictness then
    Strictness.strict(_G)
  end
  require "client"
end