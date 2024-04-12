-- stop script if not host
if not host:isHost() then return end

-- require panels
local panels = require('panels.main')

-- create new page called main
local page = panels.newPage('main')

-- set current page to that page
panels.setPage(page)

-- create new text element with text 'meow' and size 2, 2
local obj = page:newText()
obj:setText('meow')
obj:setSize(2, 2)
obj:setMargin(4)

-- create text with figura triangle as text
page:newToggle():setText({text = '△', font = 'figura:badges'}):setMargin(-10)

page:newToggle():setText('meow'):setPos(50, 0)

-- create toggle
page:newToggle():setText('hello | off'):onToggle(function(toggled, self) self:setText(toggled and 'hello | on' or 'hello | off') end)

-- hue slider
page:newSlider():setText('hue'):setColor(1, 0, 0):setMax(360):setValue(0):setStep(10, 1):allowWarping(true):onScroll(function(value, self) self:setColor(vectors.hsvToRGB(value / 360, 1, 1)) end)

-- a text that changes when pressed
page:newText():setText({text = ':cat: cat', color = '#ed773b'}):onPress(function(self) self:setText({text = ':cat: meow', color = '#fcc64f'}) end)

-- color picker that prints color when its changed
page:newColorPicker():onColorChange(function(a)
   printJson('{"text":"'..tostring(a)..'","color":"#'..vectors.rgbToHex(a)..'"}')
end):setColor(1, 0.5, 0):setText('meow')

-- button to switch to different page
page:newPageRedirect():setText('test'):setPage('test')

-- test page
local page2 = panels.newPage('test')

-- some random example toggle
page2:newToggle():setText('always on'):onToggle(function(_, self) self:setToggled(true) end):setToggled(true)
page2:newToggle():setText('always off'):onToggle(function(_, self) self:setToggled(false) end)
page2:newToggle():setText('toggle 3')
page2:newToggle():setText('toggle 4')
page2:newToggle():setText('toggle 5'):setToggled(true)

-- normal slider
page2:newSlider():setRange(10, 30)

-- create mrrowww page
local page3 = panels.newPage('mrrooww')

page3:setTheme({
   render = function(model, time, chatOffset, pageZoom)
      local pos = client:getScaledWindowSize() * vec(0.5, 0)
      time = (1 - time) ^ 3
      pos.y = 64 - (1 - time) * 32
      model:setPos(-pos.xy_)
      local scale = 1 + pageZoom * 0.2
      model:setScale(scale * (1 - time * vec(0.5, 1, 1)))
   end,
   renderElements = function(elements, updateElement, selected)
      local currentHeight = 0
      local offset = math.floor(#elements / 8) * 32
      for i, v in pairs(elements) do
         local height = updateElement(i, v)
         v.renderData.pos = vec(offset - v.pos.x, currentHeight - v.pos.y)
         currentHeight = currentHeight - height
         if i % 8 == 0 then
            offset = offset - 64
            currentHeight = 0
         end
      end
   end,
   sliderDefault = '#fb5454',
   on = '#fb5454',
   off = '#545454',
   returnSelected = '#ffaaaa',
})

-- add meows
local meows = {'meow', 'miau', 'mrow', 'mraw', 'moew', 'mrow'}
for _ = 1, 26 do
   page3:newText():setText(meows[math.random(#meows)])
end
page3:newText():setText('miau')
page3:newText():setText('mrow')
page3:newSlider():setText('mraw')
page3:newToggle():setText('moew')
page3:newToggle():setText('mrow')

-- add return button so you can go back to previous page
page3:newReturnButton()

-- add button to test page to switch to mrrooww page 
page2:newPageRedirect():setPage(page3):setText('mrow')

-- add return button so you can go back to main page
page2:newReturnButton()