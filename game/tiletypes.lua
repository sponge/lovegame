local keen1 = { 
  [0] = {
    num = 0,
    solid = false,
    platform = false
  },
  
  [179] = {
    num = 179,
    solid = false,
    platform = true
  },
  
  [225] = {
    num = 225,
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
}

local smw = {
  [96] = {
    num = 96,
    solid = false,
    platform = false
  },
  
  [97] = {
    num = 97,
    solid = false,
    platform = false
  },
  
  [98] = {
    num = 98,
    solid = false,
    platform = false
  },
  
  [144] = {
    num = 144,
    solid = false,
    platform = true
  },
  
  [145] = {
    num = 145,
    solid = false,
    platform = true
  },
  
  [146] = {
    num = 146,
    solid = false,
    platform = true
  },
  
  [199] = {
    num = 199,
    solid = false,
    platform = false
  },
  
  [200] = {
    num = 200,
    solid = false,
    platform = false
  },
  
  [201] = {
    num = 200,
    solid = false,
    platform = false
  },

  [247] = {
    num = 247,
    solid = false,
    platform = false
  },
  
  [248] = {
    num = 248,
    solid = false,
    platform = false
  },
  
  [249] = {
    num = 249,
    solid = false,
    platform = false
  },
  
  [295] = {
    num = 295,
    solid = false,
    platform = false
  },
  
  [296] = {
    num = 296,
    solid = false,
    platform = false
  },
  
  [297] = {
    num = 297,
    solid = false,
    platform = false
  },
  
  [151] = {
    num = 151,
    solid = false,
    platform = true
  },
  
  [152] = {
    num = 152,
    solid = false,
    platform = true
  },
  
  [153] = {
    num = 153,
    solid = false,
    platform = true
  },
}

local keen3 = {}

local mt = {}
mt.__index = function (table, key)
  return {
    num = key,
    solid = true,
    platform = false
  }
end

setmetatable(keen1, mt)
setmetatable(keen3, mt)
setmetatable(smw, mt)

local __oob = {
  num = 1,
  solid = true,
  platform = false
}

return {keen1 = keen1, smw = smw, keen3 = keen3, __oob = __oob }