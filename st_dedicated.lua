require "enet"
local Gamestate = require "gamestate"
local Console = require 'game/console'
local GameFSM = require 'game/gamefsm'
local Binser = require 'binser'

local gs = {}

--host = nil
--gs = nil
--accum = 0
--clients = {}
--level_json = nil

--local event_cb = function(s, ev)
--  if ev.type == 'death' then
--    print('player died')
--  elseif ev.type == 'win' then
--    print('player won')
--    -- FIXME: doesn't work yet
--    --Console:command("map base/maps/smw.json")
--  end
  
--  local msg = Binser.s(ev)
--  for peer, client in pairs(clients) do
--    if client.state == 'active' then
--      peer:send( string.char(4) .. msg )
--    end
--  end
--end

--local function con_map(mapname)
--  print("Loading", mapname)
  
--  level_json, _ = love.filesystem.read(mapname)
--  gs = GameFSM.init(level_json, event_cb)
  
--  for _, v in pairs(gs.cvars) do
--    Console:registercvar(v)
--  end
--  host = enet.host_create("0.0.0.0:6789")
--end

function gs:enter()
  collectgarbage("collect")
end

function gs:leave()

end

function gs:update()   
  collectgarbage("step")
  require("lovebird").update()
  
  if host == nil then
    return
  end
  
  local event = host:service()
  while event do
    if event.type == "receive" then
      if event.data == "ready" then
        clients[event.peer].state = "active"
      elseif event.data == "spawn" then
        local playerNum = GameFSM.spawnPlayer(gs)
        local compressedData = love.math.compress(Binser.s(gs.s), "lz4", 9)
        local s_gs = compressedData:getString()
        event.peer:send( string.char(2) .. s_gs, 0, "reliable")
        event.peer:send( string.char(3) .. tostring(playerNum), 0, "reliable")
        clients[event.peer].entity = playerNum
      else
        local eType = event.data:byte(1)
        local msg = string.sub(event.data, 2)
        if eType == 4 and clients[event.peer].entity > 0 then
          local usercmd = Binser.d(msg)
          gs.edata[clients[event.peer].entity].command = usercmd
        end
      end
    elseif event.type == "connect" then
      print("a player connected")
      clients[event.peer] = {
        name = 'player',
        peer = event.peer,
        state = 'gamestate',
        entity = 0,
      }
      event.peer:send( string.char(1) .. level_json, 0, "reliable")
    elseif event.type == "disconnect" then
      print("a player disconnected")
      gs.edata[clients[event.peer].entity] = nil
      clients[event.peer] = nil
    end
    event = host:service()
  end
  
  accum = accum + dt
  local send_update = false
  while accum >= 1/60 do
    send_update = true
    GameFSM.step(gs, 1/60)
    accum = accum - 1/60
  end
  
  if send_update then
    local uncompressed_state = Binser.s(gs.s)
    local compressedData = love.math.compress(uncompressed_state, "lz4", 9)
    local msg = compressedData:getString()
    for peer, client in pairs(clients) do
      if client.state == 'active' then
        peer:send( string.char(2) .. msg, 0, "unreliable")
      end
    end
  end
end

return gs