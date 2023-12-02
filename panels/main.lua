-- load theme
local theme = require(.....'.theme')

-- modelpart
local panelsHud = models:newPart('panelsHud', 'Hud')

--- @class panelsApi
local panelsApi = {history = {}}
local pages = {}
local currentPage = nil
local elements = {}
local needReload = false
local selected = 0
local selectedFull = 0
local panelsEnabled = false
local panelsEnableTime, panelsOldEnableTime = 0, 0
local animations = {}
--- @class panelsElementDefault
local defaultElementMethods = {}

-- generate rgb colors for theme
theme.rgb = {}
for i, v in pairs(theme) do
   if type(v) == 'string' then
      theme.rgb[i] = vectors.hexToRGB(v)
   end
end
panelsApi.theme = theme

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
   if name then
      pages[name] = page
   end
   setmetatable(page, pageMetatable)
   return page
end

--- sets panel page to the one provided, you can also use name of page instead 
--- @overload fun(page: panelsPage, keepHistory: boolean?, dontAddToHistory: boolean?)
--- @overload fun(pageName: string, keepHistory: boolean?, dontAddToHistory: boolean?)
function panelsApi.setPage(page, keepHistory, dontAddToHistory)
   -- remove all old parts
   if currentPage then
      for i, v in pairs(currentPage.elements) do
         panelsHud:removeChild(v.renderData.model)
         v.renderData = nil
      end
   end
   -- set page
   currentPage = pages[page] or page --- @cast currentPage panelsPage
   panelsApi.reload()
   animations = {}
   -- change selected element
   selected = 0
   selectedFull = 0
   -- update history
   if not keepHistory then panelsApi.history = {} end
   if not dontAddToHistory then table.insert(panelsApi.history, page) end
   -- on open
   if currentPage.openFunc then currentPage.openFunc(currentPage) end
end

