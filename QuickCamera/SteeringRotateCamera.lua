--
-- QuickCamera sub-component: Panning of in-cabin camera when turning steering wheel.
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-September
--


VehicleCamera.modQC_PanCamera_enabled = true
VehicleCamera.modQC_PanCamera_factor  = 0.6

--

function adjustForDeadZone(value)
    if math.abs(value) < 0.02 then
        return 0
    end
    return value
end

Drivable.updateVehiclePhysics = Utils.prependedFunction(Drivable.updateVehiclePhysics, function(self)
    self.modQC_previous_rotatedTime = adjustForDeadZone(self.rotatedTime)
end);

Steerable.updateTick = Utils.prependedFunction(Steerable.updateTick, function(self, dt)
    if self.isEntered and self.isClient then
        self.modQC_updateTick_dt = (dt > 0) and dt or 1
        self.modQC_update_dtSum = 0
    end
end);

VehicleCamera.update = Utils.prependedFunction(VehicleCamera.update, function(self, dt)
    self.vehicle.modQC_update_dtSum = self.vehicle.modQC_update_dtSum + dt
    if self.vehicle.rotatedTime ~= nil and self.vehicle.rotatedTime ~= 0 then
        self.vehicle.modQC_rotateSumTime = self.vehicle.modQC_rotateSumTime + dt*0.001
    else
        self.vehicle.modQC_rotateSumTime = 0
    end
end);

VehicleCamera.onActivate = Utils.prependedFunction(VehicleCamera.onActivate, function(self)
    self.vehicle.modQC_previous_rotatedTime = adjustForDeadZone(self.vehicle.rotatedTime) -- Fix for when 1st camera is the 'isInside'.
    self.vehicle.modQC_updateTick_dt = 1;
    self.vehicle.modQC_update_dtSum = 0;
    self.vehicle.modQC_rotateSumTime = 0
end);

local mod_half_pi = math.pi/2

-- Re-implementing the entire `VehicleCamera.updateRotateNodeRotation` method, 
-- just to be able to add the code that does the panning of the camera when steering.
VehicleCamera.updateRotateNodeRotation = function(self)
    local rotY = self.rotY;

-- Decker_MMIV >>
    --if self.rotYSteeringRotSpeed ~= 0 and self.vehicle.rotatedTime ~= nil then
    --    rotY = rotY + self.vehicle.rotatedTime*self.rotYSteeringRotSpeed;
    --end
    
    if self.isInside and self.vehicle.steeringEnabled and VehicleCamera.modQC_PanCamera_enabled then
        if self.vehicle.rotatedTime ~= nil then
            if (self.origRotY - mod_half_pi) >= rotY or rotY >= (self.origRotY + mod_half_pi) then
                -- When looking backwards, then do not pan camera
            else
                -- Note: `rotatedTime` is only updated every updateTick() on server, or at every readUpdateStream() on clients.
                -- However this updateRotateNodeRotation() method is called at every update() - i.e. at every frame.
                -- Observed that "predicting" the future value of `rotatedTime` caused "snapping" when using analog steering-wheel, 
                -- so the algorithm it now changed to instead calculate it as; "from previous value bringing it up to the present value".
                
                local diffPrevRotatedTime = adjustForDeadZone(self.vehicle.rotatedTime) - self.vehicle.modQC_previous_rotatedTime
                local rotateTimePredict = diffPrevRotatedTime * (self.vehicle.modQC_update_dtSum / self.vehicle.modQC_updateTick_dt)
                local rotateTime = (self.vehicle.modQC_previous_rotatedTime + rotateTimePredict)
                
                -- Attempt to avoid that "snapping" that occurs when centering due to rotating-back
                if (self.vehicle.rotatedTime < 0 and rotateTimePredict > 0 and rotateTime > 0) then
                    rotateTime = 0
                elseif (self.vehicle.rotatedTime > 0 and rotateTimePredict < 0 and rotateTime < 0) then
                    rotateTime = 0
                end
                
                -- Attempt to smooth the initial camera-panning, so it won't be as harsh for small quick adjustments.
                rotateTime = rotateTime * (1 - math.cos(math.min(self.vehicle.modQC_rotateSumTime, mod_half_pi)))
                
                local rotRad = math.sin(rotateTime / self.vehicle.maxRotTime)
                
                if self.vehicle.isReverseDriving == true then
                    rotY = rotY + rotRad * -VehicleCamera.modQC_PanCamera_factor
                else
                    rotY = rotY + rotRad * VehicleCamera.modQC_PanCamera_factor
                end
            end
        end
    elseif self.rotYSteeringRotSpeed ~= 0 and self.vehicle.rotatedTime ~= nil then
        rotY = rotY + self.vehicle.rotatedTime*self.rotYSteeringRotSpeed;
    end
-- << Decker_MMIV

    if self.useWorldXZRotation then
        local upx,upy,upz = 0,1,0;

        local dx,dy,dz = localDirectionToWorld(getParent(self.rotateNode), 0,0,1);
        local invLen = 1/math.sqrt(dx*dx + dz*dz);
        dx = dx*invLen;
        dz = dz*invLen;

-- Decker_MMIV >>
        --local newDx = math.cos(self.rotX) * (math.cos(rotY)*dx + math.sin(rotY)*dz);
        --local newDy = -math.sin(self.rotX);
        --local newDz = math.cos(self.rotX) * (-math.sin(rotY)*dx + math.cos(rotY)*dz);
        
        local cosX = math.cos(self.rotX)
        local cosY = math.cos(rotY)
        local sinY = math.sin(rotY)

        local newDx = cosX * (cosY*dx + sinY*dz);
        local newDy = -math.sin(self.rotX);
        local newDz = cosX * (-sinY*dx + cosY*dz);
-- << Decker_MMIV

        newDx,newDy,newDz = worldDirectionToLocal(getParent(self.rotateNode), newDx,newDy,newDz);
        upx,upy,upz = worldDirectionToLocal(getParent(self.rotateNode), upx,upy,upz);

        setDirection(self.rotateNode, newDx,newDy,newDz, upx,upy,upz);
    else
        setRotation(self.rotateNode, self.rotX, rotY, self.rotZ);
    end;
end;
