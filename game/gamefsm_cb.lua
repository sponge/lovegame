local GameState = require 'gamestate'
local st_win = require 'st_win'

return function(s, ev)
  if ev.type == 'sound' then
    love.audio.stop(s.media['snd_'.. ev.name])
    love.audio.play(s.media['snd_'.. ev.name])
  elseif ev.type == 'stopsound' then
    love.audio.stop(s.media['snd_'.. ev.name])
  elseif ev.type == 'death' then
    GameState.switch(scene, currmap)
  elseif ev.type == 'win' then
    GameState.switch(st_win)
  elseif ev.type == 'error' then
    game_err(ev.message)
  end
end