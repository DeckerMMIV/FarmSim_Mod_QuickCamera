--
-- QuickCamera for FS25
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
-- @date    2024-11-xx
--

function QuickCamOneButtonChangeDirectionAndFlipCamera(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_motorized
    spec.modQC_FlipCameraToDirection = true
    Motorized.actionEventDirectionChange(self, InputAction.DIRECTION_CHANGE, inputValue, callbackState, isAnalog)
end

Motorized.onRegisterActionEvents = Utils.appendedFunction(Motorized.onRegisterActionEvents, function(self, isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient and isActiveForInputIgnoreSelection then
        local spec = self.spec_motorized
        if self:getDirectionChangeMode() == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamDirectionChangeFlipCamera, self, QuickCamOneButtonChangeDirectionAndFlipCamera, false, true, false, true, nil, nil, true)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
        end
    end
end)

Motorized.onGearDirectionChanged = Utils.appendedFunction(Motorized.onGearDirectionChanged, function(self, direction)
    if self.isClient then
        local spec = self.spec_motorized
        if spec.modQC_FlipCameraToDirection then
            local reverserDirection = 1

            local activeCamera = self:getActiveCamera()
            if nil ~= activeCamera and activeCamera.isInside then
                if nil ~= self.getReverserDirection then
                    reverserDirection = self:getReverserDirection()
                end
            end

            Enterable.QC_onInputLookForeBack(self, nil, 0, direction * reverserDirection, nil, nil)
        end
        spec.modQC_FlipCameraToDirection = false
    end
end)
