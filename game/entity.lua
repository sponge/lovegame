local entity = {}
entity.__index = entity

local function new(className, x, y, w, h)
	x,y  = x or love.graphics.getWidth()/2, y or love.graphics.getHeight()/2
	className = className or "default"

	return setmetatable({
      number = nil,
      className = className,
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