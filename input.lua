local ffi = require "ffi"

local pad = nil

local kbmappings = {
  left = {'left'},
  right = {'right'},
  up = {'up'},
  down = {'down'},
  jump = {'z','a'},
  attack = {'x','s'},
  menu = {'escape'},
}

local padmappings = {
  left = {'dpleft'},
  right = {'dpright'},
  up = {'dpup'},
  down = {'dpdown'},
  jump = {'a'},
  attack = {'x'},
  menu = {'start'},
}

local function gamepadAdded(gamepad)
  if pad == nil and gamepad:isGamepad() then
    pad = gamepad
  end
end

local function gamepadRemoved(gamepad)
  if pad == gamepad then
    pad = nil
  end
end

local function isGamepadDown(action)
  if pad == nil then return false end
  if padmappings[action] == nil then return false end
  return pad:isGamepadDown(unpack(padmappings[action]))
end

local function isKeyboardDown(action)
  if kbmappings[action] == nil then return false end
  return love.keyboard.isDown(unpack(kbmappings[action]))
end

local function getInputs()
  local usercmd = ffi.new("entcommand_t")
  for i, v in ipairs(usercmd) do
    usercmd[v] = isKeyboardDown(v) or isGamepadDown(v)
  end
  
  return usercmd
end

local function getPad()
  return pad
end

return { gamepadAdded = gamepadAdded, gamepadRemoved = gamepadRemoved, getInputs = getInputs, getPad = getPad }