local ent_funcs = {
  player_start = {init = nil, spawn = nil, think = nil, draw = nil},
  player = require 'game/ent_player',
  coin = require 'game/ent_coin',
  red_coin = require 'game/ent_red_coin',
  coin_block = require 'game/ent_coin_block',
  goomba = require 'game/ent_goomba',
  turtle = require 'game/ent_turtle',
  goal = require 'game/ent_goal',
}

return ent_funcs