-- This file is part of SUIT, copyright (c) 2016 Matthias Richter

local Layout = {}
function Layout.new()
	return setmetatable({_stack = {}}, {__index = Layout}):reset()
end

function Layout:reset(x,y, padx,pady)
	self._x = x or 0
	self._y = y or 0
	self._padx = padx or 0
	self._pady = pady or 0
	self._w = -1
	self._h = -1
	self._widths = {min=math.huge,max=-math.huge}
	self._heights = {min=math.huge,max=-math.huge}

	return self
end

function Layout:padding(padx,pady)
	self._padx = padx
	self._pady = pady
end

function Layout:push(x,y)
	self._stack[#self._stack+1] = {
		self._x, self._y,
		self._padx, self._pady,
		self._w, self._h,
		self._widths,
		self._heights,
	}

	return self:reset(x,y)
end

function Layout:pop()
	assert(#self._stack > 0, "Nothing to pop")
	local w,h = self._w, self._h
	self._x, self._y,
	self._padx,self._pady,
	self._w, self._h,
	self._widths, self._heights = unpack(self._stack[#self._stack])

	self._w, self._h = math.max(w, self._w), math.max(h, self._h)

	return self
end

--- recursive binary search for position of v
local function insert_sorted_helper(t, i0, i1, v)
	if i1 <= i0 then
		table.insert(t, i0, v)
		return
	end

	local i = i0 + math.floor((i1-i0)/2)
	if t[i] < v then
		return insert_sorted_helper(t, i+1, i1, v)
	elseif t[i] > v then
		return insert_sorted_helper(t, i0, i-1, v)
	else
		table.insert(t, i, v)
	end
end

local function insert_sorted(t, v)
	if v <= 0 then return end
	insert_sorted_helper(t, 1, #t, v)
	t.min = math.min(t.min, v)
	t.max = math.max(t.max, v)
end

local function calc_width_height(self, w, h)
	if w == "" or w == nil then
		w = self._w
	elseif w == "max" then
		w = self._widths.max
	elseif w == "min" then
		w = self._widths.min
	elseif w == "median" then
		w = self._widths[math.ceil(#self._widths/2)] or 0
	elseif type(w) ~= "number" then
		error("width: invalid value (" .. tostring(w) .. ")", 3)
	end

	if h == "" or h == nil then
		h = self._h
	elseif h == "max" then
		h = self._heights.max
	elseif h == "min" then
		h = self._heights.min
	elseif h == "median" then
		h = self._heights[math.ceil(#self._heights/2)] or 0
	elseif type(h) ~= "number" then
		error("width: invalid value (" .. tostring(w) .. ")", 3)
	end

	if w < 0 or h < 0 then
		error("Invalid cell size", 3)
	end

	insert_sorted(self._widths, w)
	insert_sorted(self._heights, h)
	return w,h
end

function Layout:row(w, h)
	self._y = self._y + self._pady
	w,h = calc_width_height(self, w, h)

	local x,y = self._x, self._y + self._h
	self._y, self._w, self._h = y, w, h

	return x,y,w,h
end

function Layout:col(w, h)
	self._x = self._x + self._padx
	w,h = calc_width_height(self, w, h)

	local x,y = self._x + self._w, self._y
	self._x, self._w, self._h = x, w, h

	return x,y,w,h
end


local function layout_iterator(t, idx)
	idx = (idx or 1) + 1
	if t[idx] == nil then return nil end
	return idx, unpack(t[idx])
end

local function layout_retained_mode(self, t, constructor, string_argument_to_table, fill_width, fill_height)
	-- sanity check
	local p = t.pos or {0,0}
	if type(p) ~= "table" then
		error("Invalid argument `pos' (table expected, got "..type(p)..")", 2)
	end

	self:push(p[1] or 0, p[2] or 0)

	-- first pass: get dimensions, add layout info
	local layout = {n_fill_w = 0, n_fill_h = 0}
	for i,v in ipairs(t) do
		if type(v) == "string" then
			v = string_argument_to_table(v)
		end
		local x,y,w,h = 0,0, v[1], v[2]
		if v[1] == "fill" then w = 0 end
		if v[2] == "fill" then h = 0 end

		x,y, w,h = constructor(self, w,h)

		if v[1] == "fill" then
			w = "fill"
			layout.n_fill_w = layout.n_fill_w + 1
		end
		if v[2] == "fill" then
			h = "fill"
			layout.n_fill_h = layout.n_fill_h + 1
		end
		layout[i] = {x,y,w,h, unpack(v,3)}
	end

	-- second pass: extend "fill" cells and shift others accordingly
	local fill_w = fill_width(layout, t.min_width or 0, self._x + self._w - p[1])
	local fill_h = fill_height(layout, t.min_height or 0, self._y + self._h - p[2])
	local dx,dy = 0,0
	for _,v in ipairs(layout) do
		v[1], v[2] = v[1] + dx, v[2] + dy
		if v[3] == "fill" then
			v[3] = fill_w
			dx = dx + v[3]
		end
		if v[4] == "fill" then
			v[4] = fill_h
			dy = dy + v[4]
		end
	end

	-- finally: return layout with iterator
	self:pop()
	layout.cell = function(self, i)
		if self ~= layout then -- allow either colon or dot syntax
			i = self
		end
		return unpack(layout[i])
	end
	return setmetatable(layout, {__call = function()
		return layout_iterator, layout, 0
	end})
end

function Layout:rows(t)
	return layout_retained_mode(self, t, self.row,
			function(v) return {nil, v} end,
			function() return self._widths.max end, -- fill width
			function(l,mh,h) return (mh - h) / l.n_fill_h end) -- fill height
end

function Layout:cols(t)
	return layout_retained_mode(self, t, self.col,
			function(v) return {v} end,
			function(l,mw,w) return (mw - w) / l.n_fill_w end, -- fill width
			function() return self._heights.max end) -- fill height
end

-- TODO: nesting a la rows{..., cols{...} } ?

local instance = Layout.new()
return setmetatable({
	new     = Layout.new,
	reset   = function(...) return instance:reset(...) end,
	padding = function(...) return instance:padding(...) end,
	push    = function(...) return instance:push(...) end,
	pop     = function(...) return instance:pop(...) end,
	row     = function(...) return instance:row(...) end,
	col     = function(...) return instance:col(...) end,
	rows    = function(...) return instance:rows(...) end,
	cols    = function(...) return instance:cols(...) end,
}, {__call = function(_,...) return Layout.new(...) end})

--[[do

L = Layout.new()



print("immediate mode")
print("--------------")
x,y,w,h = L:row(100,20) -- x,y,w,h = x0,y0, 100,20
print(1,x,y,w,h)
x,y,w,h = L:row()       -- x,y,w,h = x0, y0+20, 100,20 (default: reuse last dimensions)
print(2,x,y,w,h)
x,y,w,h = L:col(20)     -- x,y,w,h = x0+100, y0+20, 20, 20
print(3,x,y,w,h)
x,y,w,h = L:row(nil,30) -- x,y,w,h = x0+100, y0+40, 20, 30
print(4,x,y,w,h)
print()

L:reset()

local layout = L:rows{
	pos = {10,10},   -- optional, default {0,0}

	{100, 10},
	{nil, 10},       -- {100, 10}
	{100, 20},       -- {100, 20}
	{},              -- {100, 20} -- default = last value
	{nil, "median"}, -- {100, 20}
	"median",        -- {100, 20}
	"max",           -- {100, 20}
	"min",           -- {100, 10}
	""               -- {100, 10} -- default = last value
}

print("rows")
print("----")
for i,x,y,w,h in layout() do
	print(i,x,y,w,h)
end
print()

--  +-------+-------+----------------+-------+
--  |       |       |                |       |
-- 70 {100, | "max" |     "fill"     | "min" |
--  |   70} |       |                |       |
--  +--100--+--100--+------220-------+--100--+
--
--  `-------------------,--------------------'
--                     520
local layout = L:cols{
	pos = {10,10},
	min_width = 520,

	{100, 70},
	"max",    -- {100, 70}
	"fill",   -- {min_width - width_of_items, 70} = {420, 70}
	"min",    -- {100,70}
}

print("cols")
print("----")
for i,x,y,w,h in layout() do
	print(i,x,y,w,h)
end
print()

end
--]]
