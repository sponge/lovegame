local Gamestate = require "gamestate"
local InputManager = require "input"
local GNet = require 'gamenet'

local st_game = require "st_game"

require "enet"

local scene = {}

function scene:enter(from, address)
  collectgarbage("collect")
  self.mp = {
    address = address,
    host = nil,
    server = nil,
    peer = nil,
    gs = nil,
    ent_number = 0,
    status = 'connecting'
  }
  self.mp.host = enet.host_create()
  self.mp.server = self.mp.host:connect(address)

end

function scene:leave()
  self.mp = nil
end

function scene:keypressed(key, code, isrepeat)
  local inputs = InputManager.getInputs()
  if inputs.menu then
    -- FIXME: quit
  end
end

function scene:gamepadpressed(pad, button)
  local inputs = InputManager.getInputs()
  if inputs.menu then
    -- FIXME: quit
  end
end

function scene:update(dt)
  GNet.service(self.mp)
  if self.mp.status == "level_loaded" then
    self.mp.peer:send("spawn")
    self.mp.status = "spawn_wait"
  elseif self.mp.status == "ready" then
    Gamestate.switch(st_game, nil, self.mp)
  end
end

function scene:draw()   

end

return scene