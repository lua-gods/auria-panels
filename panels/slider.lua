--- @class panelsPage
local myPageApi = {}
--- @class panelsApi
local panels = {}
--- @class panelsElementSlider : panelsElementDefault
local methods = {}
local api = {page = myPageApi, methods = methods}

local whitePixel = textures.whitePixel or textures:newTexture('whitePixel', 1, 1):setPixel(0, 0, 1, 1, 1)

local sliderLen = 34

--- creates new panels text element
--- @param self panelsPage
--- @return panelsElementSlider
function myPageApi:newSlider()
   local obj = panels.newElement('slider', self)
   obj.text = ''
   obj.value = 0
   obj.min = 0
   obj.max = 16
   obj.color = vec(0.98, 0.65, 0.78)
   obj.step = 1
   obj.preciseStep = nil
   obj.warp = false
   obj.scrollOffset = 0
   return obj
end

function api.scroll(obj, dir, shift)
   dir = dir + obj.scrollOffset
   obj.scrollOffset = dir % 1
   dir = math.floor(dir)
   obj.value = obj.value + dir * (shift and obj.preciseStep or obj.step)
   if obj.warp then
      obj.value = (obj.value - obj.min) % (obj.max - obj.min) + obj.min
   else
      obj.value = math.clamp(obj.value, obj.min, obj.max)
   end
   if obj.scroll then
      obj.scroll(obj.value, obj)
   end
end

-- methods
--- set text of slider, returns itself for chaining
--- @overload fun(self: panelsElementSlider, text: string): panelsElementSlider
--- @overload fun(self: panelsElementSlider, text: table): panelsElementSlider
function methods:setText(text)
   self.text = text
   panels.reload()
   return self
end

--- sets color of slider, returns itself for chaining
--- @overload fun(self: panelsElementSlider, r: number, g: number, b: number): panelsElementSlider
--- @overload fun(self: panelsElementSlider, color: Vector3): panelsElementSlider
function methods:setColor(r, g, b)
   if type(r) == 'Vector3' then
      self.color = r 
   else
      self.color = vec(r, g, b) 
   end
   panels.reload()
   return self
end

--- sets minimum for slider, returns itself for chaining
--- @overload fun(self: panelsElementSlider, min: number): panelsElementSlider
function methods:setMin(min)
   self.min = min
   self.value = math.max(self.value, min)
   panels.reload()
   return self
end

--- sets maximum for slider, returns itself for chaining
--- @overload fun(self: panelsElementSlider, max: number): panelsElementSlider
function methods:setMax(max)
   self.max = max
   self.value = math.min(self.value, max)
   panels.reload()
   return self
end

--- sets current value for slider, returns itself for chaining
--- @overload fun(self: panelsElementSlider, value: number): panelsElementSlider
function methods:setValue(value)
   self.value = math.clamp(value, self.min, self.max)
   panels.reload()
   return self
end

--- sets step size for slider, optional argument for precise step that will be used instead of step when shift is held, returns itself for chaining
--- @overload fun(self: panelsElementSlider, step: number): panelsElementSlider
--- @overload fun(self: panelsElementSlider, step: number, precise: number): panelsElementSlider
function methods:setStep(step, precise)
   self.step = step 
   self.preciseStep = precise
   return self
end

--- makes slider value loop around, returns itself for chaining
--- @overload fun(self: panelsElementSlider, warp: boolean): panelsElementSlider
function methods:allowWarping(warp)
   self.warp = warp
   return self
end


--- sets function that will be called when scrolling
--- @param func function
--- @return panelsElementSlider
function methods:onScroll(func)
   self.scroll = func
   return self
end

-- rendering
function api.createModel(model)
   model:newText('text'):setOutline(true):setPos(-sliderLen - 4, 0, 0)
   model:newSprite('slider'):setTexture(whitePixel, 1, 7)
   model:newSprite('sliderBg'):setTexture(whitePixel, 1, 7):setColor(panels.theme.rgb.sliderBg)
   model:newSprite('sliderOutline'):setTexture(whitePixel, sliderLen + 2, 9):setColor(panels.theme.rgb.outline):setPos(1, 1, 1)
   model:newText('sliderText')
   model:newText('sliderText2')
end

function api.renderElement(data, isSelected, isPressed, model, tasks)
   -- text
   local color = isPressed and panels.theme.pressed or isSelected and panels.theme.selected or panels.theme.default
   local text = toJson({
      text = '',
      color = color,
      extra = {data.text}
   })
   tasks.text:setText(text)

   -- slider
   local slider = (data.value - data.min) / (data.max - data.min)
   tasks.slider:setColor(data.color):setScale(slider * sliderLen, 1, 1)
   tasks.sliderBg:setScale(sliderLen * (1 - slider), 1, 1):setPos(- slider * sliderLen, 0, 0)
   -- text
   tasks.sliderText:setText(toJson({text = data.value, color = panels.theme.outline}))
   tasks.sliderText2:setText(data.value)

   local mat = matrices.translate4(-1, 0, 2 / sliderLen - slider)
   mat.v31 = 1 / -sliderLen
   tasks.sliderText:setMatrix(mat)

   mat = matrices.translate4(-1, 0, slider)
   mat.v31 = 1 / sliderLen
   tasks.sliderText2:setMatrix(mat)
   
   return 10
end

return 'slider', api, function(v) panels = v end