--
-- QuickCamera for FS25
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
-- @date    2024-11-xx
--

----
local STATE_FOREBACK = 1
local STATE_LEFTRIGHT = 3
local STATE_ZOOMINOUT = 5

----

local math_pi_half    = math.pi * 0.5
local math_pi_double  = math.pi * 2

local function normalizeRotation(rot)
  while (rot < 0)              do rot = rot + math_pi_double end
  while (rot > math_pi_double) do rot = rot - math_pi_double end
  return rot
end

----

Enterable.QC_onInputLookForeBack = function(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  local spec = self.spec_enterable
  local actCam = (nil~=spec and spec.activeCamera) or nil

  qcLog("QC_onInputLookForeBack", " self=",self, " hasActCam=",nil ~= actCam, " isRotatable=",((not actCam and "n/a") or actCam.isRotatable), " ; ", inputActionName," ", inputValue," ", callbackState," ", isAnalog," ", isMouse)

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
        if (0 == callbackState and (destRotY - math_pi_half) < rotY and rotY < (destRotY + math_pi_half)) then
          callbackState = -1
        end

        -- Forced to 'look back'
        if -1 == callbackState then
          if actCam.isInside then
            -- For the in-cabin camera, try to make it act like "turning your head", so when it is instructed to look forward again,
            -- the rotation would occur in opposite direction.
            local notQuitePi = math.pi - math.pi/500
            if rotY <= destRotY then
              destRotY = destRotY - notQuitePi
            else
              destRotY = destRotY + notQuitePi
            end
          else
            -- For outside cameras, just rotate the same direction continuously
            destRotY = destRotY - math.pi
          end
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
  local spec = self.spec_enterable
  local actCam = (nil~=spec and spec.activeCamera) or nil

  qcLog("QC_onInputSnapLeftRight", " self=",self, " hasActCam=",nil ~= actCam, " isRotatable=",((not actCam and "n/a") or actCam.isRotatable), " ; ", inputActionName," ", inputValue," ", callbackState," ", isAnalog," ", isMouse)

  if nil ~= actCam and true == actCam.isRotatable then
    if 0 == inputValue then
      if nil ~= spec.modQc and STATE_LEFTRIGHT == spec.modQc.State then
        if (not spec.modQc.Continue) and g_time <= spec.modQc.PressedTime + QuickCamera.quickTapThresholdMS then
          local angleDegSnap = spec.modQc.AngleDegSnap
          local dirY = math.sign(spec.modQc.InputValue) * math.rad(angleDegSnap)
          local rotY = actCam.rotY - dirY
          rotY = math.rad(angleDegSnap * math.floor((math.deg(rotY) + (angleDegSnap/2))/angleDegSnap)) -- snap
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
  local spec = self.spec_enterable
  local actCam = (nil~=spec and spec.activeCamera) or nil

  qcLog("QC_onInputPeekLeftRight", " self=",self, " hasActCam=",nil ~= actCam, " isRotatable=",((not actCam and "n/a") or actCam.isRotatable), " ; ", inputActionName," ", inputValue," ", callbackState," ", isAnalog," ", isMouse)

  if nil ~= actCam and true == actCam.isRotatable then
    if nil == actCam.modQc or nil == actCam.modQc.peekFrom then
      local dirY = math.sign(inputValue) * math.rad(callbackState)
      local rotY = actCam.rotY - dirY
      actCam.modQc = Utils.getNoNil(actCam.modQc, {})
      actCam.modQc.camTime    = 100
      actCam.modQc.peekFrom   = { actCam.rotX, actCam.rotY }
      actCam.modQc.peekValue  = inputValue
      actCam.modQc.camSource  = { actCam.rotX, actCam.rotY }
      actCam.modQc.camTarget  = { actCam.rotX, rotY }
    elseif nil ~= actCam.modQc.peekFrom then
      if 0 == inputValue then
        local origPeekFrom = actCam.modQc.peekFrom
        actCam.modQc.camTime    = 100
        actCam.modQc.accTime    = 0
        actCam.modQc.peekFrom   = nil
        actCam.modQc.peekValue  = nil
        actCam.modQc.camSource  = { actCam.rotX, actCam.rotY }
        actCam.modQc.camTarget  = origPeekFrom
      elseif actCam.modQc.peekValue ~= inputValue then
        local origPeekFrom = actCam.modQc.peekFrom
        local dirY = math.sign(inputValue) * math.rad(callbackState)
        local rotY = origPeekFrom[2] - dirY
        actCam.modQc.camTime    = 100
        actCam.modQc.accTime    = 0
        actCam.modQc.peekFrom   = origPeekFrom
        actCam.modQc.peekValue  = inputValue
        actCam.modQc.camSource  = { actCam.rotX, actCam.rotY }
        actCam.modQc.camTarget  = { actCam.rotX, rotY }
      end
    end
  end
end

Enterable.QC_onInputQuickZoom = function(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  local spec = self.spec_enterable
  local actCam = (nil~=spec and spec.activeCamera) or nil

  qcLog("QC_onInputQuickZoom", " self=",self, " hasActCam=",nil ~= actCam, " allowTranslation=",((not actCam and "n/a") or actCam.allowTranslation), " ; ", inputActionName," ", inputValue," ", callbackState," ", isAnalog," ", isMouse)

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

----

function QC_VehicleCamera_LookLeftRightWithSnap(self, superFunc, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  --qcLog("QC_VehicleCamera_LookLeftRightWithSnap", " self=",self, " isRotatable=",self.isRotatable, " ; ", inputActionName," ", inputValue," ", callbackState," ", isAnalog," ", isMouse)

  if true == self.isRotatable and not (isAnalog or isMouse) then
    if 0 == inputValue then
      if nil ~= self.modQc and STATE_LEFTRIGHT == self.modQc.State then
        qcLog("QC_VehicleCamera_LookLeftRightWithSnap", " self=",self, " isRotatable=",self.isRotatable, " ; ", inputActionName," ", inputValue," ", callbackState," ", isAnalog," ", isMouse)
        if (not self.modQc.Continue) and g_time <= self.modQc.PressedTime + QuickCamera.quickTapThresholdMS then
          local angleDegSnap = self.modQc.AngleDegSnap or 45
          local dirY = math.sign(self.modQc.InputValue) * math.rad(angleDegSnap)
          local rotY = self.rotY - dirY
          rotY = math.rad(angleDegSnap * math.floor((math.deg(rotY) + (angleDegSnap/2))/angleDegSnap)) -- snap
          self.modQc.camTime = 100
          self.modQc.accTime = 0
          self.modQc.camSource = { self.rotX, self.rotY }
          self.modQc.camTarget = { self.rotX, rotY }
        end
        self.modQc.State        = nil
        self.modQc.Continue     = nil
        self.modQc.PressedTime  = nil
        self.modQc.InputValue   = nil
        self.modQc.AngleDegSnap = nil
      end
    elseif nil == self.modQc or STATE_LEFTRIGHT ~= self.modQc.State then
      qcLog("QC_VehicleCamera_LookLeftRightWithSnap", " self=",self, " isRotatable=",self.isRotatable, " ; ", inputActionName," ", inputValue," ", callbackState," ", isAnalog," ", isMouse)
      self.modQc = Utils.getNoNil(self.modQc, {})
      self.modQc.State        = STATE_LEFTRIGHT
      self.modQc.PressedTime  = g_time
      self.modQc.InputValue   = inputValue
      self.modQc.AngleDegSnap = callbackState
    elseif STATE_LEFTRIGHT == self.modQc.State
    and (self.modQc.Continue or g_time > self.modQc.PressedTime + QuickCamera.quickTapThresholdMS) then
      qcLog("QC_VehicleCamera_LookLeftRightWithSnap", " self=",self, " isRotatable=",self.isRotatable, " ; ", inputActionName," ", inputValue," ", callbackState," ", isAnalog," ", isMouse)
      self.modQc.Continue = true
      superFunc(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
    end
  else
    superFunc(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  end
end

function delayedInjection_VehicleCamera_Update()
  qcLog("delayedInjection_VehicleCamera_Update")

  VehicleCamera.update = Utils.prependedFunction(VehicleCamera.update, function(self, dt)
    local modQc = self.modQc
    if nil ~= modQc and nil ~= modQc.camTime then
      if nil ~= modQc.accTime then
        if dt < 16 then
          qcLog("(pre)VehicleCamera.update - deltaTime is less than 16ms? dt="..tostring(dt))
        end
        modQc.accTime = modQc.accTime + dt
      else
        modQc.accTime = 0
      end
      local newCamRot = Utils.getMovedLimitedValues(modQc.camSource, modQc.camSource, modQc.camTarget, 2, modQc.camTime, modQc.accTime, true)
      self.rotX = newCamRot[1]
      self.rotY = newCamRot[2]
      if nil == modQc.peekFrom and modQc.accTime > modQc.camTime then
        modQc.camTime   = nil
        modQc.accTime   = nil
        modQc.camSource = nil
        modQc.camTarget = nil
      end
    end
  end)

  VehicleCamera.actionEventLookLeftRight = Utils.overwrittenFunction(VehicleCamera.actionEventLookLeftRight, QC_VehicleCamera_LookLeftRightWithSnap)

  VehicleCamera.onActivate = Utils.appendedFunction(VehicleCamera.onActivate, function(self)
    qcLog("(post)VehicleCamera.onActivate", " self=",self, " isClient=",self.isClient," self.isRotatable=",self.isRotatable)

    local function addActionEvent(inputAction, callback, callbackState)
      local state, actionEventId = g_inputBinding:registerActionEvent(inputAction, self, callback, false, false, true, true, callbackState)
      g_inputBinding:setActionEventTextVisibility(actionEventId, false)
      if (not state) then
        qcLog("Failed addActionEvent for: ",inputAction)
      end
    end

    if self.isRotatable then
      g_inputBinding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
      addActionEvent(InputAction.QuickCamVehicleSnapLR,       VehicleCamera.actionEventLookLeftRight,  45)
      addActionEvent(InputAction.QuickCamVehicleSnap2LR,      VehicleCamera.actionEventLookLeftRight,  90)
      g_inputBinding:endActionEventsModification()
    end
  end)

  Enterable.onRegisterActionEvents = Utils.overwrittenFunction(Enterable.onRegisterActionEvents, function(self, superFunc, isActiveForInput, isActiveForInputIgnoreSelection, ...)
    superFunc(self, isActiveForInput, isActiveForInputIgnoreSelection, ...)

    qcLog("(post)Enterable.onRegisterActionEvents", " self=",self, " isClient=",self.isClient, " getIsEntered=",self:getIsEntered(), " getIsActiveForInput=",self:getIsActiveForInput(true,true), " ; ", isActiveForInput, isActiveForInputIgnoreSelection, ...)
    if self.isClient and self:getIsEntered() and self:getIsActiveForInput(true,true) then
      local spec = self.spec_enterable

      local function addActionEvent(inputAction, callback, callbackState)
        local state, actionEventId = self:addActionEvent(spec.actionEvents, inputAction, self, callback, false, false, true, true, callbackState, nil, nil, true)
        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
        if (not state) then
          qcLog("Failed addActionEvent for: ",inputAction)
        end
      end

      addActionEvent(InputAction.QuickCamVehicleForeBack,     Enterable.QC_onInputLookForeBack,  nil)
      addActionEvent(InputAction.QuickCamVehiclePeekLR,       Enterable.QC_onInputPeekLeftRight,  60)
      addActionEvent(InputAction.QuickCamVehiclePeekBehindLR, Enterable.QC_onInputPeekLeftRight, 120)
      addActionEvent(InputAction.QuickCamVehicleZoomIn,       Enterable.QC_onInputQuickZoom,      -1)
      addActionEvent(InputAction.QuickCamVehicleZoomOut,      Enterable.QC_onInputQuickZoom,       1)
    end
  end)

  EnterablePassenger.onRegisterActionEvents = Utils.overwrittenFunction(EnterablePassenger.onRegisterActionEvents, function(self, superFunc, isActiveForInput, isActiveForInputIgnoreSelection, ...)
    superFunc(self, isActiveForInput, isActiveForInputIgnoreSelection, ...)

    local spec = self.spec_enterablePassenger
    qcLog("(post)EnterablePassenger.onRegisterActionEvents", " self=",self, " spec=",spec, " getIsEntered=",self:getIsEntered(), " getIsActiveForInput=",self:getIsActiveForInput(true,true), " ; ", isActiveForInput, isActiveForInputIgnoreSelection, ...)
    if nil ~= spec and spec.available and spec.passengerEntered then
      local function addActionEvent(inputAction, callback, callbackState)
        local state, actionEventId = self:addActionEvent(spec.actionEvents, inputAction, self, callback, false, false, true, true, callbackState, nil, nil, true)
        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
        if (not state) then
          qcLog("Failed addActionEvent for: ",inputAction)
        end
      end

      addActionEvent(InputAction.QuickCamVehicleForeBack,     Enterable.QC_onInputLookForeBack,  nil)
      addActionEvent(InputAction.QuickCamVehiclePeekLR,       Enterable.QC_onInputPeekLeftRight,  60)
      addActionEvent(InputAction.QuickCamVehiclePeekBehindLR, Enterable.QC_onInputPeekLeftRight, 120)
      addActionEvent(InputAction.QuickCamVehicleZoomIn,       Enterable.QC_onInputQuickZoom,      -1)
      addActionEvent(InputAction.QuickCamVehicleZoomOut,      Enterable.QC_onInputQuickZoom,       1)
    end
  end)
end
