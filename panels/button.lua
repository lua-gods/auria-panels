local enabledColor = vec(0.33, 0.99, 0.33)
local disabledColor = vec(0.99, 0.33, 0.33)

--- @class panelsPage
local myPageApi = {}
--- @class panelsApi 
local panels = {}
--- @class panelsElementText : panelsElementDefault
local methods = {}
local api = {page = myPageApi, methods = methods}

--- creates new panels text element
--- @param self panelsPage
--- @return table
function myPageApi:newButton()
   local obj = panels.newElement('button', self)
   obj.text = ''
   obj.toggled = false
   return obj
end

-- methods
--- set text of text element, returns itself for chaining
--- @param text string
--- @return panelsElementText
function methods:setText(text)
   self.text = text
   panels.reload()
   return self
end


-- press
function api.press(obj)
   obj.toggled = not obj.toggled
   panels.anim(obj, 'toggle', 10, function(time, _, _, tasks)
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

function api.renderElement(data, isSelected, model, tasks)
   -- text
   local selectColor = isSelected and 'white' or 'gray'
   local text = toJson({
      text = data.text,
      color = selectColor
   })
   tasks.text:setText(text)
   tasks.toggle:setText('{"text":"[]","color":"'..selectColor..'"}')
   -- toggle
   local toggleColor = data.toggled and enabledColor or disabledColor
   toggleColor = '#' .. vectors.rgbToHex(toggleColor)
   tasks.toggleLeft:setText('{"text":"[","color":"'..toggleColor..'"}')
   tasks.toggleRight:setText('{"text":"]","color":"'..toggleColor..'"}')
   tasks.toggle:setPos(data.toggled and -4 or -2, 0, 0)
   return 10
end

return 'button', api, function(v) panels = v end