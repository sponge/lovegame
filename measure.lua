local timers = {}

local mod = {}

return function(mode, metric, time)
  if mode ~= 'clearall' and timers[metric] == nil then
    timers[metric] = {0,0,0,0}
  end
  
  if mode == 'get' then
    return string.format("%.1f", timers[metric][2] * 1000)
  elseif mode == 'getmax' then
    return string.format("%.1f", timers[metric][3] * 1000)
  elseif mode == 'getsum' then
    return string.format("%.1f", timers[metric][4] * 1000)
  elseif mode == 'getpct' then
    return string.format("%.1f", timers[metric][4] / timers.frame[4] * 100 )
  elseif mode == 'clearall' then
    for i, v in pairs(timers) do
      timers[i][3] = 0
      timers[i][4] = 0
    end
  elseif mode == 'start' then
    timers[metric][1] = love.timer.getTime()
  elseif mode == 'end' then
    timers[metric][2] = love.timer.getTime() - timers[metric][1]
    timers[metric][3] = math.max(timers[metric][3], timers[metric][2])
    timers[metric][4] = timers[metric][4] + timers[metric][2]
  end
  
end