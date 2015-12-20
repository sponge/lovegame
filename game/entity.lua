local entity = {}
entity.__index = entity

local function new(classname, x, y, w, h)
	if not classname or not x or not y or not w or not h then return nil end
	classname = classname or "default"

	return setmetatable({
      number = nil,
      classname = classname,
      x = x,
      y = y,
      dx = 0,
      dy = 0,
      w = w,
      h = h,
      drawx = 0,
      drawy = 0,
      think = nil,
      draw = nil,
      command = {}
    }, entity)
end

-- the module
return setmetatable({new = new},
	{__call = function(_, ...) return new(...) end})