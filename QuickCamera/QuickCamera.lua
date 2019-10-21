--
-- QuickCamera for FS19
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
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

if g_client then

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

local quickTapThresholdMS = 150 -- Milliseconds. Below = quick-tap. Above = long-hold
local quickZoomFactorUnit = 13

----

VehicleCamera.onLoadFinished = Utils.appendedFunction(VehicleCamera.onLoadFinished, function(self, savegame)
  if self.allowHeadTracking then
    self.modQcOrig_TransDirX = self.transDirX
    self.modQcOrig_TransDirY = self.transDirY
    self.modQcOrig_TransDirZ = self.transDirZ
  end
end)

VehicleCamera.update = Utils.prependedFunction(VehicleCamera.update, function(self, dt)
  local modQc = self.modQc
  if nil ~= modQc then
    if nil ~= modQc.accTime then
      modQc.accTime = modQc.accTime + dt
    else
      modQc.accTime = 0
    end
    local newCamRot = Utils.getMovedLimitedValues(modQc.camSource, modQc.camSource, modQc.camTarget, 2, modQc.camTime, modQc.accTime, true);
    self.rotX = newCamRot[1];
    self.rotY = newCamRot[2];
    if nil == modQc.peekFrom and modQc.accTime > modQc.camTime then
      self.modQc = nil
    end
  end

  local moveInside = self.modQCMoveInside
  if nil ~= moveInside then
    local newXYZ
    if moveInside.active then
      moveInside.restoreTime = 0
      moveInside.restoreSource = { moveInside.x, moveInside.y, moveInside.z }
      newXYZ = moveInside.restoreSource
    else
      moveInside.restoreTime = moveInside.restoreTime + dt
      if moveInside.restoreTime > 300 then
        newXYZ = {0,0,0}
        self.modQCMoveInside = nil
      else
        newXYZ = Utils.getMovedLimitedValues(moveInside.restoreSource, moveInside.restoreSource, {0,0,0}, 3, 300, moveInside.restoreTime, true);
        moveInside.x = newXYZ[1]
        moveInside.y = newXYZ[2]
        moveInside.z = newXYZ[3]
      end
    end
    self.transDirX = self.modQcOrig_TransDirX + newXYZ[1]
    self.transDirY = self.modQcOrig_TransDirY + newXYZ[2]
    self.transDirZ = self.modQcOrig_TransDirZ + newXYZ[3]
  end
end)

VehicleCamera.actionEventLookUpDown = Utils.overwrittenFunction(VehicleCamera.actionEventLookUpDown, function(self, superFunc, actionName, inputValue, callbackState, isAnalog, isMouse)
  if self.modQCMoveInside then
    if inputValue ~= 0 then
      if isMouse then
        inputValue = inputValue * 0.0005 * 16.666
      else
        inputValue = inputValue * 0.0005 * g_currentDt
      end
      -- Lean forward/back
      self.modQCMoveInside.z = self.modQCMoveInside.z - inputValue
    end
  else
    superFunc(self, actionName, inputValue, callbackState, isAnalog, isMouse)
  end
end)

VehicleCamera.actionEventLookLeftRight = Utils.overwrittenFunction(VehicleCamera.actionEventLookLeftRight, function(self, superFunc, actionName, inputValue, callbackState, isAnalog, isMouse)
  if self.modQCMoveInside then
    if inputValue ~= 0 then
      if isMouse then
        inputValue = inputValue * 0.0005 * 16.666
      else
        inputValue = inputValue * 0.0005 * g_currentDt
      end
      -- Lean left/right
      self.modQCMoveInside.x = self.modQCMoveInside.x - inputValue
    end
  else
    superFunc(self, actionName, inputValue, callbackState, isAnalog, isMouse)
  end
end)

VehicleCamera.zoomSmoothly = Utils.overwrittenFunction(VehicleCamera.zoomSmoothly, function(self, superFunc, offset)
  if self.modQCMoveInside then
    -- Lean(?) up/down
    self.modQCMoveInside.y = self.modQCMoveInside.y + offset * 0.05
  else
    superFunc(self, offset)
  end
end)

