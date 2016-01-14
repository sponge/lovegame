local GameFSM = require 'game/gamefsm'
local Binser = require "binser"

local mod = {}

mod.service = function(mpdata)
  local event = mpdata.host:service()
  while event do
    if event.type == "receive" and event.peer == mpdata.peer then
      local eType = event.data:byte(1)
      local msg = string.sub(event.data, 2)
      if eType == 1 then
        mpdata.gs = GameFSM.init(msg, require "game/gamefsm_cb")
        mpdata.status = "level_loaded"
        mpdata.peer:send("ready")
      elseif eType == 2 then
        assert(mpdata.gs ~= nil)
        local new_gs = Binser.d(msg, 1000000)
        GameFSM.mergeState(mpdata.gs, new_gs)
        assert(#mpdata.gs.s.entities > 0)
        return
      elseif eType == 3 then
        mpdata.gs.playerNum = tonumber(msg)
        mpdata.status = "ready"
      end
      
    elseif event.type == "connect" then
      mpdata.peer = event.peer
      local limit, min, max = mpdata.peer:timeout()
      mpdata.peer:timeout(limit, min, 5000)
      print("connected.")
      
    elseif event.type == "disconnect" then
      return "Disconnected from server."
    end
    event = mpdata.host:service()
  end
  
  return nil
end

return mod