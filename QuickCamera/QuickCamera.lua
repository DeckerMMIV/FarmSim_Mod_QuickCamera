--
-- QuickCamera for FS19
--
-- @author  Decker_MMIV (DCK)
-- @contact fs-uk.com, forum.farming-simulator.com
-- @date    2019-01-xx
--

--[[
Suggestions
-----------

Kyuss33
    I was wondering if anyone has a mod that allows you to adjust the height of your head or view in the cabin.
    I feel like I'm a 7 foot person in harvester's cabin view.I have seen quick camera mod that allows for saving previous cameras
    but I don't think it adjust the up down or height in cabin
    http://forum.giants-software.com/viewtopic.php?f=831&t=77401
]]

-- For debugging
local function log(...)
  if true then
      local txt = ""
      for idx = 1,select("#", ...) do
          txt = txt .. tostring(select(idx, ...))
      end
      print(string.format("%7ums ", g_time) .. txt);
  end
end;

----

VehicleCamera.update = Utils.prependedFunction(VehicleCamera.update, function(self, dt)
  if self.modQc ~= nil then
    local modQc = self.modQc
    if modQc.accTime ~= nil then
      modQc.accTime = modQc.accTime + dt
    else
      modQc.accTime = 0
    end
    local newCamRot = Utils.getMovedLimitedValues(modQc.camSource, modQc.camSource, modQc.camTarget, 2, modQc.camTime, modQc.accTime, true);
    self.rotX = newCamRot[1];
    self.rotY = newCamRot[2];
    if modQc.peekFrom == nil and modQc.accTime > modQc.camTime then
      self.modQc = nil
    end
  end
end)

local math_pi_double  = math.pi*2
local function normalizeRotation(rot)
  while (rot < 0)              do rot = rot + math_pi_double; end
  while (rot > math_pi_double) do rot = rot - math_pi_double; end
  return rot
end

VehicleCamera.QC_onInputLookForeBack = function(self, inputActionName, inputValue, callbackState, arg4, isMouse)
  local destRotY = normalizeRotation(self.origRotY)
  local rotY     = normalizeRotation(self.rotY)
  if (destRotY - math.pi/2) < rotY and rotY < (destRotY + math.pi/2) then
    -- Currently looking 'forward', so wanted target is 'backwards'
    destRotY = destRotY - math.pi
  end

  self.modQc = {
    camTime = 250,
    camSource = { self.rotX, rotY },
    camTarget = { self.origRotX, MathUtil.normalizeRotationForShortestPath(destRotY, rotY) },
  }
end

VehicleCamera.QC_onInputSnapLeftRight = function(self, inputActionName, inputValue, callbackState, arg4, isMouse)
  --log("VehicleCamera.QC_onInputSnapLeftRight: ",inputActionName," ",inputValue," ",callbackState," ",arg4," ",isMouse)
  if inputValue == 0 then
    if self.modQcPressedTime ~= nil then
      if (g_time - self.modQcPressedTime) <= 150 then -- TODO: Make 150ms configurable!
        local angleDegSnap = callbackState
        local dirY = MathUtil.sign(self.modQcInputValue) * MathUtil.degToRad(angleDegSnap)
        local rotY = self.rotY - dirY
        rotY = MathUtil.degToRad(angleDegSnap * math.floor((math.deg(rotY) + (angleDegSnap/2))/angleDegSnap)); -- snap
        self.modQc = {
          camTime = 100,
          camSource = { self.rotX, self.rotY },
          camTarget = { self.rotX, rotY },
        }
      end
    end
    self.modQcPressedTime = nil
    self.modQcInputValue = nil
  else
    self.modQcPressedTime = g_time
    self.modQcInputValue = inputValue
  end
end

VehicleCamera.QC_onInputPeekLeftRight = function(self, inputActionName, inputValue, callbackState, arg4, isMouse)
  --log("VehicleCamera.QC_onInputPeekLeftRight: ",inputActionName," ",inputValue," ",callbackState," ",arg4," ",isMouse)
  if self.modQc == nil then
    local dirY = MathUtil.sign(inputValue) * MathUtil.degToRad(callbackState)
    local rotY = self.rotY - dirY
    self.modQc = {
      camTime = 100,
      peekFrom  = { self.rotX, self.rotY },
      peekValue = inputValue,
      camSource = { self.rotX, self.rotY },
      camTarget = { self.rotX, rotY },
    }
  elseif self.modQc.peekFrom ~= nil then
    if inputValue == 0 then
      local origPeekFrom = self.modQc.peekFrom
      self.modQc = {
        camTime = 100,
        camSource = { self.rotX, self.rotY },
        camTarget = origPeekFrom,
      }
    elseif self.modQc.peekValue ~= inputValue then
      local origPeekFrom = self.modQc.peekFrom
      local dirY = MathUtil.sign(inputValue) * MathUtil.degToRad(callbackState)
      local rotY = origPeekFrom[2] - dirY
      self.modQc = {
        camTime = 100,
        peekFrom  = origPeekFrom,
        peekValue = inputValue,
        camSource = { self.rotX, self.rotY },
        camTarget = { self.rotX, rotY },
      }
      end
  end
