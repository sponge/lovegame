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
  }
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