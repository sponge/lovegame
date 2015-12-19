local Gamestate = require "gamestate"
local Console = require 'game/console'
local gui = require "Quickie"

local debug_vars = {}
local sliders = {}

local scene = {from = nil}

function scene:enter(from)
  self.from = from
  
  local cvars = {
    "p_gravity",
    "p_speed",
    "p_terminalvel",
    "p_accel",
    "p_skidaccel",
    "p_airaccel",
    "p_turnairaccel",
    "p_terminalvel",
    "p_airfriction",
    "p_groundfriction",
    "p_jumpheight",
    "p_speedjumpbonus",
    "p_pogojumpheight",
    "p_doublejumpheight",
    "p_earlyjumpendmodifier",
    "p_headbumpmodifier",
    "p_wallslidespeed",
    "p_walljumpx",
  }
  
  for _, v in ipairs(cvars) do
    local cvar = Console:getcvar(v)
    debug_vars[v] = cvar
    if cvar.value > 1 then
      sliders[v] = {min = math.floor(cvar.default * 0.5), max = cvar.default * 2, step = 1, value = cvar.value}
    else
      sliders[v] = {min = 0, max = 1, step = 0.05, value = cvar.value}
    end
  end
end

function scene:leave()
end

function scene:update(dt)
  local width, height = love.graphics.getDimensions()

  if self.from.update ~= nil then
    self.from:update(dt)
  end
  
  gui.group{grow = "down", pos = {width-400, 0}, function()
    for _, v in pairs(debug_vars) do
      
      gui.group{grow = "right", function()
        gui.Label{text = v.name, size={120}}
        if gui.Slider{info = sliders[v.name], size={248}} then
          Console:setcvar(v.name, math.floor(sliders[v.name].value))
        end
        gui.Label{text = v.value, size={32}}

      end}
    
    end

    if gui.Button{text = "Export"} then
      for _, v in pairs(debug_vars) do
        print('{"'.. v.name .. '", '.. v.value .. '},')
      end
    end
  end}

end

function scene:draw()
  local width, height = love.graphics.getDimensions()

  self.from:draw()
  love.graphics.setColor(0,0,0,200)
  love.graphics.rectangle("fill", width - 410, 0, 410, height)
  love.graphics.setColor(255,255,255,255)
  gui.core.draw()
end

return scene