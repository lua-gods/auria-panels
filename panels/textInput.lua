if not host:isHost() then return end
--- @class panelsPage
local myPageApi = {}
--- @class panelsApi 
local panels = {}
--- @class panelsElementTextInput : panelsElementDefault
local methods = {}
local api = {page = myPageApi, methods = methods}
local whitePixel = textures.whitePixel or textures:newTexture('whitePixel', 1, 1):pixel(0, 0, 1, 1, 1)

--- creates new panels text element
--- @param self panelsPage
--- @return panelsElementTextInput
function myPageApi:newTextInput()
   local obj = panels.newElement('textInput', self)
   obj.value = ''
   obj.keepCursor = false
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
      obj.value = modifier == 2 and '' or obj.value:sub(1, -2)
   elseif key == 67 and modifier == 2 then
      host:setClipboard(obj.value)
   elseif key == 86 and modifier == 2 then
      obj.value = host:getClipboard()
   elseif key == 'cancel' then
      obj.value = obj.previousValue
      return
   elseif key == 257 then
      panels.textInputElement = nil
   else return end
   obj.keepCursor = true
   return true
end

-- methods

-- rendering
function api.createModel(model)
   model:newSprite('line'):setTexture(whitePixel, 64, 1):setPos(0, -8, -1)
   model:newSprite('lineOutline'):setTexture(whitePixel, 66, 3):setPos(1, -7, 1)
   model:newText('cursor'):setText('|'):setOutline(true):setVisible(false)
end

function api.renderElement(obj, isSelected, isPressed, model, tasks)
   tasks.lineOutline:setColor(panels.theme.rgb.outline)
   tasks.line:setColor(obj == panels.textInputElement and panels.theme.rgb.selected or panels.theme.rgb.default)
   
   local isPlaceHolder = obj.value == ''
   local color
   if isPlaceHolder then
      color = isSelected and panels.theme.textInputPlaceHolderSelected or panels.theme.textInputPlaceHolder
   else
      color = isSelected and panels.theme.selected or panels.theme.default
   end
   tasks.text:setText(toJson({
      text = '',
      color = color,
      extra = {isPlaceHolder and obj.text or obj.value}
   }))
   
   
   local textWidth = client.getTextWidth('.'..obj.value..'.') - client.getTextWidth('..') -- add character at start and end to make it work with spaces
   tasks.cursor:setPos(-textWidth, 0, -2)
   return 12
end

return 'textInput', api, function(v) panels = v end