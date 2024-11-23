if not host:isHost() then return end
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
   return panels.newElement('text', self)
end

function api.press(obj)
   if obj.press then
      obj.press(obj)
   end
end

-- methods
--- sets function that will be called when text is pressed, returns itself for chaining
--- @param func fun(obj: panelsElementText)
--- @return self
function methods:onPress(func)
   self.press = func
   return self
end

-- rendering
--[[@@@
function api.createModel(model)
end

function api.renderElement(data, isSelected, isPressed, model, tasks)
   return 10 -- default value
end
]]

return 'text', api, function(v) panels = v end