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
page:newColorPicker():setText('meow'):onColorChange(function(a, b) print(a) end):setColor(1, 0.5, 0)

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
-- add text mrroww
page3:newText():setText('mrrowww')

-- add return button so you can go back to previous page
page3:newReturnButton()

-- add button to test page to switch to mrrooww page 
page2:newPageRedirect():setPage(page3):setText('mrow')

-- add return button so you can go back to main page
page2:newReturnButton()