VehicleCamera.QC_onInputMoveInside = function(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  --log("VehicleCamera.QC_onInputMoveInside(",inputActionName,",",inputValue,",",callbackState,",",isAnalog,",",isMouse,")")

  if self.allowHeadTracking then
    if 1 == inputValue then
      self.modQCMoveInside = Utils.getNoNil(
        self.modQCMoveInside,
        { x=0, y=0, z=0 }
      )
      self.modQCMoveInside.active = true
    elseif nil ~= self.modQCMoveInside then
      self.modQCMoveInside.active = false
    end
  end
end

VehicleCamera.onActivate = Utils.appendedFunction(VehicleCamera.onActivate, function(self)
  if self.allowHeadTracking then
    local actionEventId
    _, actionEventId = g_inputBinding:registerActionEvent(InputAction.QuickCamInsideCamera, self, VehicleCamera.QC_onInputMoveInside, true, true, false, true,  nil); g_inputBinding:setActionEventTextVisibility(actionEventId, false);
  end
end)

----

local math_pi_double  = math.pi*2
local function normalizeRotation(rot)
  while (rot < 0)              do rot = rot + math_pi_double; end
  while (rot > math_pi_double) do rot = rot - math_pi_double; end
  return rot
end

----

Enterable.registerEventListeners = Utils.appendedFunction(Enterable.registerEventListeners, function(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Enterable)
end)

Enterable.onLoadFinished = Utils.appendedFunction(Enterable.onLoadFinished, function(self, savegame)
  local spec = self.spec_enterable
  for _,cam in pairs(spec.cameras) do
    VehicleCamera.onLoadFinished(cam, savegame)
  end
end)

--

Enterable.QC_onInputLookForeBack = function(self, inputActionName, inputValue, callbackState, arg4, isMouse)
  local spec = self.spec_enterable
  local actCam = (nil~=spec and spec.activeCamera) or nil
  if nil ~= actCam and true == actCam.isRotatable then
    if 0 == inputValue then
      if (nil ~= spec.modQcPressedTime) and spec.modQcPressedTime < g_time then
        local destRotY = normalizeRotation(actCam.origRotY)
        local rotY     = normalizeRotation(actCam.rotY)
        if (destRotY - math.pi/2) < rotY and rotY < (destRotY + math.pi/2) then
          -- Currently looking 'forward', so wanted target is 'backwards'
          destRotY = destRotY - math.pi
        end
        actCam.modQc = {
          camTime = 250,
          camSource = { actCam.rotX, rotY },
          camTarget = { actCam.rotX, MathUtil.normalizeRotationForShortestPath(destRotY, rotY) },
        }
      end
      spec.modQcPressedTime = nil
    elseif nil == spec.modQcPressedTime then
      spec.modQcPressedTime = g_time
    elseif spec.modQcPressedTime < g_time - quickTapThresholdMS then
      spec.modQcPressedTime = math.huge
      -- Reset camera 'pitch' to the original position
      actCam.modQc = {
        camTime = 200,
        camSource = { actCam.rotX,     actCam.rotY },
        camTarget = { actCam.origRotX, actCam.rotY },
      }
    end
  end
end

Enterable.QC_onInputSnapLeftRight = function(self, inputActionName, inputValue, callbackState, arg4, isMouse)
  local spec = self.spec_enterable
  local actCam = (nil~=spec and spec.activeCamera) or nil
  if nil ~= actCam and true == actCam.isRotatable then
    if 0 == inputValue then
      if (nil ~= spec.modQcPressedTime) and g_time - spec.modQcPressedTime <= quickTapThresholdMS then
        local actCam = spec.activeCamera
        local angleDegSnap = callbackState
        local dirY = MathUtil.sign(spec.modQcInputValue) * MathUtil.degToRad(angleDegSnap)
        local rotY = actCam.rotY - dirY
        rotY = MathUtil.degToRad(angleDegSnap * math.floor((math.deg(rotY) + (angleDegSnap/2))/angleDegSnap)); -- snap
        actCam.modQc = {
          camTime = 100,
          camSource = { actCam.rotX, actCam.rotY },
          camTarget = { actCam.rotX, rotY },
        }
      end
      spec.modQcPressedTime = nil
      spec.modQcInputValue = nil
    elseif nil == spec.modQcPressedTime then
      spec.modQcPressedTime = g_time
      spec.modQcInputValue = inputValue
    end
  end
end

Enterable.QC_onInputPeekLeftRight = function(self, inputActionName, inputValue, callbackState, arg4, isMouse)
  local spec = self.spec_enterable
  local actCam = (nil~=spec and spec.activeCamera) or nil
  if nil ~= actCam and true == actCam.isRotatable then
    if nil == actCam.modQc then
      local dirY = MathUtil.sign(inputValue) * MathUtil.degToRad(callbackState)
      local rotY = actCam.rotY - dirY
      actCam.modQc = {
        camTime = 100,
        peekFrom  = { actCam.rotX, actCam.rotY },
        peekValue = inputValue,
        camSource = { actCam.rotX, actCam.rotY },
        camTarget = { actCam.rotX, rotY },
      }
    elseif nil ~= actCam.modQc.peekFrom then
      if 0 == inputValue then
        local origPeekFrom = actCam.modQc.peekFrom
        actCam.modQc = {
          camTime = 100,
          camSource = { actCam.rotX, actCam.rotY },
          camTarget = origPeekFrom,
        }
      elseif actCam.modQc.peekValue ~= inputValue then
        local origPeekFrom = actCam.modQc.peekFrom
        local dirY = MathUtil.sign(inputValue) * MathUtil.degToRad(callbackState)
        local rotY = origPeekFrom[2] - dirY
        actCam.modQc = {
          camTime = 100,
          peekFrom  = origPeekFrom,
          peekValue = inputValue,
          camSource = { actCam.rotX, actCam.rotY },
          camTarget = { actCam.rotX, rotY },
        }
      end
    end
  end
end

Enterable.QC_onInputQuickZoom = function(self, inputActionName, inputValue, callbackState, arg4, isMouse)
  local spec = self.spec_enterable
  local actCam = (nil~=spec and spec.activeCamera) or nil
  if nil ~= actCam and true == actCam.allowTranslation then
    if nil == spec.modQcPressedTime then
      if 0 ~= inputValue then
        spec.modQcPressedTime = g_time
        spec.modQcInputValue = callbackState
      end
    else
      if 0 == inputValue then
        if callbackState == spec.modQcInputValue then
          if (g_time - spec.modQcPressedTime) <= quickTapThresholdMS then
            actCam:zoomSmoothly(quickZoomFactorUnit * spec.modQcInputValue)
          end
          spec.modQcPressedTime = nil
          spec.modQcInputValue = nil
        end
      elseif callbackState ~= spec.modQcInputValue then
        spec.modQcPressedTime = g_time
        spec.modQcInputValue = callbackState
      end
    end
  end
end

Enterable.onRegisterActionEvents = Utils.overwrittenFunction(Enterable.onRegisterActionEvents, function(self, superFunc, ...)
  if self.isClient and self:getIsEntered() and self:getIsActiveForInput(true,true) then
    log("Enterable.onRegisterActionEvents ", ...)
    local spec = self.spec_enterable
    self:clearActionEventsTable(spec.actionEvents) -- Part of "hack". See comment further below

    local _, actionEventId
                       -- addActionEvent(<actionEventsTable>, <inputAction>, self, <callbackFunction>, <triggerUp>, <triggerDown>, <triggerAlways>, <startActive>, <callbackState>)
    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamVehicleForeBack, self, Enterable.QC_onInputLookForeBack,  true, false, true, true, nil); g_inputBinding:setActionEventTextVisibility(actionEventId, false)
    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamVehicleSnapLR,   self, Enterable.QC_onInputSnapLeftRight, true, true, false, true,  45); g_inputBinding:setActionEventTextVisibility(actionEventId, false)
    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamVehicleSnap2LR,  self, Enterable.QC_onInputSnapLeftRight, true, true, false, true,  90); g_inputBinding:setActionEventTextVisibility(actionEventId, false)
    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamVehiclePeekLR,   self, Enterable.QC_onInputPeekLeftRight, true, true, false, true,  60); g_inputBinding:setActionEventTextVisibility(actionEventId, false)
    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamVehicleZoomIn,   self, Enterable.QC_onInputQuickZoom,     true, true, false, true,  -1); g_inputBinding:setActionEventTextVisibility(actionEventId, false)
    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamVehicleZoomOut,  self, Enterable.QC_onInputQuickZoom,     true, true, false, true,   1); g_inputBinding:setActionEventTextVisibility(actionEventId, false)

    -- UGLY HACK! - Somehow the InputBinding eventOrder is 'important' when it comes to which InputAction that
    -- occurs first in the `g_inputBinding.eventOrder` table, and whether or not its event has `triggerAlways=true`.
    -- I discovered that when two InputActions _mapped_to_the_same_key_ are active, then the (InputAction-)event with
    -- `triggerAlways=false` must occur _before_ the (InputAction-)event with `triggerAlways=true`, for both events
    -- to be triggered.
    local totalActionEvents = spec.actionEvents
    --
    spec.actionEvents = {}
    superFunc(self, ...)
    --
    for k,v in pairs(spec.actionEvents) do
      totalActionEvents[k] = v
    end
    --
    spec.actionEvents = totalActionEvents
  else
    log("Enterable.onRegisterActionEvents_ORIG ", ...)
    superFunc(self, ...)
  end
end)

----

print(("Script loaded: QuickCamera.lua - from %s (v%s)"):format(g_currentModName, g_modManager:getModByName(g_currentModName).version));

end -- g_client