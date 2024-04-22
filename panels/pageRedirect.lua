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
   obj:setIcon('theme', vec(0, 0, 8, 8), vec(0, 8, 8, 8), vec(0, 16, 8, 8))
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

return 'pageRedirect', api, function(v) panels = v end