local cvar = {}
cvar.__index = cvar

local function sanitize(value)
  local num = nil
  if type(value) == 'boolean' then
    num = value and 1 or 0
  else
    num = tonumber(value)
  end
  if num == nil then num = 0 end
  
  return num, tostring(value), value
end

local function new(name, value, cb)
  local num, str = nil
  name = string.lower(name)
  num, str, value = sanitize(value)
	return setmetatable({
    name = name,
    int = num,
    str = str,
    value = value,
    default = str,
    cb = cb}, cvar)
end

-- the module
return setmetatable({new = new, sanitize = sanitize},
	{__call = function(_, ...) return new(...) end})