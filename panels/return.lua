--- @class panelsPage
local myPageApi = {}
--- @class panelsApi 
local panels = {}
--- @class panelsElementReturn : panelsElementDefault
local methods = {}
local api = {page = myPageApi, methods = methods}

--- creates new panels text element
--- @param self panelsPage
--- @return panelsElementReturn
function myPageApi:newReturnButton()
   return panels.newElement('return', self)
end

function api.press()
   table.remove(panels.history)
   panels.setPage(panels.history[#panels.history])
end

-- rendering
function api.createModel(model)
   model:newText('text'):setOutline(true)
end

function api.renderElement(data, isSelected, isPressed, model, tasks)
   local color = isPressed and panels.theme.returnPressed or isSelected and panels.theme.returnSelected or panels.theme.returnDefault
   local text = toJson({
      text = 'return',
      color = color,
   })
   tasks.text:setText(text)
   return 10
end

return 'return', api, function(v) panels = v end