--- @class panelsPage
local myPageApi = {}
--- @class panelsApi 
local panels = {}
--- @class panelsElementColorPicker : panelsElementDefault
local methods = {}
local api = {page = myPageApi, methods = methods}
local whitePixel = textures.whitePixel or textures:newTexture('whitePixel', 1, 1):setPixel(0, 0, 1, 1, 1)

-- page
local page, currentColor, updateElements, colorPickerObj
local function pageInit()
   local function updateColor()
      if currentColor ~= colorPickerObj.color then
         colorPickerObj.color = currentColor
         if colorPickerObj.func then
            colorPickerObj.func(currentColor, colorPickerObj)
         end
      end
   end

   page = panels.newPage()
   local colorPresetsPage = panels.newPage()

   local colorPreview = page:newColorPicker():setEnabled(false):onPress(updateColor)

   local red = page:newSlider():setRange(0, 255):setStep(16, 1):setText('red')
   local green = page:newSlider():setRange(0, 255):setStep(16, 1):setText('green')
   local blue = page:newSlider():setRange(0, 255):setStep(16, 1):setText('blue')
   local hue = page:newSlider():setRange(0, 360):setStep(20, 1):allowWarping(true):setText('hue')
   local saturation = page:newSlider():setRange(0, 100):setStep(10, 1):setText('saturation')
   local value = page:newSlider():setRange(0, 100):setStep(10, 1):setText('value')
   red:onScroll(function(v) currentColor.r = v / 255 updateElements() end)
   green:onScroll(function(v) currentColor.g = v / 255 updateElements() end)
   blue:onScroll(function(v) currentColor.b = v / 255 updateElements() end)
   hue:onScroll(function(v) local hsv = vectors.rgbToHSV(currentColor) hsv.x = v / 360 currentColor = vectors.hsvToRGB(hsv) updateElements() end)
   saturation:onScroll(function(v) local hsv = vectors.rgbToHSV(currentColor) hsv.y = v / 100 currentColor = vectors.hsvToRGB(hsv) updateElements() end)
   value:onScroll(function(v) local hsv = vectors.rgbToHSV(currentColor) hsv.z = v / 100 currentColor = vectors.hsvToRGB(hsv) updateElements() end)

   page:newPageRedirect():setText('presets'):setPage(colorPresetsPage)

   page:newReturnButton():onReturn(updateColor)

   function updateElements()
      colorPreview:setColor(currentColor):setText('#' .. vectors.rgbToHex(currentColor))
      red:setValue(currentColor.r * 255):setColor(1, 0, 0)
      green:setValue(currentColor.g * 255):setColor(0, 1, 0)
      blue:setValue(currentColor.b * 255):setColor(0, 0, 1)
      local hsv = vectors.rgbToHSV(currentColor)
      hue:setValue(math.round(hsv.x * 360)):setColor(vectors.hsvToRGB(hsv.x, 1, 1))
      saturation:setValue(math.round(hsv.y * 100)):setColor(vectors.hsvToRGB(hsv.x, hsv.y, 1))
      value:setValue(math.round(hsv.z * 100)):setColor(vectors.hsvToRGB(0, 0, hsv.z))
   end

   local colors = {
      {"#000000", "black"},
      {"#2f2f2f", "dark gray"},
      {"#bcbfc4", "light gray"},
      {"#ffffff", "white"},
      {"#69453f", "brown"},
      {"#ff5757", "red"},
      {"#ff7a45", "orange"},
      {"#ffed66", "yellow"},
      {"#bdff66", "lime"},
      {"#52d156", "green"},
      {"#59fff1", "light blue"},
      {"#50aaad", "cyan"},
      {"#424fff", "blue"},
      {"#9a4dff", "purple"},
      {"#ff4dff", "magenta"},
      {"#ff82ac", "pink"},
   }
   for _, v in pairs(colors) do
      local color = vectors.hexToRGB(v[1])
      colorPresetsPage:newColorPicker():setEnabled(false):setColor(color):setText(v[2]):onPress(function()
         currentColor = color
         updateElements()
         updateColor()
         panels.previousPage()
      end)
   end
   colorPresetsPage:newReturnButton()
end

--- creates new panels color picker element
--- @param self panelsPage
--- @return panelsElementColorPicker
function myPageApi:newColorPicker()
   local obj = panels.newElement('colorPicker', self)
   obj.text = ''
   obj.color = vec(1, 1, 1)
   obj.enabled = true
   return obj
end

function api.press(obj)
   if not page then pageInit() end
   if obj.press then obj.press(obj) end
   if not obj.enabled then return end
   currentColor = obj.color:copy()
   colorPickerObj = obj
   updateElements()
   panels.setPage(page, true)
end

-- methods
--- set text of element, returns itself for chaining
--- @overload fun(text: string): panelsElementColorPicker
--- @overload fun(text: table): panelsElementColorPicker
function methods:setText(text)
   self.text = text
   panels.reload()
   return self
end

--- sets if element is enabled, returns itself for chaining
--- @overload fun(enabled: boolean): panelsElementColorPicker
function methods:setEnabled(enabled)
   self.enabled = enabled
   return self
end

--- set color of element, returns itself for chaining
--- @overload fun(self: panelsElementColorPicker, r: number, g: number, b: number): panelsElementColorPicker
--- @overload fun(self: panelsElementColorPicker, color: Vector3): panelsElementColorPicker
function methods:setColor(r, g, b)
   if type(r) == 'Vector3' then
      self.color = r 
   else
      self.color = vec(r, g, b) 
   end
   panels.reload()
   return self
end


--- sets function that will be called when color is changed, returns itself for chaining
--- @param func fun(color: Vector3, obj: panelsElementColorPicker)
--- @return panelsElementColorPicker
function methods:onColorChange(func)
   self.func = func
   return self
end

--- sets function that will be called when opening color picker, returns itself for chaining
--- @param func fun(obj: panelsElementColorPicker)
--- @return panelsElementColorPicker
function methods:onPress(func)
   self.press = func
   return self
end

-- rendering
function api.createModel(model)
   model:newText('text'):setOutline(true):setPos(-10, 0)
   model:newSprite('color'):setTexture(whitePixel, 7, 7)
   model:newSprite('colorBg'):setTexture(whitePixel, 9, 9):setPos(1, 1, 0)
end

function api.renderElement(data, isSelected, isPressed, model, tasks)
   local color = isPressed and panels.theme.pressed or isSelected and panels.theme.selected or panels.theme.default
   local text = toJson({
      text = '',
      color = color,
      extra = {data.text}
   })
   tasks.text:setText(text)
   tasks.color:setColor(data.color)
   tasks.colorBg:setColor(data.color * 0.25)
   return 10
end

return 'colorPicker', api, function(v) panels = v end