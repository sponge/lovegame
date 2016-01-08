local GameFSM = require 'game/gamefsm'
local Smallfolk = require "smallfolk"

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
      elseif eType == 2 then
        assert(mpdata.gs ~= nil)
        local new_gs = Smallfolk.loads(msg, 1000000)
        GameFSM.mergeState(mpdata.gs, new_gs)
        return
      elseif eType == 3 then
        mpdata.ent_number = tonumber(msg)
        mpdata.status = 'ready'
      end
      
    elseif event.type == "connect" then
      mpdata.peer = event.peer
      print("connected.")
      
    elseif event.type == "disconnect" then
      print("disconnected.")
    end
    event = mpdata.host:service()
  end
end

return mod