end

VehicleCamera.QC_onInputQuickZoom = function(self, inputActionName, inputValue, callbackState, arg4, isMouse)
  if self.modQcPressedTime == nil then
    if inputValue ~= 0 then
      --log("VehicleCamera.QC_onInputQuickZoom(1): ",inputActionName," ",inputValue," ",callbackState," ",arg4," ",isMouse)
      self.modQcPressedTime = g_time
      self.modQcInputValue = callbackState
    end
  else
    if inputValue == 0 then
      if callbackState == self.modQcInputValue then
        --log("VehicleCamera.QC_onInputQuickZoom(2): ",inputActionName," ",inputValue," ",callbackState," ",arg4," ",isMouse)
        if (g_time - self.modQcPressedTime) <= 150 then -- TODO: Make 150ms configurable!
          self:zoomSmoothly(13 * self.modQcInputValue)
        end
        self.modQcPressedTime = nil
        self.modQcInputValue = nil
      end
    elseif callbackState ~= self.modQcInputValue then
      --log("VehicleCamera.QC_onInputQuickZoom(3): ",inputActionName," ",inputValue," ",callbackState," ",arg4," ",isMouse)
      self.modQcPressedTime = g_time
      self.modQcInputValue = callbackState
    end
  end
end

VehicleCamera.onActivate = Utils.appendedFunction(VehicleCamera.onActivate, function(self)
  if nil == g_client then
    return
  end

  local actionEvents = {
    { 1, InputAction.QuickCamVehicleForeBack, VehicleCamera.QC_onInputLookForeBack,  false, true, false, true, nil },
    { 1, InputAction.QuickCamVehicleSnapLR,   VehicleCamera.QC_onInputSnapLeftRight, true,  true, false, true,  45 },
    { 1, InputAction.QuickCamVehicleSnap2LR,  VehicleCamera.QC_onInputSnapLeftRight, true,  true, false, true,  90 },
    { 1, InputAction.QuickCamVehiclePeekLR,   VehicleCamera.QC_onInputPeekLeftRight, true,  true, false, true,  60 },
    { 2, InputAction.QuickCamVehicleZoomIn,   VehicleCamera.QC_onInputQuickZoom,     true,  true, false, true, -1  },
    { 2, InputAction.QuickCamVehicleZoomOut,  VehicleCamera.QC_onInputQuickZoom,     true,  true, false, true,  1  },
  }

  for idx,ae in ipairs(actionEvents) do
    if ae[2] ~= nil then
      if (ae[1] == 1 and self.isRotatable) or (ae[1] == 2 and self.allowTranslation) then
        local success, actionEventId, collision = g_inputBinding:registerActionEvent(ae[2], self, ae[3], ae[4], ae[5], ae[6], ae[7], ae[8])
        --log(success," ",actionEventId," ",collision)
        if success then
          g_inputBinding:setActionEventTextVisibility(actionEventId, false)
        else
          log("[ERROR, QuickCamera] registerActionEvent failure (#",idx,") ",collision)
        end
      end
    end
  end

  -- WARNING! DANGER!
  -- EXTREMELY UGLY HACK! - Somehow the InputBinding eventOrder is 'important' when it comes which InputAction that
  -- occurs first in the `g_inputBinding.eventOrder` table, and whether or not its event has `triggerAlways=true`.
  -- I discovered that when two InputActions _mapped_to_the_same_key_, then the (InputAction-)event with `triggerAlways=false`
  -- must occur _before_ the (InputAction-)event with `triggerAlways=true`, for both events to be triggered.

  local actionNamesOrder = {
    -- 1.                                 2.
    {InputAction.QuickCamVehicleZoomIn, InputAction.CAMERA_ZOOM_IN},
    {InputAction.QuickCamVehicleZoomOut,InputAction.CAMERA_ZOOM_OUT},
  }
  for _,actNamesOrder in pairs(actionNamesOrder) do
    local eventOrderIdxs = {nil,nil}
    for idx,act in pairs(g_inputBinding.eventOrder) do
      for j,actName in pairs(actNamesOrder) do
        if act.actionName == actName then
          eventOrderIdxs[j] = idx
        end
      end
    end
    if eventOrderIdxs[1] ~= nil and eventOrderIdxs[2] ~= nil then
      if eventOrderIdxs[1] > eventOrderIdxs[2] then
        local tmp = g_inputBinding.eventOrder[eventOrderIdxs[2]]
        g_inputBinding.eventOrder[eventOrderIdxs[2]] = g_inputBinding.eventOrder[eventOrderIdxs[1]]
        g_inputBinding.eventOrder[eventOrderIdxs[1]] = tmp
      end
    end
  end

end)

print(("Script loaded: QuickCamera.lua - from %s (v%s)"):format(g_currentModName, g_modManager:getModByName(g_currentModName).version));
