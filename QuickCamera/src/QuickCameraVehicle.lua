--
-- QuickCamera for FS22
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
-- @date    2021-11-xx
--

----
local STATE_FOREBACK = 1
local STATE_LEFTRIGHT = 3
local STATE_ZOOMINOUT = 5

----

function delayedInjection_VehicleCamera_Update()
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
  end)
end

----

local math_pi_double  = math.pi*2
local function normalizeRotation(rot)
  while (rot < 0)              do rot = rot + math_pi_double; end
  while (rot > math_pi_double) do rot = rot - math_pi_double; end
  return rot
end

----

Enterable.QC_onInputLookForeBack = function(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  --log("QC_onInputLookForeBack ", inputActionName," ", inputValue," ", callbackState," ", isAnalog," ", isMouse)
  local spec = self.spec_enterable
  local actCam = (nil~=spec and spec.activeCamera) or nil
  if nil ~= actCam and true == actCam.isRotatable then
    if 0 == inputValue then
      if nil ~= spec.modQc and STATE_FOREBACK == spec.modQc.State then
        if g_time <= spec.modQc.PressedTime + QuickCamera.quickTapThresholdMS then
          callbackState = 0
        end
        spec.modQc = nil
      end
      if nil ~= callbackState then
        local destRotY = normalizeRotation(actCam.origRotY)
        local rotY     = normalizeRotation(actCam.rotY)
        -- If currently looking 'forward', then wanted target is 'backwards'
        -- or being forced to 'look back'
        if (0 == callbackState and (destRotY - math.pi/2) < rotY and rotY < (destRotY + math.pi/2))
        or (-1 == callbackState)
        then
          destRotY = destRotY - math.pi
        end
        actCam.modQc = {
          camTime = 250,
          camSource = { actCam.rotX, rotY },
          camTarget = { actCam.rotX, MathUtil.normalizeRotationForShortestPath(destRotY, rotY) },
        }
    end
    elseif nil == spec.modQc or STATE_FOREBACK ~= spec.modQc.State then
      spec.modQc = {
        State = STATE_FOREBACK,
        PressedTime = g_time
      }
    elseif STATE_FOREBACK == spec.modQc.State
    and not spec.modQc.ResetDone
    and g_time > spec.modQc.PressedTime + math.min(500, 3 * QuickCamera.quickTapThresholdMS) then
      spec.modQc.ResetDone = true
      -- Reset camera 'pitch' to the original position
      actCam.modQc = {
        camTime = 200,
        camSource = { actCam.rotX,     actCam.rotY },
        camTarget = { actCam.origRotX, actCam.rotY },
      }
    end
  end
end

Enterable.QC_onInputSnapLeftRight = function(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  --log("QC_onInputSnapLeftRight ", inputActionName," ", inputValue," ", callbackState," ", isAnalog," ", isMouse)
  local spec = self.spec_enterable
  local actCam = (nil~=spec and spec.activeCamera) or nil
  if nil ~= actCam and true == actCam.isRotatable then
    if 0 == inputValue then
      if nil ~= spec.modQc and STATE_LEFTRIGHT == spec.modQc.State then
        if (not spec.modQc.Continue) and g_time <= spec.modQc.PressedTime + QuickCamera.quickTapThresholdMS then
          local angleDegSnap = spec.modQc.AngleDegSnap
          local dirY = MathUtil.sign(spec.modQc.InputValue) * MathUtil.degToRad(angleDegSnap)
          local rotY = actCam.rotY - dirY
          rotY = MathUtil.degToRad(angleDegSnap * math.floor((math.deg(rotY) + (angleDegSnap/2))/angleDegSnap)); -- snap
          actCam.modQc = {
            camTime = 100,
            camSource = { actCam.rotX, actCam.rotY },
            camTarget = { actCam.rotX, rotY },
          }
        end
        spec.modQc = nil
      end
    elseif nil == spec.modQc or STATE_LEFTRIGHT ~= spec.modQc.State then
      spec.modQc = {
        State = STATE_LEFTRIGHT,
        PressedTime = g_time,
        InputValue = inputValue,
        AngleDegSnap = callbackState
      }
    elseif STATE_LEFTRIGHT == spec.modQc.State
    and (spec.modQc.Continue or g_time > spec.modQc.PressedTime + QuickCamera.quickTapThresholdMS) then
      spec.modQc.Continue = true
      VehicleCamera.actionEventLookLeftRight(actCam, inputActionName, inputValue, nil, isAnalog, isMouse)
    end
  end
end

Enterable.QC_onInputPeekLeftRight = function(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  --log("QC_onInputPeekLeftRight ", inputActionName," ", inputValue," ", callbackState," ", isAnalog," ", isMouse)
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

Enterable.QC_onInputQuickZoom = function(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  local spec = self.spec_enterable
  local actCam = (nil~=spec and spec.activeCamera) or nil
  if nil ~= actCam and true == actCam.allowTranslation then
    if 0 == inputValue then
      if nil ~= spec.modQc and STATE_ZOOMINOUT == spec.modQc.State then
        if (not spec.modQc.Continue) and g_time <= spec.modQc.PressedTime + QuickCamera.quickTapThresholdMS then
          actCam:zoomSmoothly(spec.modQc.InputValue * QuickCamera.quickZoomFactorUnit)
        end
        spec.modQc = nil
      end
    elseif nil == spec.modQc or STATE_ZOOMINOUT ~= spec.modQc.State then
      spec.modQc = {
        State = STATE_ZOOMINOUT,
        PressedTime = g_time,
        InputValue = callbackState
      }
    elseif STATE_ZOOMINOUT == spec.modQc.State
    and (spec.modQc.Continue or g_time > spec.modQc.PressedTime + QuickCamera.quickTapThresholdMS) then
      spec.modQc.Continue = true
      actCam:zoomSmoothly(spec.modQc.InputValue * 0.01 * g_currentDt)
    end
  end
end

Enterable.onRegisterActionEvents = Utils.overwrittenFunction(Enterable.onRegisterActionEvents, function(self, superFunc, ...)
  --log("Enterable.onRegisterActionEvents ", ...)
  superFunc(self, ...)

  if self.isClient and self:getIsEntered() and self:getIsActiveForInput(true,true) then
    local spec = self.spec_enterable
    local _, actionEventId
    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamVehicleForeBack, self, Enterable.QC_onInputLookForeBack,  true, true, true, true, nil);  g_inputBinding:setActionEventTextVisibility(actionEventId, false)
    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamVehicleSnapLR,   self, Enterable.QC_onInputSnapLeftRight, true, true, true, true,  45);  g_inputBinding:setActionEventTextVisibility(actionEventId, false)
    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamVehicleSnap2LR,  self, Enterable.QC_onInputSnapLeftRight, true, true, true, true,  90);  g_inputBinding:setActionEventTextVisibility(actionEventId, false)
    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamVehiclePeekLR,   self, Enterable.QC_onInputPeekLeftRight, true, true, true, true,  60);  g_inputBinding:setActionEventTextVisibility(actionEventId, false)
    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamVehicleZoomIn,   self, Enterable.QC_onInputQuickZoom,     true, true, true, true,  -1);  g_inputBinding:setActionEventTextVisibility(actionEventId, false)
    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamVehicleZoomOut,  self, Enterable.QC_onInputQuickZoom,     true, true, true, true,   1);  g_inputBinding:setActionEventTextVisibility(actionEventId, false)
  end
end)
