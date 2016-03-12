local GameFSM = require 'game/gamefsm'
local Binser = require "binser"

local mod = {}

mod.connect = function(address)
  local mpdata = {
    address = address,
    host = nil,
    server = nil,
    peer = nil,
    gs = nil,
    status = 'connecting'
  }
  mpdata.host = enet.host_create()
  local success, err = pcall(function() mpdata.server = mpdata.host:connect(address) end)
  if not success then
    return nil, err
  end
  
  return mpdata
end

mod.destroy = function(mpdata)
  mpdata.gs = nil
  if mpdata.server then
    mpdata.server:disconnect()
    mpdata.host:service()
  end
  
  if mpdata.host then
    mpdata.host:destroy()
  end
end

mod.service = function(mpdata)
  local event = mpdata.host:service()
  while event do
    if event.type == "receive" and event.peer == mpdata.peer then
      local eType = event.data:byte(1)
      local msg = string.sub(event.data, 2)
      if eType == 1 then
        mpdata.gs = GameFSM.init(msg)
        mpdata.status = "level_loaded"
        mpdata.peer:send("ready")
      elseif eType == 2 then
        assert(mpdata.gs ~= nil)
        local new_gs = Binser.d(love.math.decompress(msg, "lz4"), 1000000)
        GameFSM.mergeState(mpdata.gs, new_gs)
        assert(#mpdata.gs.edata > 0)
      elseif eType == 3 then
        mpdata.gs.playerNum = tonumber(msg)
        mpdata.status = "ready"
      elseif eType == 4 then
        -- FIXME: needs to not use callbacks and insert into the gs events table
        --local ev = Binser.d(msg, 1000)
        --mpdata.gGameFSM.addEvent(mpdata.gs, ev)
      else
        print("unknown packet type", eType)
      end
      
    elseif event.type == "connect" then
      mpdata.peer = event.peer
      local limit, min, max = mpdata.peer:timeout()
      mpdata.peer:timeout(limit, min, 5000)
      print("connected.")
      
    elseif event.type == "disconnect" then
      return false, "Disconnected from server."
    end
    event = mpdata.host:service()
  end
  
  return true
end

return mod