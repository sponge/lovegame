--[[
Tile Collider 3.1

Copyright (c) 2013 Minh Ngo

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]
local floor = math.floor
local ceil  = math.ceil
local max   = math.max
local min   = math.min

local t   = setmetatable({startzero = nil},{__call = function(self,...) return self.new(...) end})
t.__index = t

local gx, gy, gx2, gy2

-----------------------------------------------------------
local function getTileRange(tw,th,x,y,w,h)
	gx,gy   = floor(x/tw)+1,floor(y/th)+1
	gx2,gy2 = w == 0 and gx or ceil( (x+w)/tw ), h == 0 and gy or ceil( (y+h)/th )
	return gx,gy,gx2,gy2
end

local function getActualCoord(self,tx,ty)
	if self.startzero then return tx-1,ty-1 else return tx,ty end
end

-----------------------------------------------------------
function t.new(getTile,tileWidth,tileHeight,isResolvable,heightmaps,startzero)
	local o = {
		getTile     = getTile,
		tileWidth   = tileWidth,
		tileHeight  = tileHeight,
		isResolvable= isResolvable,
		heightmaps  = heightmaps or {},
		startzero   = startzero == nil and true or startzero,
	}
	return setmetatable(o,t)
end
-----------------------------------------------------------
function t:rightResolve(state,ent,x,y,w,h,dx,dy)
	local tw,th        = self.tileWidth,self.tileHeight
	local gx,gy,gx2,gy2= getTileRange(tw,th,x,y,w,h)
	local newx         = x
	local getTile      = self.getTile
	local isResolvable = self.isResolvable
	local heightmaps   = self.heightmaps
	for tx = gx,gx2 do
		for ty = gy,gy2 do 
			local actualtx,actualty = getActualCoord(self,tx,ty)
			local tile = getTile(state,actualtx,actualty)
			if tile then
				local hmap = heightmaps[tile] and heightmaps[tile].horizontal
				if hmap then
					local ti   = floor(y-(ty-1)*th)+1
					local bi   = ceil(y+h-(ty-1)*th)
					ti         = ti > th and th or ti < 1 and 1 or ti
					bi         = bi > th and th or bi < 1 and 1 or bi
					local minx = min(x,tx*tw-w-hmap[ti],tx*tw-w-hmap[bi])
					if minx ~= x and isResolvable(state,ent,'right',tile,actualtx,actualty,dx,dy) then
						newx = min(minx,newx)
					end
				elseif isResolvable(state,ent,'right',tile,actualtx,actualty,dx,dy) then
					newx = min(newx,(tx-1)*tw-w)
				end
			end
		end
		if newx ~= x then break end
	end
	return newx, newx ~= x
end
-----------------------------------------------------------
function t:leftResolve(state,ent,x,y,w,h,dx,dy)
	local tw,th        = self.tileWidth,self.tileHeight
	local gx,gy,gx2,gy2= getTileRange(tw,th,x,y,w,h)
	local newx         = x
	local getTile      = self.getTile
	local isResolvable = self.isResolvable
	local heightmaps   = self.heightmaps
	for tx = gx2,gx,-1 do
		for ty = gy,gy2 do 
			local actualtx,actualty = getActualCoord(self,tx,ty)
			local tile = getTile(state,actualtx,actualty)
			if tile then
				local hmap = heightmaps[tile] and heightmaps[tile].horizontal
				if hmap then
					local ti   = floor(y-(ty-1)*th)+1
					local bi   = ceil(y+h-(ty-1)*th)
					ti         = ti > th and th or ti < 1 and 1 or ti
					bi         = bi > th and th or bi < 1 and 1 or bi
					local maxx = max(x,(tx-1)*tw+hmap[ti],(tx-1)*tw+hmap[bi])
					if maxx ~= x and isResolvable(state,ent,'left',tile,actualtx,actualty,dx,dy) then
						newx = max(maxx,newx)
					end
				elseif isResolvable(state,ent,'left',tile,actualtx,actualty,dx,dy) then
					newx = max(newx,tx*tw)
				end
			end
		end
		if newx ~= x then break end
	end
	return newx, newx ~= x
end
-----------------------------------------------------------
function t:bottomResolve(state,ent,x,y,w,h,dx,dy)
	local tw,th        = self.tileWidth,self.tileHeight
	local gx,gy,gx2,gy2= getTileRange(tw,th,x,y,w,h)
	local newy         = y
	local getTile      = self.getTile
	local isResolvable = self.isResolvable
	local heightmaps   = self.heightmaps
	for ty = gy,gy2 do
		for tx = gx,gx2 do 
			local actualtx,actualty = getActualCoord(self,tx,ty)
			local tile = getTile(state,actualtx,actualty)
			if tile then
				local hmap = heightmaps[tile] and heightmaps[tile].vertical
				if hmap then
					local li   = floor(x-(tx-1)*tw)+1
					local ri   = ceil((x+w)-(tx-1)*tw)
					li         = li > tw and tw or li < 1 and 1 or li
					ri         = ri > tw and tw or ri < 1 and 1 or ri
					local miny = min(y,ty*th-h-hmap[li],ty*th-h-hmap[ri])
					if miny ~= y and isResolvable(state,ent,'bottom',tile,actualtx,actualty,dx,dy) then
						newy = min(miny,newy)
					end
				elseif isResolvable(state,ent,'bottom',tile,actualtx,actualty,dx,dy) then
					newy = min(newy,(ty-1)*th-h)
				end
			end
		end
		if newy ~= y then break end
	end
	return newy, newy ~= y
end
-----------------------------------------------------------
function t:topResolve(state,ent,x,y,w,h,dx,dy)
	local tw,th        = self.tileWidth,self.tileHeight
	local gx,gy,gx2,gy2= getTileRange(tw,th,x,y,w,h)
	local newy         = y
	local getTile      = self.getTile
	local isResolvable = self.isResolvable
	local heightmaps   = self.heightmaps
	for ty = gy2,gy,-1 do
		for tx = gx,gx2 do
			local actualtx,actualty = getActualCoord(self,tx,ty) 
			local tile = getTile(state,actualtx,actualty)
			if tile then
				local hmap = heightmaps[tile] and heightmaps[tile].vertical
				if hmap then
					local li   = floor(x-(tx-1)*tw)+1
					local ri   = ceil((x+w)-(tx-1)*tw)
					li         = li > tw and tw or li < 1 and 1 or li
					ri         = ri > tw and tw or ri < 1 and 1 or ri
					local maxy = max(y,(ty-1)*th+hmap[li],(ty-1)*th+hmap[ri])
					if maxy ~= y and isResolvable(state,ent,'top',tile,actualtx,actualty,dx,dy) then
						newy = max(maxy,newy)
					end
				elseif isResolvable(state,ent,'top',tile,actualtx,actualty,dx,dy) then
					newy = max(newy,ty*th)
				end
			end
		end
		if newy ~= y then break end
	end
	return newy, newy ~= y
end
-----------------------------------------------------------
return t
