require("errhand")

if arg and arg[#arg] ~= "-debug" then
  local Strictness = require "game/strictness"
else
  require("mobdebug").start()
end

-- globals
_, game_err, socket, currgame, con, sess = nil

sess = {
  client = true,
  server = false,
}

for i, v in ipairs(arg) do
  if v == '-server' then
    sess.server = true
    sess.client = false
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

if Strictness then
  Strictness.strict(_G)
end

require "client"