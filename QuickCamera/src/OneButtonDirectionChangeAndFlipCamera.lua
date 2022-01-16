--
-- QuickCamera for FS22
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
-- @date    2022-01-xx
--

function func1(self, actionName, inputValue, callbackState, isAnalog)
--print("OneButtonDirectionChangeAndFlipCamera - func1")
    local spec = self.spec_motorized
    spec.modQC_FlipCameraToDirection = true
    Motorized.actionEventDirectionChange(self, InputAction.DIRECTION_CHANGE, inputValue, callbackState, isAnalog)
end

Motorized.onRegisterActionEvents = Utils.appendedFunction(Motorized.onRegisterActionEvents, function(self, isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient and isActiveForInputIgnoreSelection then
		local spec = self.spec_motorized
        if self:getDirectionChangeMode() == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamDirectionChangeFlipCamera, self, func1, false, true, false, true, nil, nil, true)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
        end
    end
end)

Motorized.onGearDirectionChanged = Utils.appendedFunction(Motorized.onGearDirectionChanged, function(self, direction)
    if self.isClient then
--print("OneButtonDirectionChangeAndFlipCamera - onGearDirectionChanged: " .. tostring(direction))
        local spec = self.spec_motorized
        if spec.modQC_FlipCameraToDirection then
            Enterable.QC_onInputLookForeBack(self, nil, 0, direction, nil, nil)
        end
        spec.modQC_FlipCameraToDirection = false
    end
end)