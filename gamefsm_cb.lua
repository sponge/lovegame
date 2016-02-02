

return function(s, ev)
  if ev.type == 'sound' then
    love.audio.stop(s.media['snd_'.. ev.name])
    love.audio.play(s.media['snd_'.. ev.name])
  elseif ev.type == 'stopsound' then
    love.audio.stop(s.media['snd_'.. ev.name])
  elseif ev.type == 'death' then
    GameState.switch(st_game, s.currmap)
  elseif ev.type == 'win' then
    GameState.switch(st_win)
  end
end