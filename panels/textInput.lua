if not host:isHost() then return end
--- @class panelsPage
local myPageApi = {}
--- @class panelsApi 
local panels = {}
--- @class panelsElementTextInput : panelsElementDefault
--- @field value string
local methods = {}
local api = {page = myPageApi, methods = methods}
local whitePixel = textures.whitePixel or textures:newTexture('whitePixel', 1, 1):pixel(0, 0, 1, 1, 1)

--- creates new panels text input element
--- @param self panelsPage
--- @return panelsElementTextInput
function myPageApi:newTextInput()
   local obj = panels.newElement('textInput', self)
   obj.value = ''
   obj.keepCursor = false
   obj.inputAccepted = nil
   obj.inputCanceled = nil
   obj.inputChanged = nil
   return obj
end

local function cursorAnim(time, obj, _, tasks)
   tasks.cursor:setVisible(obj == panels.textInputElement and (time < 0.5 or obj.keepCursor))
end

local function playCursorAnim(obj)
   obj.keepCursor = false
   if obj == panels.textInputElement then
      panels.anim(obj, 'cursorBlink', 20, cursorAnim, playCursorAnim)
   end
end

function api.press(obj)
   obj.previousValue = obj.value
   panels.setTextInputElement(obj)
   playCursorAnim(obj)
end

function api.textInput(obj, char, key, modifier) -- backspace 259, crtl + c 67 2, crtl + v 86 2, escape 256, enter 257
   if char then
      obj.value = obj.value..char
   elseif key == 259 then
      if modifier == 3 then
         obj.value = ''
      elseif modifier == 2 then
         obj.value = obj.value:gsub('%s*%S*$', '')
      else
         obj.value = obj.value:gsub("[\x00-\x7F\xC2-\xF4][\x80-\xBF]*$", "", 1)
      end
   elseif key == 67 and modifier == 2 then
      host:setClipboard(obj.value)
   elseif key == 86 and modifier == 2 then
      obj.value = host:getClipboard()
   elseif key == 'cancel' then
      panels.setTextInputElement(nil, true)
      obj.value = obj.previousValue
      if obj.inputCanceled then obj.inputCanceled(obj.value, obj) end
      return true
   elseif key == 257 then
      panels.setTextInputElement()
      if obj.inputAccepted then obj.inputAccepted(obj.value, obj) end
      return true
   else return end
   obj.keepCursor = true
   if obj.inputChanged then obj.inputChanged(obj.value, obj) end
   return true
end

function api.textInputFinished(obj)
   if obj.inputAccepted then obj.inputAccepted(obj.value, obj) end
end

-- methods
--- sets function that will be called when text input is accepted, returns itself for chaining
--- @param func fun(text: string, obj: panelsElementTextInput)
--- @return self
function methods:onInputAccepted(func)
   self.inputAccepted = func
   return self
end

--- sets function that will be called when text input is canceled, returns itself for chaining
--- @param func fun(text: string, obj: panelsElementTextInput)
--- @return self
function methods:onInputCanceled(func)
   self.inputCanceled = func
   return self
end

--- sets function that will be called when text input is changed, returns itself for chaining
--- @param func fun(text: string, obj: panelsElementTextInput)
--- @return self
function methods:onInputChanged(func)
   self.inputChanged = func
   return self
end

---sets text typed into text input
---@param text string
---@return self
function methods:setValue(text)
   self.value = text
   return self
end

-- rendering
function api.createModel(model)
   model:newSprite('line'):setTexture(whitePixel, 1, 1):setPos(0, -8, -1)
   model:newSprite('lineOutline'):setTexture(whitePixel, 1, 3):setPos(1, -7, 1)
   model:newText('cursor'):setText('|'):setOutline(true):setVisible(false)
end

local function getTextWidth(str)
   return client.getTextWidth('.'..str..'.') - client.getTextWidth('..') -- add character at start and end to make it work with spaces
end

function api.renderElement(obj, isSelected, isPressed, model, tasks)
   local isPlaceHolder = obj.value == ''
   local text = isPlaceHolder and obj.text or obj.value
   local textWidth = getTextWidth(text)
   local lineWidth = math.clamp(textWidth, 64, 128)
   if textWidth > 118 then
      local range = vec(1, 64)
      for _ = 1, 6 do
         local half = math.floor((range.x + range.y) * 0.5)
         local width = getTextWidth(obj.value:sub(-half, -1))
         if width > 118 then
            range.y = half
         else
            range.x = half + 1
         end
      end
      text = range.x < #obj.value and '...'..text:sub(-range.x, -1) or text
      textWidth = getTextWidth(text)
   end

   tasks.cursor:setPos(isPlaceHolder and 0 or -textWidth, 0, -2)
   
   tasks.lineOutline:setColor(panels.theme.rgb.outline):setScale(lineWidth + 2, 1, 1)
   tasks.line:setColor(obj == panels.textInputElement and panels.theme.rgb.selected or panels.theme.rgb.default):setScale(lineWidth, 1, 1)
   
   local color
   if isPlaceHolder then
      color = isSelected and panels.theme.textInputPlaceHolderSelected or panels.theme.textInputPlaceHolder
   else
      color = isSelected and panels.theme.selected or panels.theme.default
   end
   tasks.text:setText(toJson({
      text = '',
      color = color,
      extra = {text}
   }))

   return 12
end

return 'textInput', api, function(v) panels = v end