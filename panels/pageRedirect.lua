if not host:isHost() then return end
--- @class panelsPage
local myPageApi = {}
--- @class panelsApi 
local panels = {}
--- @class panelsElementPageRedirect : panelsElementDefault
local methods = {}
local api = {page = myPageApi, methods = methods}

--- creates new panels page redirect element
--- @param self panelsPage
--- @return panelsElementPageRedirect
function myPageApi:newPageRedirect()
   local obj = panels.newElement('pageRedirect', self)
   obj:setIcon(panels.theme.icons, vec(0, 0, 8, 8))
   return obj
end

function api.press(obj)
   if obj.page then
      panels.setPage(obj.page, true)
   end
end

-- methods

--- sets function that will be called when text is pressed, returns itself for chaining
--- @overload fun(self: panelsElementPageRedirect, page: panelsPage): panelsElementPageRedirect
--- @overload fun(self: panelsElementPageRedirect, page: string): panelsElementPageRedirect
function methods:setPage(page)
   self.page = page
   return self
end

-- rendering
function api.createModel(model)
   model:newText('text'):setOutline(true)
end

function api.renderElement(data, isSelected, isPressed, model, tasks)
   return 10
end

return 'pageRedirect', api, function(v) panels = v end