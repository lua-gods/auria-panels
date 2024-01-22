return host:isHost() and {
   render = function(model, time, chatOffset)
      local pos = client:getScaledWindowSize() * vec(0.5, 1)
      pos.x = pos.x + 95
      pos.y = pos.y + 8 - (1 - (1 - time) ^ 3) * 10
      pos.y = pos.y - chatOffset * 14
      model:setPos(-pos.xy_)
   end,
   renderElements = function(elements, updateElement, selected)
      local currentHeight = 0
      for i = #elements, 1, -1 do
         local v = elements[i]
         local height = updateElement(i, v)
         currentHeight = currentHeight + height
         v.renderData.pos = vec(-v.pos.x, currentHeight - v.pos.y)
      end
   end,
   default = '#a8a8a8',
   selected = '#ffffff',
   pressed = '#545454',
   outline = '#202020',
   on = '#54fb54',
   off = '#fb5454',
   sliderTextLight = '#ffffff',
   sliderTextDark = '#202020',
   sliderDefault = '#fca3c4',
   returnDefault = '#fc5454',
   returnSelected = '#ffaaba',
   returnPressed = '#884050'
}