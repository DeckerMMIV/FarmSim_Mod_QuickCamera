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

----

local math_pi_double  = math.pi*2
local function normalizeRotation(rot)
  while (rot < 0)              do rot = rot + math_pi_double; end
  while (rot > math_pi_double) do rot = rot - math_pi_double; end
  return rot
end

----

Enterable.QC_onInputLookForeBack = function(self, inputActionName, inputValue, callbackState, arg4, isMouse)
  local actCam = self.spec_enterable.activeCamera

  local destRotY = normalizeRotation(actCam.origRotY)
  local rotY     = normalizeRotation(actCam.rotY)
  if (destRotY - math.pi/2) < rotY and rotY < (destRotY + math.pi/2) then
    -- Currently looking 'forward', so wanted target is 'backwards'
    destRotY = destRotY - math.pi
  end

  actCam.modQc = {
    camTime = 250,
    camSource = { actCam.rotX, rotY },
    camTarget = { actCam.origRotX, MathUtil.normalizeRotationForShortestPath(destRotY, rotY) },
  }
end

Enterable.QC_onInputSnapLeftRight = function(self, inputActionName, inputValue, callbackState, arg4, isMouse)
  --log("VehicleCamera.QC_onInputSnapLeftRight: ",inputActionName," ",inputValue," ",callbackState," ",arg4," ",isMouse)
  local spec = self.spec_enterable
  if inputValue == 0 then
    if spec.modQcPressedTime ~= nil then
      if (g_time - spec.modQcPressedTime) <= 150 then -- TODO: Make 150ms configurable!
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
    end
    spec.modQcPressedTime = nil
    spec.modQcInputValue = nil
  else
    spec.modQcPressedTime = g_time
    spec.modQcInputValue = inputValue
  end
end

Enterable.QC_onInputPeekLeftRight = function(self, inputActionName, inputValue, callbackState, arg4, isMouse)
  --log("VehicleCamera.QC_onInputPeekLeftRight: ",inputActionName," ",inputValue," ",callbackState," ",arg4," ",isMouse)
  local actCam = self.spec_enterable.activeCamera
  if actCam.modQc == nil then
    local dirY = MathUtil.sign(inputValue) * MathUtil.degToRad(callbackState)
    local rotY = actCam.rotY - dirY
    actCam.modQc = {
      camTime = 100,
      peekFrom  = { actCam.rotX, actCam.rotY },
      peekValue = inputValue,
      camSource = { actCam.rotX, actCam.rotY },
      camTarget = { actCam.rotX, rotY },
    }
  elseif actCam.modQc.peekFrom ~= nil then
    if inputValue == 0 then
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

Enterable.QC_onInputQuickZoom = function(self, inputActionName, inputValue, callbackState, arg4, isMouse)
  local spec = self.spec_enterable
  if spec.modQcPressedTime == nil then
    if inputValue ~= 0 then
      --log("VehicleCamera.QC_onInputQuickZoom(1): ",inputActionName," ",inputValue," ",callbackState," ",arg4," ",isMouse)
      spec.modQcPressedTime = g_time
      spec.modQcInputValue = callbackState
    end
  else
    if inputValue == 0 then
      if callbackState == spec.modQcInputValue then
        --log("VehicleCamera.QC_onInputQuickZoom(2): ",inputActionName," ",inputValue," ",callbackState," ",arg4," ",isMouse)
        if (g_time - spec.modQcPressedTime) <= 150 then -- TODO: Make 150ms configurable!
          spec.activeCamera:zoomSmoothly(13 * spec.modQcInputValue)
        end
        spec.modQcPressedTime = nil
        spec.modQcInputValue = nil
      end
    elseif callbackState ~= spec.modQcInputValue then
      --log("VehicleCamera.QC_onInputQuickZoom(3): ",inputActionName," ",inputValue," ",callbackState," ",arg4," ",isMouse)
      spec.modQcPressedTime = g_time
      spec.modQcInputValue = callbackState
    end
  end
end

Enterable.onRegisterActionEvents = Utils.overwrittenFunction(Enterable.onRegisterActionEvents, function(self, superFunc, ...)
  if self:getIsEntered() and self:getIsActiveForInput(true,true) then
    local spec = self.spec_enterable
    self:clearActionEventsTable(spec.actionEvents) -- Part of "hack". See comment further below

    local actCam = spec.activeCamera
    if nil ~= actCam then
      local actionEvents = {
        { 1, InputAction.QuickCamVehicleForeBack, Enterable.QC_onInputLookForeBack,  false, true, false, true, nil },
        { 1, InputAction.QuickCamVehicleSnapLR,   Enterable.QC_onInputSnapLeftRight, true,  true, false, true,  45 },
        { 1, InputAction.QuickCamVehicleSnap2LR,  Enterable.QC_onInputSnapLeftRight, true,  true, false, true,  90 },
        { 1, InputAction.QuickCamVehiclePeekLR,   Enterable.QC_onInputPeekLeftRight, true,  true, false, true,  60 },
        { 2, InputAction.QuickCamVehicleZoomIn,   Enterable.QC_onInputQuickZoom,     true,  true, false, true, -1  },
        { 2, InputAction.QuickCamVehicleZoomOut,  Enterable.QC_onInputQuickZoom,     true,  true, false, true,  1  },
      }

      local actionEventId
      for idx,ae in ipairs(actionEvents) do
        if ae[2] ~= nil then
          if (ae[1] == 1 and actCam.isRotatable) or (ae[1] == 2 and actCam.allowTranslation) then
            _, actionEventId = self:addActionEvent(spec.actionEvents, ae[2], self, ae[3], ae[4], ae[5], ae[6], ae[7], ae[8])
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
          end
        end
      end
    end

    -- UGLY HACK! - Somehow the InputBinding eventOrder is 'important' when it comes to which InputAction that
    -- occurs first in the `g_inputBinding.eventOrder` table, and whether or not its event has `triggerAlways=true`.
    -- I discovered that when two InputActions _mapped_to_the_same_key_ are active, then the (InputAction-)event with
    -- `triggerAlways=false` must occur _before_ the (InputAction-)event with `triggerAlways=true`, for both events
    -- to be triggered.
    local totalActionEvents = spec.actionEvents
    spec.actionEvents = {}
    superFunc(self, ...)
    for k,v in pairs(spec.actionEvents) do
      totalActionEvents[k] = v
    end
    spec.actionEvents = totalActionEvents
  else
    superFunc(self, ...)
  end
end)

print(("Script loaded: QuickCamera.lua - from %s (v%s)"):format(g_currentModName, g_modManager:getModByName(g_currentModName).version));
