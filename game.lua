local json = require "dkjson"
local Camera = require "camera"
local Entity = require "entity"
local tilecollider = require "tilecollider"

local gs = {}

local state = {entities = {}, worldLayer = nil}
local lc = {playerEnt = nil, camera = nil} -- local client, not gamestate related stuff
local media = {}
local spritebatches = {}
local tileInfo = {}
local cam = nil
local level = nil

local collider = nil
local can_jump = false

local g = function(x,y)
  return state.worldLayer.data[(y-1)*level.width+x]
end

local c = function(side, tile, x, y)
  if tile > 0 then
    return true
  end
  
  return false
end

-- Collision detection function.
-- Checks if a and b overlap.
-- w and h mean width and height.
local function CheckCollision(ax1,ay1,aw,ah, bx1,by1,bw,bh)
  local ax2,ay2,bx2,by2 = ax1 + aw, ay1 + ah, bx1 + bw, by1 + bh
  return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
end

local function player_think(ent, s, dt)
  
  if love.keyboard.isDown("z") and can_jump == true then
    ent.dy = -1
    can_jump = false
  end
  
  if love.keyboard.isDown("left") then
    ent.dx = ent.dx - (2 * dt)
  elseif love.keyboard.isDown("right") then
    ent.dx = ent.dx + (2 * dt)
  else
    if ent.dx < 0 then
      ent.dx = ent.dx + 2 * dt
    elseif ent.dx > 0 then
      ent.dx = ent.dx - 2 * dt
    end
    
    if ent.dx ~= 0 and math.abs(ent.dx) < 0.1 then
      ent.dx = 0
    end
  end
  
  ent.dx = math.max(-1, math.min(1, ent.dx))
  ent.dy = math.min(2, ent.dy + 2 * dt)
  
  local collided = false
  if ent.dx > 0 then
    ent.x, collided = collider:rightResolve(ent.x + ent.dx, ent.y, ent.w, ent.h)
  elseif ent.dx < 0 then
    ent.x, collided = collider:leftResolve(ent.x + ent.dx, ent.y, ent.w, ent.h)
  end
  
  if collided then
    ent.dx = 0
  end
  
  collided = false
  if ent.dy > 0 then
    ent.y, collided = collider:bottomResolve(ent.x, ent.y + ent.dy, ent.w, ent.h)
    if collided then
      can_jump = true
      ent.dy = 0
    end
  elseif ent.dy < 0 then
    ent.y, collided = collider:topResolve(ent.x, ent.y + ent.dy, ent.w, ent.h)
  end

end

local function player_draw(ent)
  love.graphics.setColor(255,0,0,255)
  love.graphics.rectangle("fill", ent.x, ent.y, 16, 32)
  love.graphics.setColor(255,255,255,255)
end

local map_funcs = {

}

local ent_funcs = {
  player = {
    think = player_think,
    draw = player_draw
  },
  
  player_start = {
    think = nil,
    draw = nil
  }
}

function gs:enter()
  local err = nil
  local level_json, _ = love.filesystem.read("base/maps/testlevel.json")
  level, _, err = json.decode(level_json, 1, nil)
  lc.cam = Camera(0, 0, 4)
  
  if err ~= nil then
    game_err("Error while loading map json")
    return
  end
  
  for _, v in ipairs(level.tilesets) do
    media[v.name] = love.graphics.newImage(v.image)
    media[v.name]:setFilter("nearest", "nearest")
    spritebatches[v.name] = love.graphics.newSpriteBatch(media[v.name], 1024)
    local lastgid = v.firstgid + v.tilecount
    for i = v.firstgid, lastgid do
      tileInfo[i+1] = { name = v.name, quad = love.graphics.newQuad(i * v.tilewidth % v.imagewidth, math.floor(i * v.tilewidth / v.imagewidth) * v.tileheight, v.tilewidth, v.tileheight, v.imagewidth, v.imageheight) }
    end
  end
  
  local spawnPoint = nil
  
  for _, layer in ipairs(level.layers) do
    if layer.name == "world" and layer.type == "tilelayer" then
      state.worldLayer = layer
    end
    
    if layer.type == "objectgroup" then
      for _, obj in ipairs(layer.objects) do
        local ent = Entity.new(obj.type, obj.x, obj.y - obj.height, obj.width, obj.height)
        ent.think = map_funcs[obj.properties.think] or ent_funcs[obj.type].think
        ent.draw = map_funcs[obj.properties.draw] or ent_funcs[obj.type].draw
        table.insert(state.entities, ent)
        if ent.className == "player_start" then
          spawnPoint = ent
        end
      end
    end
  end
  
  local player = Entity.new("player", spawnPoint.x, spawnPoint.y, 16, 32)
  player.think = ent_funcs[player.className].think
  player.draw = ent_funcs[player.className].draw
  table.insert(state.entities, player)
  lc.playerEnt = #state.entities
  lc.cam:lookAt(spawnPoint.x, spawnPoint.y)
  
  collider = tilecollider(g, level.tilewidth, level.tileheight, c, nil, false)

end

function gs:keyreleased(key)

end

function gs:update(dt)
  local ent = nil
  for i = 1, #state.entities do
    ent = state.entities[i]
    if ent.think ~= nil then
      ent.think(ent, state, dt)
    end
  end
end

function gs:draw()
  
  lc.cam:lookAt(state.entities[lc.playerEnt].x, state.entities[lc.playerEnt].y)

  love.graphics.setColor(168,168,168,255)
  local width, height = love.graphics.getDimensions()
  love.graphics.rectangle("fill", 0, 0, width, height)
  
  love.graphics.setColor(255,255,255,255)
  
  local cminx, cminy = lc.cam:worldCoords(0,0)
  local cmaxx, cmaxy = lc.cam:worldCoords(width, height)
  
  if cminx <= 0 then
    lc.cam:move(math.abs(cminx), 0)
  elseif cmaxx > level.width * level.tilewidth then
    lc.cam:move(0 - (cmaxx - (level.width * level.tilewidth)), 0)
  end
  
  if cminy <= 0 then
    lc.cam:move(0, math.abs(cminy))
  elseif cmaxy > level.height * level.tileheight then
    lc.cam:move(0, 0 - (cmaxy - (level.height * level.tileheight)), 0)
  end
  
  cminx, cminy = lc.cam:worldCoords(0,0)
  cmaxx, cmaxy = lc.cam:worldCoords(width, height)
    
  for _, batch in pairs(spritebatches) do
    batch:clear()
  end
  
  lc.cam:attach()
  
  for _, layer in pairs(level.layers) do
    local minx = math.max(1, math.floor(cminx/16) )
    local maxx = math.min(layer.width, math.ceil(cmaxx/16) )
    local miny = math.max(1, math.floor(cminy/16) )
    local maxy = math.min(layer.height, math.ceil(cmaxy/16) )
    
    if layer.type == "tilelayer" then
      for x = minx, maxx do
        for y = miny, maxy do
          local id = layer.data[(y-1)*layer.width+x]
          if id > 0 then
            local tile = tileInfo[id]
            spritebatches[tile.name]:add(tile.quad, (x-1)*16, (y-1)*16)
          end
        end
      end
    end
    
  end
  
  for _, batch in pairs(spritebatches) do
    love.graphics.draw(batch)
  end
  
  local ent = nil
  for i = 1, #state.entities do
    ent = state.entities[i]
    if ent.draw ~= nil then
      ent.draw(ent)
    end
  end

  lc.cam:detach()

end

return gs
