--
-- QuickFeet for FS19
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
-- @date    2019-01-xx
--

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

Player.QC_onInputLookForeBack = function(self, arg1, inputValue, arg3, arg4, isMouse)
  --log("Player.QC_onInputLookForeBack: ",arg1," ",inputValue," ",arg3," ",arg4," ",isMouse)
  self.inputInformation.yawCamera = (math.pi) / g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
end

Player.QC_onInputLookLeftRight = function(self, inputActionName, inputValue, callbackState, arg4, isMouse)
  --log("Player.QC_onInputLookLeftRight: ",inputActionName," ",inputValue," ",callbackState," ",arg4," ",isMouse)
  if 0 == inputValue then
    if nil ~= self.inputInformation.modQcPressedTime then
      if (g_time - self.inputInformation.modQcPressedTime) <= 150 then -- TODO: Make 150ms configurable!
        self.inputInformation.yawCamera = ((math.pi / 4) * self.inputInformation.modQcInputValue) / g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
      end
    end
    self.inputInformation.modQcPressedTime = nil
  else
    self.inputInformation.modQcPressedTime = g_time
    self.inputInformation.modQcInputValue = inputValue
  end
end

Player.load = Utils.appendedFunction(Player.load, function(self, xmlFilename, playerStyle, creatorConnection, isOwner)
  if nil ~= InputAction.QuickCamOnFootForeBack then
    --log("exists: InputAction.QuickCamOnFootForeBack")
    self.inputInformation.registrationList[InputAction.QuickCamOnFootForeBack] = { eventId="", callback=self.QC_onInputLookForeBack, triggerUp=false, triggerDown=true, triggerAlways=false, activeType=Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT, callbackState=nil, text="", textVisibility=false }
  end
  if nil ~= InputAction.QuickCamOnFootLeftRight then
    --log("exists: InputAction.QuickCamOnFootLeftRight")
    self.inputInformation.registrationList[InputAction.QuickCamOnFootLeftRight] = { eventId="", callback=self.QC_onInputLookLeftRight, triggerUp=true, triggerDown=true, triggerAlways=false, activeType=Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT, callbackState=nil, text="", textVisibility=false }
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

Player.mouseEvent = Utils.appendedFunction(Player.mouseEvent, function(self, posX, posY, isDown, isUp, button)
  if isDown then
    if button == Input.MOUSE_BUTTON_WHEEL_UP and g_currentMission:getHasPlayerPermission("manageRights") then
      self.inputInformation.modQcRunSpeedModifier = 1.25
    elseif button == Input.MOUSE_BUTTON_WHEEL_DOWN and g_currentMission:getHasPlayerPermission("manageRights") then
      self.inputInformation.modQcRunSpeedModifier = 0.9
    end
  end
end);

Player.updatePlayerStates = Utils.appendedFunction(Player.updatePlayerStates, function(self)
  if nil ~= self.inputInformation.modQcRunSpeedModifier then
    self.motionInformation.maxRunningSpeed = math.max(1, math.min(128, self.motionInformation.maxRunningSpeed * self.inputInformation.modQcRunSpeedModifier))
    self.inputInformation.modQcRunSpeedModifier = nil
    self.inputInformation.modQcRunSpeedModified = true
  elseif self.inputInformation.runAxis <= 0 and true == self.inputInformation.modQcRunSpeedModified then
    self.motionInformation.maxRunningSpeed = 9 -- The constant '9' seems to be the default value.
    self.inputInformation.modQcRunSpeedModified = nil
  end
end)

----

print(("Script loaded: QuickFeet.lua - from %s (v%s)"):format(g_currentModName, g_modManager:getModByName(g_currentModName).version));
