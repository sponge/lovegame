local Gamestate = require 'gamestate'

local con = {}

local function con_map(mapname)
  local st_game = require 'st_game'
  print("Switching to gameplay scene with map ", mapname)
  Gamestate.switch(st_game, mapname)
end

local function con_set(name, value)
  local cvar = con:setcvar(name, value)
  if cvar then
    print(cvar.name .. " = " .. cvar.str)
  end
end

local function con_get(name)
  local cvar = con:getcvar(name)
  if cvar ~= nil then 
    print(cvar.name .. " = " .. cvar.str)
  else
    print(name .. " is not set")
  end
end

local function con_reset(name)
  local cvar = con:getcvar(name)
  if cvar ~= nil then 
    con_set(name, cvar.default)
  else
    print(name .. " is not set")
  end
end

local function con_listcvars()
  local cvarlist = {}
  for _, cvar in pairs(con.cvars) do
    table.insert(cvarlist, cvar.name) 
  end
  table.sort(cvarlist)
  for _, v in ipairs(cvarlist) do
    con_get(v)
  end
end

local function con_listcmds()
  local cmdlist ={}
  for i in pairs(con.cmds) do
    table.insert(cmdlist, i)
  end 
  table.sort(cmdlist)
  for _, v in ipairs(cmdlist) do
    print(v)
  end
end

con.lines = {}
con.cmds = {}
con.cvars = {}

function con:addcommand(cmd, cb)
  cmd = string.lower(cmd)
  if self.cmds[cmd] ~= nil then return false end
  self.cmds[cmd] = cb
end

function con:removecommand(cmd)
  self.cmds[cmd] = nil
end

function con:addline(...)
  local line = ''
  for _, e in ipairs({...}) do
   line = line .. tostring(e)
  end
  self.lines[#self.lines+1] = line
  
  if #self.lines > 50 then
    table.remove(self.lines, 1)
  end
end

function con:init()
  self:addcommand("listcvars", con_listcvars)
  self:addcommand("listcmds", con_listcmds)
  self:addcommand("reset", con_reset)
  self:addcommand("set", con_set)
  self:addcommand("get", con_get)
  self:addcommand("map", con_map)
  
  print("Console loaded")
end

function con:dispatch(cmd, ...)
  if type(self.cmds[cmd]) == "function" then
    self.cmds[cmd](...)
    return true
  end
  
  return false
end

function con:command(s)
  local cmd = nil
  local args = {}
  for i in string.gmatch(s, "%S+") do
    if cmd == nil then
      cmd = string.lower(i)
    else
      args[#args+1] = i
    end
  end
  
  if not self:dispatch(cmd, unpack(args)) then  
    local cvar = con:getcvar(cmd)
    if cvar ~= nil then
      if args[1] ~= nil then
        con_set(cvar.name, args[1])
      else
        con_get(cvar.name)
      end
      return
    else
      print("Unknown command " .. cmd)
    end
  end
    
end

function con:getcvar(name)
  return self.cvars[string.lower(name)]
end

local function sanitizecvar(name, value)
  name = string.lower(name)
  
  local num = nil
  if type(value) == 'boolean' then
    num = value and 1 or 0
  else
    num = tonumber(value)
  end
  if num == nil then num = 0 end
  
  return name, num, tostring(value), value
end

function con:addcvar(name, value, cb)
  if name == nil or value == nil then return false end
  
  local num, str = nil
  name, num, str, value = sanitizecvar(name, value)
  
  if self.cvars[name] ~= nil then
    return self.cvars[name], false
  end
  
  self.cvars[name] = {name = name, int = num, str = str, value = value, default = str, cb = nil}
  if type(cb) == 'function' then
    self.cvars[name].cb = cb
  end
  
  return self.cvars[name], true
end

function con:setcvar(name, value)
  if name == nil or value == nil then return false end
  
  local num, str = nil
  name, num, str, value = sanitizecvar(name, value)
  
  local cvar = self.cvars[name]
  
  if cvar == nil then
    return false
  end
  
  local old = {name = cvar.name, int = cvar.int, str = cvar.str, value = cvar.value}
  cvar.int = num
  cvar.str = str
  cvar.value = value
  if type(cvar.cb) == 'function' then
    cvar.cb(old, cvar)
  end

  return self.cvars[name]
end

return con