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

-- methods
--- set text of text element, returns itself for chaining
--- @param text string
--- @return panelsElementText
function methods:setText(text)
   self.text = text
   panels.reload()
   return self
end

-- rendering
function api.createModel(model)
   model:newText('text'):setOutline(true)
end

function api.renderElement(data, isSelected, model, tasks)
   local text = toJson({
      text = data.text,
      color = isSelected and 'white' or 'gray'
   })
   tasks.text:setText(text)
   return 10
end

return 'text', api, function(v) panels = v end