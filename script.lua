local panels = require('panels.main')

local page = panels.newPage()

panels.setPage(page)

local obj = page:newText()
obj:setText('meow')
obj:setSize(vec(2, 2))

page:newButton():setText({text = '△', font = 'figura:badges'})
page:newButton():setText('hello | off'):onToggle(function(toggled, self) self:setText(toggled and 'hello | on' or 'hello | off') end)
page:newText():setText('world'):setPos(20, 0)

page:newText():setText({text = ':cat: cat', color = '#ed773b'}):onPress(function(self) self:setText({text = ':cat: meow', color = '#fcc64f'}) end)

page:newPageRedirect():setText('test'):setPage('test')

local page2 = panels.newPage('test')

page2:newButton():setText('button1')
page2:newButton():setText('button2')
page2:newButton():setText('button3')
page2:newButton():setText('button4')
page2:newButton():setText('button5')

page2:newPageRedirect():setText('main'):setPage(page)