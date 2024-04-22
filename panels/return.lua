if not host:isHost() then return end
--- @class panelsPage
local myPageApi = {}
--- @class panelsApi 
local panels = {}
--- @class panelsElementReturn : panelsElementDefault
local methods = {}
local api = {page = myPageApi, methods = methods}

--- creates new panels return element
--- @param self panelsPage
--- @return panelsElementReturn
function myPageApi:newReturnButton()
   local obj = panels.newElement('return', self)
   obj.text = 'return'
   obj:setIcon('theme', vec(8, 0, 8, 8), vec(8, 8, 8, 8), vec(8, 16, 8, 8))
   return obj
end

function api.press(obj)
   if obj.func then
      obj.func(obj)
   end
   panels.previousPage()
end

--- sets function that will be called when returning to previous page, returns itself for chaining
--- @param func fun(obj: panelsElementReturn)
--- @return panelsElementReturn
function methods:onReturn(func)
   self.func = func
   return self
end

-- rendering
function api.renderElement(data, isSelected, isPressed, model, tasks)
   local color = isPressed and panels.theme.returnPressed or isSelected and panels.theme.returnSelected or panels.theme.returnDefault
   local text = toJson({
      text = data.text,
      color = color,
   })
   tasks.text:setText(text)
end

return 'return', api, function(v) panels = v end