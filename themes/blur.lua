if not host:isHost() then return end

local panels = require('panels.main')

local panelsHeight = 0
local panelsTime = 0
local enabledBefore = false
local theme = {
   updateOffsets = function(old, new)
   end,
   render = function(model, time, offsets, pageAnim)
      panelsTime = time
      local windowSize = client:getScaledWindowSize()
      local pos = windowSize * vec(0.5, 0.5)
      local openAnim = 1 - (1 - time) ^ 4 * 0.1
      openAnim = openAnim + pageAnim * 0.1
      pos.x = pos.x - 32 * openAnim
      pos.y = pos.y + panelsHeight * 0.5 * openAnim
      model:setPos(-pos.xy_)
      local scale = 1 * openAnim
      model:setScale(scale, scale)
   end,
   renderElements = function(elements, updateElement, selected)
      panelsHeight = 0
      for i = #elements, 1, -1 do
         local v = elements[i]
         local height = updateElement(i, v)
         panelsHeight = panelsHeight + height
         v.renderData.pos = vec(-v.pos.x, panelsHeight - v.pos.y)
      end
   end,
}

function events.world_render(delta)
   if panelsTime > 0.5 and panels.getTheme() == theme then
      renderer:postEffect('blur')
      enabledBefore = true
   elseif enabledBefore then
      renderer:postEffect()
      enabledBefore = false
   end
end

return theme