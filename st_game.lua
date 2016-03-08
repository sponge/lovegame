local ffi = require 'ffi'

local JSON = require "game/dkjson"
local GNet = require 'gamenet'
local Binser = require 'binser'
local Console = require 'game/console'
local GameState = require 'gamestate'
local GameFSM = require 'game/gamefsm'
local Camera = require 'game/camera'
local InputManager = require 'input'
local Easing = require 'game/easing'
local Entity = require 'game/entity'

local st_console = require 'st_console'
local st_debug = require 'st_debug'
local st_levelintro = require 'st_levelintro'
local st_win = require 'st_win'

local Tiny = require 'game/tiny'

local tickrate = 1/200
local update_accum = 0

local gs = nil
local world = nil

local scene = {}
local canvas = nil

local mp_predict = nil

function scene:enter(current, mapname, mpdata)
  local err = nil
  
  mp_predict = Console:addcvar("mp_predict", 0)
  
  if mpdata ~= nil then
    gs = mpdata.gs
    gs.mpdata = mpdata
  else
    local err
    local level_json, _ = love.filesystem.read(mapname)
  
    gs, world, err = GameFSM.init(level_json)
    if err ~= nil then
      game_err(err)
      return
    end
    
    gs.currmap = mapname
    
    gs.playerNum = GameFSM.spawnPlayer(gs)
    
    for _, v in pairs(gs.cvars) do
      Console:registercvar(v)
    end
  end
  
  GameState.push(st_levelintro, gs)
  
  currgame = gs -- global for the debugger
  
  canvas = love.graphics.newCanvas(1920, 1080)
  
  if gs.entities[gs.playerNum] ~= nil then
    gs.cam:lookAt(gs.entities[gs.playerNum].x, gs.entities[gs.playerNum].y)
  end
  
end

function scene:leave()  
  currgame = nil
  canvas = nil
  love.audio.stop()
  if gs and gs.mpdata then
    GNet.destroy(gs.mpdata)
    gs.mpdata = nil
  end
  gs = {}
end

local filter_update = Tiny.requireAll("think")
local filter_draw = Tiny.requireAll("draw")

function scene:update(dt)
  -- FIXME: move input into a system
  update_accum = update_accum + dt
  
  local usercmd = nil
  
  if GameState.current() == st_console then
    usercmd = ffi.new("entcommand_t")
  else
    usercmd = InputManager.getInputs()
    if usercmd.menu then
      game_err('Game Exited')
      return
    end
  end
  
  if gs then
    if not gs.mpdata then
      GameFSM.addCommand(gs, gs.playerNum, usercmd)
    else
      gs.mpdata.peer:send( string.char(4) .. Binser.s(usercmd), 0, "unreliable")
    end
  end
  
  while update_accum >= tickrate do    
    Tiny.update(world, tickrate, filter_update)
    update_accum = update_accum - tickrate
  end
end

function scene:draw()
  local width, height = canvas:getDimensions()
  
  love.graphics.setCanvas(canvas)
  
  Tiny.update(world, 0, filter_draw)
  
  love.graphics.setCanvas()
  
  local winw, winh = love.graphics.getDimensions()
  local sf = winw/winh < width/height and winw/width or winh/height
  local x, xoff = winw/2, width/2
  if GameState.current() == st_debug then
    x, xoff = 0
  end
  
  local y = winh/2
  if gs.goal_time ~= nil and gs.time + 1.5 >= gs.goal_time then
    y = Easing.inBack(gs.time - gs.goal_time + 1.5, winh/2, winh/2, 0.6)
  end
  
  love.graphics.draw(canvas, x, y, 0, sf, sf, xoff, height/2)
end

return scene
