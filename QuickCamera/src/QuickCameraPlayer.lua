--
-- QuickFeet for FS22
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
-- @date    2021-11-xx
--

----

Player.QC_onInputLookForeBack = function(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  --log("Player.QC_onInputLookForeBack: ",inputActionName," ",inputValue," ",callbackState," ",isAnalog," ",isMouse)
  self.inputInformation.yawCamera = (math.pi) / g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
end

Player.QC_onInputLookLeftRight = function(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  --log("Player.QC_onInputLookLeftRight: ",inputActionName," ",inputValue," ",callbackState," ",isAnalog," ",isMouse)
  if 0 == inputValue then
    if self.modQc then
      if g_time <= self.modQc.PressedTime + QuickCamera.quickTapThresholdMS then
        self.inputInformation.yawCamera = ((math.pi / 4) * self.modQc.InputValue) / g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
      end
      self.modQc = nil
    end
  elseif nil == self.modQc then
    self.modQc = {
      PressedTime = g_time,
      InputValue = inputValue
    }
  elseif g_time > self.modQc.PressedTime + QuickCamera.quickTapThresholdMS then
    Player.onInputLookLeftRight(self, inputActionName, inputValue, callbackState, isAnalog, isMouse)
  end
end

Player.load = Utils.appendedFunction(Player.load, function(self, xmlFilename, playerStyle, creatorConnection, isOwner)
  if nil ~= InputAction.QuickCamOnFootForeBack then
    self.inputInformation.registrationList[InputAction.QuickCamOnFootForeBack] = { eventId="", callback=self.QC_onInputLookForeBack, triggerUp=false, triggerDown=true, triggerAlways=false, activeType=Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT, callbackState=nil, text="", textVisibility=false }
  end
  if nil ~= InputAction.QuickCamOnFootLeftRight then
    self.inputInformation.registrationList[InputAction.QuickCamOnFootLeftRight] = { eventId="", callback=self.QC_onInputLookLeftRight, triggerUp=false, triggerDown=false, triggerAlways=true, activeType=Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT, callbackState=nil, text="", textVisibility=false }
  end
end)

----

Player.load = Utils.appendedFunction(Player.load, function(self, xmlFilename, playerStyle, creatorConnection, isOwner)
  if  nil ~= self.playerStateMachine
  and nil ~= self.playerStateMachine.fsmTable
  and nil ~= self.playerStateMachine.fsmTable["run"]
  then
    -- Do not allow switching to handtool when in running state
    self.playerStateMachine.fsmTable["run"]["cycleHandtool"] = false
  end
end)

PlayerStateCycleHandtool.isAvailable = Utils.overwrittenFunction(PlayerStateCycleHandtool.isAvailable, function(self, superFunc)
  local result = superFunc(self)
  if result then
    -- Disallow switching to "cycleHandtool" state, if AXIS_RUN is pressed
    result = (0 == self.player.inputInformation.runAxis)
  end
  return result
end)

Player.mouseEvent = Utils.appendedFunction(Player.mouseEvent, function(self, posX, posY, isDown, isUp, button)
  if isDown then
    if button == Input.MOUSE_BUTTON_WHEEL_UP and g_currentMission:getHasPlayerPermission("manageRights") then
      self.inputInformation.modQcRunSpeedModifier = 1.25
    elseif button == Input.MOUSE_BUTTON_WHEEL_DOWN and g_currentMission:getHasPlayerPermission("manageRights") then
      self.inputInformation.modQcRunSpeedModifier = 0.9
    end
  end
end);

local basegameRunningSpeed = 9 -- The constant '9' seems to be the default value.

Player.updatePlayerStates = Utils.appendedFunction(Player.updatePlayerStates, function(self)
  if nil ~= self.inputInformation.modQcRunSpeedModifier then
    self.motionInformation.maxRunningSpeed = math.max(1, math.min(QuickCamera.playerRunSpeedFactorMax * basegameRunningSpeed, self.motionInformation.maxRunningSpeed * self.inputInformation.modQcRunSpeedModifier))
    self.inputInformation.modQcRunSpeedModifier = nil
    self.inputInformation.modQcRunSpeedModified = true
  elseif self.inputInformation.runAxis <= 0 and true == self.inputInformation.modQcRunSpeedModified then
    self.motionInformation.maxRunningSpeed = basegameRunningSpeed
    self.inputInformation.modQcRunSpeedModified = nil
  end
end)

local infoText_SpeedRun = g_i18n:getText("QUICKCAMERA_ONFOOT_SPEEDRUN")

Player.update = Utils.appendedFunction(Player.update, function(self, dt)
  if self.isClient and self.isControlled then
    if self.inputInformation.runAxis > 0 and not self:hasHandtoolEquipped() then
      if g_currentMission:getHasPlayerPermission("manageRights") then
        g_currentMission:addExtraPrintText((infoText_SpeedRun):format(self.motionInformation.maxRunningSpeed / basegameRunningSpeed))
      end
    end
  end
end)
