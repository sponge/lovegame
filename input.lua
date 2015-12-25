local pad = nil

local kbmappings = {
  left = 'left',
  right = 'right',
  up = 'up',
  down = 'down',
  jump = 'z',
  attack = 'x',
  menu = 'escape',
}

local padmappings = {
  left = 'dpleft',
  right = 'dpright',
  up = 'dpup',
  down = 'dpdown',
  jump = 'a',
  attack = 'x',
  menu = 'start',
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
  return pad:isGamepadDown(padmappings[action])
end

local function isKeyboardDown(action)
  if kbmappings[action] == nil then return false end
  return love.keyboard.isDown(kbmappings[action])
end

local function getInputs()
  local usercmd = { left = 0, right = 0, up = 0, down = 0, jump = false, attack = false, menu = false }
  for i, v in pairs(usercmd) do
    usercmd[i] = isKeyboardDown(i) or isGamepadDown(i)
  end
  
  return usercmd
end

local function getPad()
  return pad
end

return { gamepadAdded = gamepadAdded, gamepadRemoved = gamepadRemoved, getInputs = getInputs, getPad = getPad }