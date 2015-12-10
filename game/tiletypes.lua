local ti = { 
  [0] = {
    num = 0,
    solid = false,
    platform = false
  },
  
  [180] = {
    num = 180,
    solid = false,
    platform = true
  },
  
  [226] = {
    num = 226,
    solid = false,
    platform = true
  },
  
  [227] = {
    num = 227,
    solid = false,
    platform = true
  },
  
  [228] = {
    num = 228,
    solid = false,
    platform = true
  },
}

local mt = {}
mt.__index = function (table, key)
  return {
    num = key,
    solid = true,
    platform = false
  }
end

setmetatable(ti, mt)

return ti