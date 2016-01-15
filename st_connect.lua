local Gamestate = require "gamestate"
local InputManager = require "input"
local GNet = require 'gamenet'

local st_game = require "st_game"

require "enet"

local scene = {}

function scene:enter(from, address)
  collectgarbage("collect")
  local err
  self.mpdata, err = GNet.connect(address)
  if self.mpdata == nil then
    game_err(err)
  end
end

function scene:leave()
  self.mpdata = nil
end

function scene:keypressed(key, code, isrepeat)
  local inputs = InputManager.getInputs()
  if inputs.menu then
    GNet.destroy(self.mpdata)
    game_err()
  end
end

function scene:gamepadpressed(pad, button)
  local inputs = InputManager.getInputs()
  if inputs.menu then
    GNet.destroy(self.mpdata)
    game_err()
  end
end

function scene:update(dt)
  GNet.service(self.mpdata)
  if self.mpdata.status == "level_loaded" then
    Gamestate.switch(st_game, nil, self.mpdata)
  end
end

function scene:draw()   

end

return scene