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
   return panels.newElement('textInput', self)
end

function api.press(obj)
   if obj.press then
      obj:press(obj)
   end
end

-- methods
--- sets function that will be called when text is pressed, returns itself for chaining
--- @param func fun(obj: panelsElementTextInput)
--- @return self
function methods:onPress(func)
   self.press = func
   return self
end

-- rendering
function api.createModel(model)
   -- model:getTask('text'):setOutline(false):setPos(-1, 0, 0)
   model:newSprite('line'):setTexture(whitePixel, 64, 1):setPos(0, -8, -1)
   model:newSprite('lineOutline'):setTexture(whitePixel, 66, 3):setPos(1, -7, 1)
end

function api.renderElement(data, isSelected, isPressed, model, tasks)
   tasks.lineOutline:setColor(panels.theme.rgb.outline)
   tasks.line:setColor(isPressed and panels.theme.rgb.selected or panels.theme.rgb.default)
   return 12
end

return 'textInput', api, function(v) panels = v end