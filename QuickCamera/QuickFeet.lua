--
-- QuickFeet for FS19
--
-- @author  Decker_MMIV (DCK)
-- @contact fs-uk.com, forum.farming-simulator.com
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
  if inputValue == 0 then
    if self.inputInformation.modQcPressedTime ~= nil then
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
  if InputAction.QuickCamOnFootForeBack ~= nil then
    --log("exists: InputAction.QuickCamOnFootForeBack")
    self.inputInformation.registrationList[InputAction.QuickCamOnFootForeBack] = { eventId="", callback=self.QC_onInputLookForeBack, triggerUp=false, triggerDown=true, triggerAlways=false, activeType=Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT, callbackState=nil, text="", textVisibility=false }
  end
  if InputAction.QuickCamOnFootLeftRight ~= nil then
    --log("exists: InputAction.QuickCamOnFootLeftRight")
    self.inputInformation.registrationList[InputAction.QuickCamOnFootLeftRight] = { eventId="", callback=self.QC_onInputLookLeftRight, triggerUp=true, triggerDown=true, triggerAlways=false, activeType=Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT, callbackState=nil, text="", textVisibility=false }
  end
end)

----

Player.load = Utils.appendedFunction(Player.load, function(self, xmlFilename, playerStyle, creatorConnection, isOwner)
  -- Do not allow switching to handtool when in running state
  self.playerStateMachine.fsmTable["run"]["cycleHandtool"] = false
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

Player.updatePlayerStates = Utils.appendedFunction(Player.updatePlayerStates, function(self)
  if self.inputInformation.modQcRunSpeedModifier ~= nil then
    self.motionInformation.maxRunningSpeed = math.max(9, math.min(128, self.motionInformation.maxRunningSpeed * self.inputInformation.modQcRunSpeedModifier))
    self.inputInformation.modQcRunSpeedModifier = nil
  elseif self.inputInformation.runAxis <= 0 then
    self.motionInformation.maxRunningSpeed = 9
  end
end)

print(("Script loaded: QuickFeet.lua - from %s (v%s)"):format(g_currentModName, g_modManager:getModByName(g_currentModName).version));
