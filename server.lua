-- server.lua
require "enet"
local Console = require 'game/console'
local GameFSM = require 'game/gamefsm'
local Smallfolk = require 'smallfolk'

_ = nil

host = nil
gs = nil
accum = 0
clients = {}
level_json = nil

local event_cb = function(s, ev)
  if ev.type == 'death' then
    print('player died')
  elseif ev.type == 'win' then
    print('player won')
  elseif ev.type == 'error' then
    print(ev.message)
    Console:dispatch("quit")
  end
end

local function con_map(mapname)
  print("Loading", mapname)
  
  level_json, _ = love.filesystem.read(mapname)
  gs = GameFSM.init(level_json, event_cb)
  
  for _, v in pairs(gs.cvars) do
    Console:registercvar(v)
  end
  host = enet.host_create("0.0.0.0:6789")
end

function love.load(arg)
  require("lovebird").port = 8888
  require("lovebird").update()
  
  Console:init()
  Console:addcommand("map", con_map)
  
  print("Navigate to http://localhost:8888 to access console, use con:command()")
  con:command('map base/maps/smw.json')
  
end

function love.update(dt)
  collectgarbage("step")
  require("lovebird").update()
  
  if host == nil then
    return
  end
  
  local event = host:service()
  while event do
    if event.type == "receive" then
      if event.data == "spawn" then
        local playerNum = GameFSM.spawnPlayer(gs)
        event.peer:send( string.char(2) .. Smallfolk.dumps(gs.s), 0, "reliable")
        event.peer:send( string.char(3) .. tostring(playerNum), 0, "reliable")
        clients[event.peer].entity = playerNum
        clients[event.peer].state = "active"
      else
        local eType = event.data:byte(1)
        local msg = string.sub(event.data, 2)
        if eType == 4 then
          local usercmd = Smallfolk.loads(msg)
          gs.s.entities[clients[event.peer].entity].command = usercmd
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
      gs.s.entities[clients[event.peer].entity] = nil
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
    local msg = Smallfolk.dumps(gs.s)
    for peer, client in pairs(clients) do
      if client.state == 'active' then
        peer:send( string.char(2) .. msg, 0, "unreliable")
      end
    end
  end
end