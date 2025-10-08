--
-- QuickFeet for FS25
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
-- @date    2025-07-xx, 2025-09-xx
--

----

PlayerInputComponent.QC_onInputLookForeBack = function(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  qcLog("PlayerInputComponent.QC_onInputLookForeBack: ",inputActionName," ",inputValue," ",callbackState," ",isAnalog," ",isMouse)
  self.cameraRotationY = self.cameraRotationY + math.pi
end

PlayerInputComponent.onInputLookLeftRight = Utils.overwrittenFunction(PlayerInputComponent.onInputLookLeftRight, function(self, superFunc, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  --qcLog("(pre)PlayerInputComponent.onInputLookLeftRight: ",inputActionName," ",inputValue," ",callbackState," ",isAnalog," ",isMouse)
  if isAnalog or isMouse then
    superFunc(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  elseif 0 == inputValue then
    if self.modQc then
      qcLog("(pre)PlayerInputComponent.onInputLookLeftRight: ",inputActionName," ",inputValue," ",callbackState," ",isAnalog," ",isMouse)
      if g_time <= self.modQc.PressedTime + QuickCamera.quickTapThresholdMS
      and (not self.locked)
      then
        self.cameraRotationY = self.cameraRotationY + ((math.pi / 4) * self.modQc.InputValue)
      end
      self.modQc = nil
    end
  elseif nil == self.modQc then
    qcLog("(pre)PlayerInputComponent.onInputLookLeftRight: ",inputActionName," ",inputValue," ",callbackState," ",isAnalog," ",isMouse)
    self.modQc = {
      PressedTime = g_time,
      InputValue = inputValue
    }
  elseif g_time > self.modQc.PressedTime + QuickCamera.quickTapThresholdMS then
    qcLog("(pre)PlayerInputComponent.onInputLookLeftRight: ",inputActionName," ",inputValue," ",callbackState," ",isAnalog," ",isMouse)
    superFunc(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  end
end)

local hasRegisteredAdditionalActionEvents = false

PlayerInputComponent.listenForBindingChanges = Utils.appendedFunction(PlayerInputComponent.listenForBindingChanges, function(self, ...)
  qcLog("(post)PlayerInputComponent.listenForBindingChanges: self=",self)

  if not hasRegisteredAdditionalActionEvents then
    -- Attempt to force a call to `PlayerInputComponent.registerActionEvents`
    g_messageCenter:publish(MessageType.INPUT_BINDINGS_CHANGED, {})
  end
end)

PlayerInputComponent.registerActionEvents = Utils.appendedFunction(PlayerInputComponent.registerActionEvents, function(self)
  qcLog("(post)PlayerInputComponent.registerActionEvents: self=",self)

  g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)
  local _, eventId = g_inputBinding:registerActionEvent(InputAction.QuickCamOnFootForeBack, self, PlayerInputComponent.QC_onInputLookForeBack, true, false, false, true, nil, true)
  g_inputBinding:setActionEventTextVisibility(eventId, false)
  g_inputBinding:endActionEventsModification()
  hasRegisteredAdditionalActionEvents = true
end)

----

local orig_ACCELERATION = PlayerMover.ACCELERATION
local orig_DECELERATION = PlayerMover.DECELERATION

PlayerInputComponent.onInputZoomInOut = Utils.overwrittenFunction(PlayerInputComponent.onInputZoomInOut, function(self, superFunc, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  --qcLog("PlayerInputComponent.onInputZoomInOut: ",inputActionName," ",inputValue," ",callbackState," ",isAnalog," ",isMouse," self.lastRunAxis:",self.lastRunAxis," self.player:",self.player)
  if 0 ~= self.lastRunAxis then
    if inputValue > 0 then
      self.modQC_runMultiplier = math.clamp(Utils.getNoNil(self.modQC_runMultiplier, 1) * 1.25, 0.5, QuickCamera.playerRunSpeedFactorMax)
    elseif inputValue < 0 then
      self.modQC_runMultiplier = math.clamp(Utils.getNoNil(self.modQC_runMultiplier, 1) * 0.90, 0.5, QuickCamera.playerRunSpeedFactorMax)
    end
    PlayerMover.ACCELERATION = orig_ACCELERATION * math.max(self.modQC_runMultiplier, 1)
    PlayerMover.DECELERATION = orig_DECELERATION * math.max(self.modQC_runMultiplier, 1)
    qcLog("PlayerInputComponent.onInputZoomInOut: ",inputActionName," ",inputValue," ",callbackState," ",isAnalog," ",isMouse," self.modQC_runMultiplier:",self.modQC_runMultiplier)
  else
    superFunc(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  end
end)

PlayerInputComponent.onInputRun = Utils.appendedFunction(PlayerInputComponent.onInputRun, function(self)
  if 0 == self.runAxis then
    self.modQC_runMultiplier = nil
  end
end)

function QC_calculateDesiredHorizontalVelocity(self, superFunc, directionX, directionZ)
  directionX, directionZ = superFunc(self, directionX, directionZ)
  if nil ~= self.player.inputComponent.modQC_runMultiplier then
    directionX = directionX * self.player.inputComponent.modQC_runMultiplier
    directionZ = directionZ * self.player.inputComponent.modQC_runMultiplier
  end
  return directionX, directionZ
end

PlayerStateWalk  .calculateDesiredHorizontalVelocity = Utils.overwrittenFunction(PlayerStateWalk  .calculateDesiredHorizontalVelocity, QC_calculateDesiredHorizontalVelocity)
PlayerStateSwim  .calculateDesiredHorizontalVelocity = Utils.overwrittenFunction(PlayerStateSwim  .calculateDesiredHorizontalVelocity, QC_calculateDesiredHorizontalVelocity)
PlayerStateJump  .calculateDesiredHorizontalVelocity = Utils.overwrittenFunction(PlayerStateJump  .calculateDesiredHorizontalVelocity, QC_calculateDesiredHorizontalVelocity)
PlayerStateFall  .calculateDesiredHorizontalVelocity = Utils.overwrittenFunction(PlayerStateFall  .calculateDesiredHorizontalVelocity, QC_calculateDesiredHorizontalVelocity)
PlayerStateCrouch.calculateDesiredHorizontalVelocity = Utils.overwrittenFunction(PlayerStateCrouch.calculateDesiredHorizontalVelocity, QC_calculateDesiredHorizontalVelocity)
