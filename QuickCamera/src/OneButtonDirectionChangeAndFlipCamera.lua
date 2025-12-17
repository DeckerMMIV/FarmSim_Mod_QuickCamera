--
-- QuickCamera for FS25
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
-- @date    2024-11-xx, 2025-02-xx, 2025-09-xx
--

function Motorized.QC_onInputChangeDirectionAndFlipCamera(self, actionName, inputValue, callbackState, isAnalog)
    qcLog("Motorized.QC_onInputChangeDirectionAndFlipCamera: inputValue:",inputValue)
    local spec = self.spec_motorized
    spec.modQC = {
        flipCamera = true,
    }
    Motorized.actionEventDirectionChange(self, InputAction.DIRECTION_CHANGE, inputValue, callbackState, isAnalog)
end

function Motorized.QC_onInputChangeDirectionThenDelayFlipCamera(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_motorized
    if nil == spec.modQC and 0 ~= inputValue then
        spec.modQC = {
            timeout = g_time + math.min(500, QuickCamera.quickTapThresholdMS),
        }
        qcLog("Motorized.QC_onInputChangeDirectionThenDelayFlipCamera: inputValue:",inputValue," spec.modQC.timeout:",spec.modQC.timeout)
        Motorized.actionEventDirectionChange(self, InputAction.DIRECTION_CHANGE, inputValue, callbackState, isAnalog)
    elseif nil ~= spec.modQC
    and g_time > spec.modQC.timeout
    and (   self.isServer
        or  (not self.isServer and spec.modQC.haveReadGearDataFromStream)
        )
    then
        qcLog("Motorized.QC_onInputChangeDirectionThenDelayFlipCamera: spec.modQC.direction:",spec.modQC.direction)
        spec.modQC.timeout = math.huge
        if nil ~= spec.modQC.direction then
            Enterable.QC_onInputLookForeBack(self, nil, 0, spec.modQC.direction, nil, nil)
        end
    elseif 0 == inputValue then
        qcLog("Motorized.QC_onInputChangeDirectionThenDelayFlipCamera: inputValue:",inputValue)
        spec.modQC = nil
    end
end

Motorized.onRegisterActionEvents = Utils.appendedFunction(Motorized.onRegisterActionEvents, function(self, isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient and isActiveForInputIgnoreSelection then
        local spec = self.spec_motorized
        if self:getDirectionChangeMode() == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL then
            qcLog("(post)Motorized.onRegisterActionEvents: self=",self)
            local _, actionEventId

            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamDirectionChangeFlipCamera,      self, Motorized.QC_onInputChangeDirectionAndFlipCamera,      false, true, false, true, nil, nil, true)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)

            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.QuickCamDirectionChangeDelayFlipCamera, self, Motorized.QC_onInputChangeDirectionThenDelayFlipCamera, true, true,  true, true, nil, nil, true)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
        end
    end
end)

Motorized.onGearDirectionChanged = Utils.appendedFunction(Motorized.onGearDirectionChanged, function(self, direction)
    if self.isServer then
        local spec = self.spec_motorized
        if nil ~= spec.modQC then
            if nil ~= self.getReverserDirection then
                spec.modQC.direction = direction * self:getReverserDirection()
            else
                spec.modQC.direction = direction
            end

            if spec.modQC.flipCamera then
                qcLog("Motorized.onGearDirectionChanged: spec.modQC.flipCamera:",spec.modQC.flipCamera)
                Enterable.QC_onInputLookForeBack(self, nil, 0, spec.modQC.direction, nil, nil)
                spec.modQC = nil
            end
        end
    end
end)

VehicleMotor.readGearDataFromStream = Utils.appendedFunction(VehicleMotor.readGearDataFromStream, function(self, streamId)
    local vehicle = self.vehicle
    if nil ~= vehicle and vehicle.isClient then
        local spec = vehicle.spec_motorized
        if nil ~= spec and nil ~= spec.modQC then
            spec.modQC.haveReadGearDataFromStream = true
            if nil ~= vehicle.getReverserDirection then
                spec.modQC.direction = self.currentDirection * vehicle:getReverserDirection()
            else
                spec.modQC.direction = self.currentDirection
            end

            if spec.modQC.flipCamera then
                qcLog("VehicleMotor.readGearDataFromStream: spec.modQC.flipCamera:",spec.modQC.flipCamera)
                Enterable.QC_onInputLookForeBack(vehicle, nil, 0, spec.modQC.direction, nil, nil)
                spec.modQC = nil
            end
        end
    end
end)
