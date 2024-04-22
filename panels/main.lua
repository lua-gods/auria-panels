-- dont load panels when not host
if not host:isHost() then return setmetatable({}, {__index = function() error('panels are host only, add host:isHost() if check around your code that uses panels') end}) end

-- modelpart
local panelsHud = models:newPart('panelsHud', 'Hud')

--- @class panelsApi
local panelsApi = {history = {}}
--- @class panelsElementDefault
local defaultElementMethods = {}
local pages = {}
local currentPage = nil
local elements = {}
local needReload = false
local selected, selectedFull, selectedWithMouse = 0, 0, false
local panelsEnabled = false
local panelsEnableTime, panelsOldEnableTime = 0, 0
local chatOffset, oldChatOffset = 0, 0
local pageZoom, oldPageZoom = 0, 0
local animations = {}
local panelsPos = vec(0, 0)
local oldMousePos, mousePos = vec(0, 0), vec(0, 0)
local lastMinecraftScreen = nil

-- theme
local defaultTheme = require(.....'.theme')
local globalTheme = {}
local theme = {}
theme.rgb = {}
panelsApi.theme = theme
local function getThemeValue(i)
   return currentPage and currentPage.theme[i] or globalTheme[i] or defaultTheme[i]
end
setmetatable(theme, {
   __index = function(_, i)
      local v = getThemeValue(i)
      local vType = type(v)
      return vType == 'Vector3' and '#'..vectors.rgbToHex(v) or vType == 'string' and '#'..v:match('%x+') or v
   end
})
setmetatable(theme.rgb, {
   __index = function(_, i)
      local v = getThemeValue(i)
      local vType = type(v)
      return vType == 'Vector3' and v or vType == 'string' and vectors.hexToRGB(v) or v
   end
})

--- @class panelsPage
local pageApi = {elements = {}}
local pageMetatable = {__index = pageApi}

