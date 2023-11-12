local panels = require('panels.main')

local page = panels.newPage()

panels.setPage(page)

local obj = page:newText()
obj:setText('meow')
obj:setSize(vec(2, 2))

page:newText():setText('meow')
page:newButton():setText('hello')
page:newText():setText('world'):setPos(20, 0)

page:newText():setText('cat')