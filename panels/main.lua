local panelsHud = models:newPart('panelshud', 'Hud'):pos(-2, -2)

--- @class panelsApi
local panelsApi = {}
local pages = {}
local currentPage = nil
local elements = {}
local needReload = false
local selected = 1
local selectedFull = 1
local animations = {}
--- @class panelsElementDefault
local defaultElementMethods = {}

--- @class panelsPage
local pageApi = {elements = {}}
local pageMetatable = {__index = pageApi}

--- creates new page
--- @param name? string
--- @return panelsPage
function panelsApi.newPage(name)
   local page = {
      elements = {}
   }
   pages[name or #pages+1] = page
   setmetatable(page, pageMetatable)
   return page
end

--- sets panel page to the one provided, you can also use name of page instead 
--- @overload fun(page: panelsPage)
--- @overload fun(pageName: string)
function panelsApi.setPage(page)
   -- remove all old parts
   if currentPage then
      for i, v in pairs(currentPage.elements) do
         panelsHud:removeChild(v.model)
      end
   end
   -- set page
   currentPage = pages[page] or page
   panelsApi.reload()
   animations = {}
   -- change selected element
   selected = 1
   selectedFull = 1
end

--- reload all panels elements
function panelsApi.reload()
   needReload = true
end

--- plays animation requires panel element, animation name, duration and function
--- @param obj any
--- @param name string
--- @param duration number
--- @param func function
function panelsApi.anim(obj, name, duration, func)
   if not animations[obj] then
      animations[obj] = {}
   end
   animations[obj][name] = {
      time = 0,
      duration = duration,
      func = func
   }
end

--- creates new element and adds it to page
--- @param name string
--- @param page panelsPage
--- @return table
function panelsApi.newElement(name, page)
   local obj = {
      type = name,
      pos = vec(0, 0),
      size = vec(1, 1)
   }
   setmetatable(obj, elements[name].metatable)
   table.insert(page.elements, obj)
   panelsApi.reload()
   return obj
end

--- sets pos of element, returns itself for self chaining
--- @overload fun(self: panelsElementDefault, x: number, y: number): panelsElementDefault
--- @overload fun(self: panelsElementDefault, x: Vector2): panelsElementDefault
function defaultElementMethods:setPos(x, y)
   if type(x) == 'Vector2' then
      self.pos = x
   else
      self.pos = vec(x, y)
   end
   return self
end

--- sets size of element, returns itself for self chaining
--- @overload fun(self: panelsElementDefault, x: number, y: number): panelsElementDefault
--- @overload fun(self: panelsElementDefault, x: Vector2): panelsElementDefault
function defaultElementMethods:setSize(x, y)
   if type(x) == 'Vector2' then
      self.size = x
   else
      self.size = vec(x, y)
   end
   return self
end

-- load elements
for _, file in pairs(listFiles(..., false)) do
   if not file:match('%.main$') then
      local name, api, getPanels = require(file)
      --- @cast api table
      for i, v in pairs(api.page) do
         pageApi[i] = v
      end
      -- give panels to element
      getPanels(panelsApi)
      -- create meatable
      local metatable = {
         __index = function(t, i) return api.methods[i] or defaultElementMethods[i] end
      }
      api.metatable = metatable
      elements[name] = api
   end
end

-- controls
local panelsClick = keybinds:newKeybind('panels - click', 'key.mouse.left')

panelsClick.press = function()
   if not currentPage then return end
   local obj = currentPage.elements[selectedFull]
   if elements[obj.type].press then
      elements[obj.type].press(obj)
      panelsApi.reload()
   end
   return true
end

function events.mouse_scroll(dir)
   if not currentPage then return end
   local oldSelectedFull = math.round(selected)
   selected = selected - dir
   selected = math.clamp(selected, 1, #currentPage.elements)
   selectedFull = math.round(selected)
   if oldSelectedFull ~= selectedFull then
      panelsApi.reload()
   end
   return true
end

-- rendering
function events.tick()
   for i, v in pairs(animations) do
      local haveAnimations = false
      for i2, v2 in pairs(v) do
         v2.time = v2.time + 1
         if v2.time > v2.duration + 2 then
            animations[i2] = nil
         else
            haveAnimations = true
         end
      end
      if not haveAnimations then
         animations[i] = nil
      end
   end
end

local function updateElement(i, v)
   return elements[v.type].renderElement(v, i == selectedFull, v.model, v.model:getTask())
end

function events.world_render(delta)
   if needReload then
      needReload = false
      
      panelsHud:removeTask()
      if currentPage then
         local height = 0
         for i, v in pairs(currentPage.elements) do
            if not v.model then
               v.model = panelsHud:newPart('element')
               elements[v.type].createModel(v.model)
            end
            v.model:setPos(- v.pos.xy_ - vec(0, height, 0))
            v.model:setScale(v.size.x, v.size.y, 1)
            local heightOffset = updateElement(i, v)
            height = height + heightOffset * v.size.y
         end
      end
   end

   for obj, anims in pairs(animations) do
      for name, data in pairs(anims) do
         local time = math.min(data.time + delta, data.duration) / data.duration
         data.func(time, obj, obj.model, obj.model:getTask())
      end
   end
end

return panelsApi