--- goes to previous page
function panelsApi.previousPage()
   table.remove(panelsApi.history)
   panelsApi.setPage(panelsApi.history[#panelsApi.history], true, true)
end

--- gets created page with specific name, returns nil if doesnt exist
--- @param name string
--- @return panelsPage?
function panelsApi.getPage(name)
   return pages[name]
end

--- returns currently opened page
--- @return panelsPage?
function panelsApi.getCurrentPage()
   return currentPage
end

--- reload all panels elements
function panelsApi.reload()
   needReload = true
end

--- plays animation requires panel element, animation name, duration and function
--- @param obj panelsElementDefault
--- @param name string
--- @param duration number
--- @param func fun(time: number, obj: panelsElementDefault, model: ModelPart, tasks: table<string, RenderTask>)
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


--- removes element from page 
--- @param i number
function pageApi:removeElement(i)
   if not self.elements[i] then return end
   if self.elements[i].renderData.model then
      panelsHud:removeChild(self.elements[i].renderData.model)
      panelsApi.reload()
   end
   table.remove(self.elements, i)
   return self
end

--- removes all elements from page
function pageApi:clear()
   if currentPage == self then
      for i, v in pairs(self.elements) do
         panelsHud:removeChild(v.renderData.model)
      end
   end
   self.elements = {}
   return self
end

--- function called when page is open
--- @param func fun(page: panelsPage)?
--- @return panelsPage
function pageApi:onOpen(func)
   self.openFunc = func
   return self
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
   panelsApi.reload()
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
   panelsApi.reload()
   return self
end

-- load elements
for _, file in pairs(listFiles(..., false)) do
   if not file:match('%.main$') then
      local name, api, getPanels = require(file)
      if type(name) == 'string' and type(api) == 'table' then
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
end

-- controls
local function selectElementAnim(time, obj, model, tasks)
   -- easing
   local c1, c3 = 1.7, 2.7
   time = 1 + c3 * (time - 1) ^ 3 + c1 * (time - 1) ^ 2
   -- apply animation
   obj.renderData.selectOffset = time * -4
   model:setPos(obj.renderData.renderedPos + vec(obj.renderData.selectOffset, 0, 0))
end

local function unselectElementAnim(time, obj, model, tasks)
   -- easing
   local c1, c3 = 1.7, 2.7
   time = 1 + c3 * (time - 1) ^ 3 + c1 * (time - 1) ^ 2
   -- apply animation
   obj.renderData.selectOffset = time * 4 - 4
   model:setPos(obj.renderData.renderedPos + vec(obj.renderData.selectOffset, 0, 0))
end

local function setSelected(new)
   local oldSelectedFull = selectedFull
   selected = math.clamp(new, 1, #currentPage.elements)
   selectedFull = math.round(selected)
   if oldSelectedFull ~= selectedFull then
      panelsApi.reload()
      -- unselect
      if currentPage.elements[oldSelectedFull] then
         panelsApi.anim(currentPage.elements[oldSelectedFull], 'selectElementAnim', 6, unselectElementAnim)
      end
      -- select
      panelsApi.anim(currentPage.elements[selectedFull], 'selectElementAnim', 6, selectElementAnim)
   end
end

-- open panel, click
local f3 = keybinds:newKeybind('panels - f3', 'key.keyboard.f3') -- prevent overriding f3 keybinds
local panelsClick = keybinds:fromVanilla('figura.config.action_wheel_button')
panelsClick.press = function()
   if f3:isPressed() then return end
   if not currentPage then return end
   if panelsEnabled then
      local obj = currentPage.elements[selectedFull]
      if obj and elements[obj.type].press then
         elements[obj.type].press(obj)
      end
      panelsApi.reload()
   else
      panelsEnabled = true
   end
   return true
end

panelsClick.release = panelsApi.reload

-- shift
local shift = keybinds:newKeybind('panels - shift', 'key.keyboard.left.shift')
shift.press = function()
   if panelsEnabled and currentPage then
      return panelsClick:isPressed()
   end
end

-- close panel
local escKey = keybinds:newKeybind('panels - close', 'key.keyboard.escape')
escKey.press = function()
   if panelsEnabled then
      panelsEnabled = false
      return true
   end
end

-- scroll
function events.mouse_scroll(dir)
   if not panelsEnabled or not currentPage or host:getScreen() then return end
   if panelsClick:isPressed() then
      local obj = currentPage.elements[selectedFull]
      if obj and elements[obj.type].scroll then
         elements[obj.type].scroll(obj, dir, shift:isPressed())
         panelsApi.reload()
      end
   else
      setSelected(selected - dir)
   end
   return true
end

-- rendering
function events.tick()
   panelsOldEnableTime = panelsEnableTime
   panelsEnableTime = math.clamp(panelsEnableTime + (panelsEnabled and 0.25 or -0.25), 0, 1)
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
   return elements[v.type].renderElement(v, i == selectedFull, i == selectedFull and panelsClick:isPressed(), v.renderData.model, v.renderData.model:getTask())
end

function events.world_render(delta)
   local panelsTime = math.lerp(panelsOldEnableTime, panelsEnableTime, delta)
   local panelsPos = client:getScaledWindowSize() * vec(0.5, 1)
   panelsPos.x = panelsPos.x + 95
   panelsPos.y = panelsPos.y + 8 - (1 - (1 - panelsTime) ^ 3) * 10
   panelsHud:setPos(-panelsPos.xy_)
   panelsHud:setVisible(panelsTime > 0)
   if needReload and panelsTime > 0 then
      needReload = false
      
      panelsHud:removeTask()
      if currentPage then
         local height = 0
         for i = #currentPage.elements, 1, -1 do
            local v = currentPage.elements[i]
            if not v.renderData then
               v.renderData = {
                  model = panelsHud:newPart('element'),
                  selectOffset = 0,
               }
               elements[v.type].createModel(v.renderData.model)
            end
            local heightOffset = updateElement(i, v)
            height = height + heightOffset * v.size.y
            v.renderData.renderedPos = vec(-v.pos.x, height - v.pos.y, i == selectedFull and -10 or 0)
            v.renderData.model:setPos(v.renderData.renderedPos + vec(v.renderData.selectOffset, 0, 0))
            v.renderData.model:setScale(v.size.x, v.size.y, 1)
         end
      end
   end

   for obj, anims in pairs(animations) do
      for name, data in pairs(anims) do
         local time = math.min(data.time + delta, data.duration) / data.duration
         data.func(time, obj, obj.renderData.model, obj.renderData.model:getTask())
      end
   end
end

return panelsApi