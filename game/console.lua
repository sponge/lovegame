local Gamestate = require 'gamestate'
local CVar = require 'game/cvar'

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

local function con_clear()
  con.lines = {}
  con.scroll_offset = 0
end

con.lines = {}
con.cmds = {}
con.cvars = {}
con.history = {}
con.history_pos = 1
con.scroll_offset = 0

function con:addhistory(cmd)
  if con.history[#con.history] == cmd then
    return
  end
  con.history[#con.history+1] = cmd
  con.history_pos = #con.history + 1
end

function con:movehistory(count)
  con.history_pos = con.history_pos + count
  con.history_pos = math.max(1, math.min(con.history_pos, #con.history+1))
  return con.history[con.history_pos] ~= nil and con.history[con.history_pos] or ''
end

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
  
  if self.scroll_offset == #self.lines - 1 then
    self.scroll_offset = self.scroll_offset + 1
  end
  
  if #self.lines > 100 then
    table.remove(self.lines, 1)
    self.scroll_offset = #self.lines
  end
end

function con:init()
  self:addcommand("listcvars", con_listcvars)
  self:addcommand("listcmds", con_listcmds)
  self:addcommand("reset", con_reset)
  self:addcommand("set", con_set)
  self:addcommand("get", con_get)
  self:addcommand("map", con_map)
  self:addcommand("clear", con_clear)
  
  print("Console loaded")
  print("listcvars, listcmds for commands and settings")
  print("pgup/pgdn to scroll back through history")
  print("alt + pgup/pgdn to jump to top/bottom")
  print("up arrow and down arrow to go through command history")
  print("alt+backspace to backspace a full word")
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
  
  if cmd == nil then
    return
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

function con:registercvar(cvar)
  if self.cvars[cvar.name] ~= nil then
    return false
  end
  
  self.cvars[cvar.name] = cvar
  return true
end

function con:addcvar(name, value, cb)
  if name == nil or value == nil then return false end
  
  local num, str = nil
  name = string.lower(name)
  
  if self.cvars[name] ~= nil then
    return self.cvars[name], false
  end
  
  self.cvars[name] = CVar.new(name, value)
  if type(cb) == 'function' then
    self.cvars[name].cb = cb
  end
  
  return self.cvars[name], true
end

function con:setcvar(name, value)
  if name == nil or value == nil then return false end
  
  local num, str = nil
  name = string.lower(name)
  num, str, value = CVar.sanitize(value)
  
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