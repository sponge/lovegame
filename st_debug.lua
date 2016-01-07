local Gamestate = require "gamestate"
local Console = require 'game/console'
local suit = require "SUIT"

local cvars = {
  "p_gravity",
  "p_terminalvel",
  "p_speed",
  "p_accel",
  "p_skidaccel",
  "p_airaccel",
  "p_turnairaccel",
  "p_airfriction",
  "p_groundfriction",
  "p_jumpheight",
  "p_speedjumpbonus",
  "p_pogojumpheight",
  "p_doublejumpheight",
  "p_earlyjumpendmodifier",
  "p_wallslidespeed",
  "p_walljumpx",
}

local debug_vars = {}
local sliders = {}

local scene = {from = nil}

function scene:enter(from)
  self.from = from
  
  for _, v in ipairs(cvars) do
    local cvar = Console:getcvar(v)
    debug_vars[v] = cvar
    if cvar.value > 1 or cvar.value < 0 then
      sliders[v] = {min = math.floor(cvar.default * 0.25), max = cvar.default * 1.75, step = 1, value = cvar.value}
    else
      sliders[v] = {min = 0, max = 1, step = 0.05, value = cvar.value}
    end
  end
end

function scene:leave()
end

function scene:update(dt)
  if self.from.update ~= nil then
    self.from:update(dt)
  end
end

function scene:draw()
  local width, height = love.graphics.getDimensions()
  
  suit.layout:reset(width-400,0)

  for _, v in ipairs(cvars) do
    v = debug_vars[v]
    suit.layout:push(suit.layout:row(400, 30))
    suit.Label(v.name, {align = "left"}, suit.layout:col(175,30))
    if suit.Slider(sliders[v.name], suit.layout:col(150)) then
      local info = sliders[v.name]
      Console:setcvar(v.name, math.floor(info.value*(1/info.step)) / math.floor(1/info.step) )
    end
    suit.Label(v.value, {align = "center"}, suit.layout:col(75))

    suit.layout:pop()
  end

  if suit.Button("Write to Terminal", suit.layout:row()).hit then
    local io = require 'io'
    io.write('\n')
    for _, v in pairs(debug_vars) do
      io.write('{"'.. v.name .. '", '.. v.value .. '},\n')
    end
  end
  self.from:draw()
  love.graphics.setColor(0,0,0,200)
  love.graphics.rectangle("fill", width - 410, 0, 410, height)
  love.graphics.setColor(255,255,255,255)
  suit.draw()
end

return scene