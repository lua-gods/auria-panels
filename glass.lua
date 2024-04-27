if not host:isHost() then return end
local theme = {}
local panels = require('panels.main')
local themeEnabled = false

local function screenToWorldSpace(distance, pos, fov, fovErr)
   local mat = matrices.mat4()
   local rot = client.getCameraRot()
   local win_size = client.getWindowSize()
   local mpos = (pos / win_size - vec(0.5, 0.5)) * vec(win_size.x/win_size.y,1)
   fov = math.tan(math.rad(fov/2))*2 * fovErr
   if renderer:getCameraMatrix() then mat:multiply(renderer:getCameraMatrix()) end
   mat:translate(mpos.x*-fov*distance,mpos.y*-fov*distance,0)
   mat:rotate(rot.x, -rot.y, rot.z)
   mat:translate(client:getCameraPos())
   return (mat * vectors.vec4(0, 0, distance, 1)).xyz
end

local function getFovErr()
   local point = vec(0, 0)
   local win = client:getWindowSize()
   local pos = vectors.worldToScreenSpace((screenToWorldSpace(1, point, client.getFOV(), 1))).xy
   local point2 = (point / win * 2 - 1)
   return point2:length() / pos:length()
end

local panelsPos = vec(0, 0)
theme.render = function(model, time, chatOffset, pageAnim)
   local pos = client.getScaledWindowSize() * vec(0.5, 1)
   pos.x = pos.x + 95
   pos.y = pos.y + 8 - (1 - (1 - time) ^ 3) * 10
   pos.y = pos.y - chatOffset * 14
   panelsPos = pos
   model:setPos(-pos.xy_)
   model:setScale(1 + pageAnim * 0.2)
end

theme.renderElements = function(elements, updateElement, selected)
   local currentHeight = 0
   local fovErr = getFovErr()
   local raycastFluidMode = #world.getBlockState(client.getCameraPos()):getFluidTags() >= 1 and 'NONE' or 'ANY'
   local startPos = client.getCameraPos()
   for i = #elements, 1, -1 do
      local v = elements[i]
      -- glass
      local pos = (panelsPos + v.pos.xy - vec(-32, currentHeight + 5)) * client.getGuiScale()
      local endPos = screenToWorldSpace(64, pos, client.getFOV(), fovErr)
      local block, hitPos = raycast:block(startPos, endPos, "COLLIDER", raycastFluidMode)

      local glass = block:getMapColor()
      if (hitPos - startPos):length() > 63.5 then
         glass = vec(0.52, 0.67, 1)
      end
      glass = vectors.rgbToHSV(glass)
      glass.y = 1 - (1 - glass.y) ^ 2
      glass.z = math.min(glass.z, 0.4)
      glass = vectors.hsvToRGB(glass) 
      v.renderData.glass = v.renderData.glass and math.lerp(v.renderData.glass, glass, 0.25) or glass

      theme.outline = math.lerp(v.renderData.glass, vec(0.13, 0.13, 0.13), 0.5)
      -- render
      local height = updateElement(i, v)
      currentHeight = currentHeight + height
      v.renderData.pos = vec(-v.pos.x, currentHeight - v.pos.y)
   end
end

function events.tick()
   if themeEnabled then
      panels.reload()
   end
end

local function setTheme(x)
   themeEnabled = x
   panels.setTheme(x and theme or nil)
end

return setTheme