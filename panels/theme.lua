return host:isHost() and {
   updateOffsets = function(old, new)
      new.chat = math.lerp(old.chat or 0, host:isChatOpen() and 1 or 0, 0.25)
      new.offHandSlot = math.lerp(old.offHandSlot or 0, player:isLeftHanded() and player:getItem(2).id ~= 'minecraft:air' and 1 or 0, 0.25)
   end,
   render = function(model, time, offsets, pageAnim)
      local pos = client:getScaledWindowSize() * vec(0.5, 1)
      pos.x = pos.x + 95
      pos.y = pos.y + 8 - (1 - (1 - time) ^ 3) * 10
      pos.y = pos.y - math.max(
         -(math.cos(math.pi * offsets.chat) - 1) * 7,
         -(math.cos(math.pi * offsets.offHandSlot) - 1) * 11
      )
      pos.x = pos.x - pageAnim * 16
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

   icons = textures[(...):gsub('/', '.')..'.icons'],

   on = '#54fb54',
   off = '#fb5454',
   outline = '#202020',

   sliderTextLight = '#ffffff',
   sliderTextDark = '#202020',
   sliderDefault = '#fca3c4',
   sliderOutline = '#202020',

   default = '#a8a8a8',
   selected = '#ffffff',
   pressed = '#545454',

   returnDefault = '#fc5454',
   returnSelected = '#ffaaba',
   returnPressed = '#891e2b',

   textInputPlaceHolder = '#545454',
   textInputPlaceHolderSelected = '#8b8b8b'
}