--- creates new page
--- @param name? string
--- @return panelsPage
function panelsApi.newPage(name)
   local page = {
      elements = {},
      theme = {}
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
function panelsApi.setPage(page, keepHistory, dontAddToHistory, reverseZoomAnimation, selectedElement)
   -- remove all old parts
   if currentPage then
      currentPage.lastSelectedElement = selectedFull
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
   if selectedElement then
      selected = selectedElement
   else
      selected = 0
      for i, v in pairs(currentPage.elements) do
         if v.type == 'return' then
            selected = i
            break
         end
      end
   end
   selectedFull = selected
   -- zoom animation
   if reverseZoomAnimation then
      pageZoom, oldPageZoom = 0.6, 1
   else
      pageZoom, oldPageZoom = -0.6, -1
   end
   -- update history
   if not keepHistory then panelsApi.history = {} end
   if not dontAddToHistory then table.insert(panelsApi.history, currentPage) end
   -- on open
   if currentPage.openFunc then currentPage.openFunc(currentPage) end
end

--- goes to previous page
function panelsApi.previousPage()
   if #panelsApi.history >= 2 then
      table.remove(panelsApi.history)
      local page = panelsApi.history[#panelsApi.history]
      panelsApi.setPage(page, true, true, true, page.lastSelectedElement)
   end
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
      size = vec(1, 1),
      margin = 0,
      text = '',
      icon = nil -- {texture = texture, uv = Vector4}
   }
   setmetatable(obj, elements[name].metatable)
   table.insert(page.elements, obj)
   panelsApi.reload()
   return obj
end

--- sets global theme for panels, check panels/theme.lua for default theme, giving nil as input will remove global theme
--- @param tbl table|nil
function panelsApi.setTheme(tbl)
   globalTheme = tbl or {}
end

--- removes element from page 
--- @param i number
--- @return self
function pageApi:removeElement(i)
   if not self.elements[i] then return self end
   if self.elements[i].renderData.model then
      panelsHud:removeChild(self.elements[i].renderData.model)
      panelsApi.reload()
   end
   table.remove(self.elements, i)
   return self
end

---removes all elements from page
---@return self
function pageApi:clear()
   if currentPage == self then
      for i, v in pairs(self.elements) do
         panelsHud:removeChild(v.renderData.model)
      end
   end
   self.elements = {}
   return self
end

---function called when page is open
---@param func fun(page: panelsPage)?
---@return self
function pageApi:onOpen(func)
   self.openFunc = func
   return self
end

---sets page theme, check panels/theme.lua to default theme, giving nil as input will remove page theme
---@param tbl table|nil
---@return self
function pageApi:setTheme(tbl)
   self.theme = tbl or {}
   return self
end

---sets pos of element, returns itself for self chaining
---@generic self
---@param self self
---@param x Vector2 | number
---@param y number
---@return self
function defaultElementMethods:setPos(x, y)
   if type(x) == 'Vector2' then
      self.pos = x
   else
      self.pos = vec(x, y)
   end
   panelsApi.reload()
   return self
end

---sets size of element, returns itself for self chaining
---@generic self
---@param self self
---@param x Vector2 | number
---@param y number
---@return self
function defaultElementMethods:setSize(x, y)
   if type(x) == 'Vector2' then
      self.size = x
   else
      self.size = vec(x, y)
   end
   panelsApi.reload()
   return self
end

---sets margin of element, returns itself for self chaining
---@generic self
---@param self self
---@param y number
---@return self
function defaultElementMethods:setMargin(y)
   self.margin = y
   panelsApi.reload()
   return self
end

--- set text of element, returns itself for chaining
---@generic self
---@param self self
---@param text string|table
---@return self
function defaultElementMethods:setText(text)
   self.text = text
   panelsApi.reload()
   return self
end

---sets icons for element, uv x, y is pos z, w is size, select uv and press uv will be used instead of uv when present and element is selected/pressed
---@generic self
---@param self self
---@param texture Texture|"theme"?
---@param uv Vector4?
---@param selectUv Vector4?
---@param pressUv Vector4?
---@return self
function defaultElementMethods:setIcon(texture, uv, selectUv, pressUv)
   if texture then
      self.icon = {
         texture = texture,
         uv = uv,
         selectUv = selectUv,
         pressUv = pressUv
      }
   else
      self.icon = nil
   end
   panelsApi.reload()
   return self
end

-- load elements
for _, file in pairs(listFiles(..., false)) do
   if not file:match('[./]main$') then
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
   model:getParent():setPos(obj.renderData.pos + vec(obj.renderData.selectOffset, 0, 0))
end

local function unselectElementAnim(time, obj, model, tasks)
   -- easing
   local c1, c3 = 1.7, 2.7
   time = 1 + c3 * (time - 1) ^ 3 + c1 * (time - 1) ^ 2
   -- apply animation
   obj.renderData.selectOffset = time * 4 - 4
   model:getParent():setPos(obj.renderData.pos + vec(obj.renderData.selectOffset, 0, 0))
end

local function setSelected(new, mouse)
   local oldSelectedFull = selectedFull
   selectedWithMouse = mouse
   selected = new and math.clamp(new, 1, #currentPage.elements) or 0
   selectedFull = math.round(selected)
   if oldSelectedFull ~= selectedFull then
      panelsApi.reload()
      -- unselect
      if currentPage.elements[oldSelectedFull] then
         panelsApi.anim(currentPage.elements[oldSelectedFull], 'selectElementAnim', 6, unselectElementAnim)
      end
      -- select
      if currentPage.elements[selectedFull] then
         panelsApi.anim(currentPage.elements[selectedFull], 'selectElementAnim', 6, selectElementAnim)
      end
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

local mouseClick = keybinds:newKeybind('panels - mouse click', 'key.mouse.left', true)
mouseClick.press = function()
   if host:isChatOpen() and selectedWithMouse then
      local obj = currentPage.elements[selectedFull]
      if obj and elements[obj.type].press then
         elements[obj.type].press(obj)
      end
      panelsApi.reload()
      return true
   end
end

mouseClick.release = panelsApi.reload

-- shift
local shift = keybinds:newKeybind('panels - shift', 'key.keyboard.left.shift', true)
shift.press = function()
   if panelsEnabled and currentPage then
      return panelsClick:isPressed()
   end
end

-- close panel
local escKey = keybinds:newKeybind('panels - close', 'key.keyboard.escape')
escKey.press = function()
   if panelsEnabled and not lastMinecraftScreen then
      panelsEnabled = false
      return true
   end
end

-- scroll
function events.mouse_scroll(dir)
   if not panelsEnabled or not currentPage then return end
   if host:isChatOpen() then
      local obj = currentPage.elements[selectedFull]
      if obj and selectedWithMouse and elements[obj.type].scroll then
         elements[obj.type].scroll(obj, dir, shift:isPressed())
         panelsApi.reload()
      end
   elseif not host:getScreen() then
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
end

-- rendering
function events.tick()
   lastMinecraftScreen = host:getScreen()
   -- panels animations
   panelsOldEnableTime = panelsEnableTime
   panelsEnableTime = math.clamp(panelsEnableTime + (panelsEnabled and 0.25 or -0.25), 0, 1)
   oldChatOffset = chatOffset
   chatOffset = math.lerp(chatOffset, host:isChatOpen() and 1 or 0, 0.25)
   oldPageZoom = pageZoom
   pageZoom = pageZoom * 0.6
   -- element animations
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
   -- mouse
   if not host:isChatOpen() then
      selectedWithMouse = false
      return
   elseif not currentPage then
      return
   end
   oldMousePos = mousePos
   mousePos = panelsPos - client:getMousePos() / client:getGuiScale()
   if mouseClick:isPressed() and selectedWithMouse then
      local obj = currentPage.elements[selectedFull]
      if obj and elements[obj.type].scroll then
         local dir = oldMousePos.x - mousePos.x
         elements[obj.type].scroll(obj, dir * 0.25, shift:isPressed())
         panelsApi.reload()
      end
      return
   end
   local closest = nil
   local dist = math.huge
   for i, v in pairs(currentPage.elements) do
      if v.renderData then
         local pos = v.renderData.pos.xy
         if mousePos >= pos - vec(128, v.renderData.heightNoMargin) and mousePos <= pos then
            local newDist = pos.x - mousePos.x
            if newDist < dist then
               closest = i
               dist = newDist
            end
         end
      end
   end
   if closest then
      setSelected(closest, true)
      return
   end
   if selectedWithMouse then
      setSelected()
   end
end

local function updateElement(i, v)
   local isSelected = i == selectedFull
   local isPressed = i == selectedFull and (host:isChatOpen() and mouseClick:isPressed() or panelsClick:isPressed())
   local model = v.renderData.elementModel
   local tasks = model:getTask()
   -- update text and icon
   tasks.text:setText(toJson({
      text = '',
      color = isPressed and theme.pressed or isSelected and theme.selected or theme.default,
      extra = {v.text}
   }))
   if v.icon then
      tasks.icon:setVisible(true)
      model:setPos(-9, 0, 0)
      local iconTexture = v.icon.texture
      if iconTexture == 'theme' then iconTexture = theme.icons end
      local textureSize = iconTexture:getDimensions()
      tasks.icon:setTexture(iconTexture, textureSize.x, textureSize.y):setScale(8 / textureSize.x, 8 / textureSize.y, 0)
      local uv = isPressed and v.icon.pressUv or isSelected and v.icon.selectUv or v.icon.uv
      if v.icon.uv then
         tasks.icon:setUV(uv.xy / textureSize):setRegion(uv.zw)
      else
         tasks.icon:setRegion(textureSize)
      end
   else
      model:setPos(0, 0, 0)
      tasks.icon:setVisible(false)
   end
   -- render element
   local height = elements[v.type].renderElement and elements[v.type].renderElement(v, isSelected, isPressed, model, tasks) or 10
   -- calculate height
   height = height * v.size.y
   v.renderData.heightNoMargin = height
   height = height + v.margin
   v.renderData.height = height
   return height
end

function events.world_render(delta)
   local panelsTime = math.lerp(panelsOldEnableTime, panelsEnableTime, delta)
   panelsHud:setVisible(panelsTime > 0)
   if panelsTime == 0 then return end
   -- render panels
   local chatOffsetTime = math.lerp(oldChatOffset, chatOffset, delta)
   chatOffsetTime = -(math.cos(math.pi * chatOffsetTime) - 1) / 2
   theme.render(
      panelsHud,
      panelsTime,
      chatOffsetTime,
      math.lerp(oldPageZoom, pageZoom, delta)
   )
   panelsPos = -panelsHud:getPos().xy or vec(0, 0)
   if needReload then
      needReload = false
      
      if currentPage then
         -- create render data
         for i, v in pairs(currentPage.elements) do
            if not v.renderData then
               v.renderData = {
                  model = panelsHud:newPart('element'),
                  selectOffset = i == selectedFull and -4 or 0,
                  height = 0,
                  pos = vec(0, 0)
               }
               v.renderData.elementModel = v.renderData.model:newPart('')
               v.renderData.elementModel:newText('text'):setOutline(true)
               v.renderData.elementModel:newSprite('icon'):pos(10, 0, 0)
               if elements[v.type].createModel then elements[v.type].createModel(v.renderData.elementModel) end
            end
         end
         -- render
         theme.renderElements(currentPage.elements, updateElement, selectedFull)
         -- set postion and scale
         for i, v in pairs(currentPage.elements) do
            v.renderData.pos = v.renderData.pos:augmented(i == selectedFull and -10 or 0)
            v.renderData.model:setPos(v.renderData.pos + vec(v.renderData.selectOffset, 0, 0))
            v.renderData.model:setScale(v.size.x, v.size.y, 1)
         end
      end
   end

   for obj, anims in pairs(animations) do
      for name, data in pairs(anims) do
         local time = math.min(data.time + delta, data.duration) / data.duration
         local model = obj.renderData.elementModel
         data.func(time, obj, model, model:getTask())
      end
   end
end

return panelsApi