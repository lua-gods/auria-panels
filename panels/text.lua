--- @class panelsPage
local myPageApi = {}
--- @class panelsApi 
local panels = {}
--- @class panelsElementText : panelsElementDefault
local methods = {}
local api = {page = myPageApi, methods = methods}

--- creates new panels text element
--- @param self panelsPage
--- @return panelsElementText
function myPageApi:newText()
   local obj = panels.newElement('text', self)
   obj.text = ''
   return obj
end

function api.press(obj)
   if obj.press then
      obj:press()
   end
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

--- sets function that will be called when text is pressed, returns itself for chaining
--- @param func function
--- @return panelsElementText
function methods:onPress(func)
   self.press = func
   return self
end

-- rendering
function api.createModel(model)
   model:newText('text'):setOutline(true)
end

function api.renderElement(data, isSelected, isPressed, model, tasks)
   local color = isPressed and panels.theme.pressed or isSelected and panels.theme.selected or panels.theme.default
   local text = toJson({
      text = data.text,
      color = color
   })
   tasks.text:setText(text)
   return 10
end

return 'text', api, function(v) panels = v end