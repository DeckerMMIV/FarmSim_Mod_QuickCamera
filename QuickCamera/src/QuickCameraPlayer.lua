--
-- QuickFeet for FS25
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
-- @date    2024-11-xx
--

----

--[[
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
  --log("self: ",self)
  --debugTable(self)
  log("self.inputComponent: ",self.inputComponent)
  debugTable(self.inputComponent)
  --log("self.inputInformation: ",self.inputInformation)
  --debugTable(self.inputInformation)
  --log("self.inputInformation.registrationList: ",self.inputInformation.registrationList)
  if nil ~= InputAction.QuickCamOnFootForeBack then
    --self.inputInformation.registrationList[InputAction.QuickCamOnFootForeBack] = { eventId="", callback=self.QC_onInputLookForeBack, triggerUp=false, triggerDown=true, triggerAlways=false, activeType=Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT, callbackState=nil, text="", textVisibility=false }
  end
  if nil ~= InputAction.QuickCamOnFootLeftRight then
    --self.inputInformation.registrationList[InputAction.QuickCamOnFootLeftRight] = { eventId="", callback=self.QC_onInputLookLeftRight, triggerUp=false, triggerDown=false, triggerAlways=true, activeType=Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT, callbackState=nil, text="", textVisibility=false }
  end
end)
--]]

----

--[[
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
    if button == Input.MOUSE_BUTTON_WHEEL_UP then
      self.inputInformation.modQcRunSpeedModifier = 1.25
    elseif button == Input.MOUSE_BUTTON_WHEEL_DOWN then
      self.inputInformation.modQcRunSpeedModifier = 0.9
    end
  end
end);

local basegameRunningSpeed =  9 -- The constant '9' seems to be the default value.

Player.updatePlayerStates = Utils.appendedFunction(Player.updatePlayerStates, function(self)
  if nil ~= self.inputInformation.modQcRunSpeedModifier then
    self.motionInformation.maxRunningSpeed      = math.max(1, math.min(QuickCamera.playerRunSpeedFactorMax * basegameRunningSpeed, self.motionInformation.maxRunningSpeed * self.inputInformation.modQcRunSpeedModifier))
    self.motionInformation.maxCheatRunningSpeed = self.motionInformation.maxRunningSpeed
    self.inputInformation.modQcRunSpeedModifier = nil
    self.inputInformation.modQcRunSpeedModified = true
    -- Due to the LumberJack mod is interfering with QuickCamera's implementation of setting player speed,
    -- so a workaround is needed.
    if  nil ~= FS22_LumberJack
    and nil ~= FS22_LumberJack.LumberJack
    and nil ~= FS22_LumberJack.LumberJack.originalRunningSpeed
    then
      FS22_LumberJack.LumberJack.originalRunningSpeed = self.motionInformation.maxRunningSpeed
      FS22_LumberJack.LumberJack.maxRunningSpeed      = self.motionInformation.maxRunningSpeed
    end
  elseif self.inputInformation.runAxis <= 0 and true == self.inputInformation.modQcRunSpeedModified then
    self.motionInformation.maxRunningSpeed      = basegameRunningSpeed
    self.motionInformation.maxCheatRunningSpeed = basegameRunningSpeed
    self.inputInformation.modQcRunSpeedModified = nil
    -- Due to the LumberJack mod is interfering with QuickCamera's implementation of setting player speed,
    -- so a workaround is needed.
    if  nil ~= FS22_LumberJack
    and nil ~= FS22_LumberJack.LumberJack
    and nil ~= FS22_LumberJack.LumberJack.originalRunningSpeed
    then
      FS22_LumberJack.LumberJack.originalRunningSpeed = self.motionInformation.maxRunningSpeed
      FS22_LumberJack.LumberJack.maxRunningSpeed      = self.motionInformation.maxRunningSpeed
    end
  end
end)

local infoText_SpeedRun = g_i18n:getText("QUICKCAM_ONFOOT_SPEEDRUN")

Player.update = Utils.appendedFunction(Player.update, function(self, dt)
  if self.isClient and self.isControlled then
    if self.inputInformation.runAxis > 0 then
      if not self:hasHandtoolEquipped()
      or (nil ~= FS22_LumberJack and nil ~= FS22_LumberJack.LumberJack)
      then
        g_currentMission:addExtraPrintText((infoText_SpeedRun):format(self.motionInformation.maxRunningSpeed / basegameRunningSpeed))
      end
    end
  end
end)
--]]