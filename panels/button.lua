local enabledColor = vec(0.33, 0.99, 0.33)
local disabledColor = vec(0.99, 0.33, 0.33)

--- @class panelsPage
local myPageApi = {}
--- @class panelsApi 
local panels = {}
--- @class panelsElementButton : panelsElementDefault
local methods = {}
local api = {page = myPageApi, methods = methods}

--- creates new panels text element
--- @param self panelsPage
--- @return panelsElementButton
function myPageApi:newButton()
   local obj = panels.newElement('button', self)
   obj.text = ''
   obj.toggled = false
   return obj
end

-- methods
--- set text of text element, returns itself for chaining
--- @overload fun(self: panelsElementButton, text: string): panelsElementButton
--- @overload fun(self: panelsElementButton, text: table): panelsElementButton
function methods:setText(text)
   self.text = text
   panels.reload()
   return self
end

--- sets function that will be called when button is toggled, returns itself for chaining
--- @param func function
--- @return panelsElementButton
function methods:onToggle(func)
   self.toggle = func
   return self
end

-- press
function api.press(obj)
   obj.toggled = not obj.toggled
   if obj.toggle then
      obj.toggle(obj.toggled, obj)
   end
   panels.anim(obj, 'toggle', 20, function(time, _, _, tasks)
      local c4 = math.pi * 2 / 3
      time = 2 ^ (-10 * time) * math.sin((time * 10 - 0.75) * c4) + 1
      if obj.toggled then
         time = 1 - time
      end
      tasks.toggle:setPos(time * 2 - 4)
   end)
end

-- rendering
function api.createModel(model)
   model:newText('text'):setOutline(true):setPos(-18, 0, 0)
   model:newText('toggle'):setOutline(true):setPos(-2, 0, 0)
   model:newText('toggleLeft'):setOutline(true):setPos(0, 0, 2)
   model:newText('toggleRight'):setOutline(true):setPos(-10, 0, 2)
end

function api.renderElement(data, isSelected, isPressed, model, tasks)
   -- text
   local selectColor = isPressed and panels.theme.pressed or isSelected and panels.theme.selected or panels.theme.default
   local text = toJson({
      text = '',
      color = selectColor,
      extra = {data.text}
   })
   tasks.text:setText(text)
   tasks.toggle:setText('{"text":"[]","color":"'..selectColor..'"}')
   -- toggle
   local toggleColor = data.toggled and panels.theme.on or panels.theme.off
   tasks.toggleLeft:setText('{"text":"[","color":"'..toggleColor..'"}')
   tasks.toggleRight:setText('{"text":"]","color":"'..toggleColor..'"}')
   tasks.toggle:setPos(data.toggled and -4 or -2, 0, 0)
   return 10
end

return 'button', api, function(v) panels = v end