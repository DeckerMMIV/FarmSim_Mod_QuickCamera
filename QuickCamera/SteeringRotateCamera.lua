
Drivable.updateVehiclePhysics = Utils.prependedFunction(Drivable.updateVehiclePhysics, function(self)
    self.mod_previous_rotatedTime = self.rotatedTime
end);

Steerable.updateTick = Utils.prependedFunction(Steerable.updateTick, function(self, dt)
    if self.isEntered and self.isClient then
        self.cameras[self.camIndex].mod_updateTick_dt = (dt > 0) and dt or 1
        self.cameras[self.camIndex].mod_update_dtSum = 0
    end
end);

VehicleCamera.update = Utils.prependedFunction(VehicleCamera.update, function(self, dt)
    self.mod_update_dtSum = self.mod_update_dtSum + dt
    if self.vehicle.rotatedTime ~= nil and self.vehicle.rotatedTime ~= 0 then
        self.mod_rotateSumTime = Utils.getNoNil(self.mod_rotateSumTime,0) + dt*0.001
    else
        self.mod_rotateSumTime = 0
    end
end);

VehicleCamera.onActivate = Utils.prependedFunction(VehicleCamera.onActivate, function(self)
    self.mod_updateTick_dt = 1;
    self.mod_update_dtSum = 0;
    self.mod_rotateSumTime = 0
end);

VehicleCamera.mod_PanCamera_enabled = true;
VehicleCamera.mod_MaxPanFactor = 0.6
local mod_half_pi = math.pi/2

VehicleCamera.updateRotateNodeRotation = function(self)
    local rotY = self.rotY;

-- Decker_MMIV >>
    --if self.rotYSteeringRotSpeed ~= 0 and self.vehicle.rotatedTime ~= nil then
    --    rotY = rotY + self.vehicle.rotatedTime*self.rotYSteeringRotSpeed;
    --end
    
    if self.isInside and VehicleCamera.mod_PanCamera_enabled then
        if self.vehicle.rotatedTime ~= nil then
            local modifierBackwards = VehicleCamera.mod_MaxPanFactor
--[[
            -- If looking backwards, then switch the panning left/right.
            if (self.origRotY - mod_half_pi) >= rotY or rotY >= (self.origRotY + mod_half_pi) then
                modifierBackwards = -modifierBackwards
            end
--]]
            -- If looking backwards, then do not pan camera
            if (self.origRotY - mod_half_pi) >= rotY or rotY >= (self.origRotY + mod_half_pi) then
                modifierBackwards = 0
            end
--
--[[
            -- If "going backwards" to the camera direction, then do not pan left/right.
            if self.vehicle.movingDirection > 0 and modifierBackwards < 0 then
                -- Attempt to avoid a "sudden reset to center", but instead "ease it to center" at 5% per tick.
                VehicleCamera.mod_TickModifier = math.max(0, Utils.getNoNil(VehicleCamera.mod_TickModifier,0)) + 0.05
                modifierBackwards = modifierBackwards * Utils.clamp((1 - VehicleCamera.mod_TickModifier), 0, 1)
            elseif self.vehicle.movingDirection < 0 and modifierBackwards > 0 then
                -- Attempt to avoid a "sudden reset to center", but instead "ease it to center" at 5% per tick.
                VehicleCamera.mod_TickModifier = math.min(0, Utils.getNoNil(VehicleCamera.mod_TickModifier,0)) - 0.05
                modifierBackwards = modifierBackwards * Utils.clamp((1 + VehicleCamera.mod_TickModifier), 0, 1)
            end
--]]
            
            -- Note: `rotatedTime` is only updated every updateTick() on server, or at every readUpdateStream() on clients.
            -- However this updateRotateNodeRotation() method is called at every update() - i.e. at every frame.
            -- Somehow I need to "predict" what `rotatedTime` should actually be, to avoid the camera rotation choppiness.
            
            if modifierBackwards == 0 then
                -- do nothing
            else
                local diffPrevRotatedTime = self.vehicle.rotatedTime - self.vehicle.mod_previous_rotatedTime
                
                local rotateTimePredict = diffPrevRotatedTime * (self.mod_update_dtSum / self.mod_updateTick_dt)
                
                --local rotateTime = (self.vehicle.rotatedTime + rotateTimePredict)
                local rotateTime = (self.vehicle.mod_previous_rotatedTime + rotateTimePredict)
                
                -- Attempt to avoid that "snapping" that occurs when centering due to rotating-back
                if (self.vehicle.rotatedTime < 0 and rotateTimePredict > 0 and rotateTime > 0) then
                    rotateTime = 0
                elseif (self.vehicle.rotatedTime > 0 and rotateTimePredict < 0 and rotateTime < 0) then
                    rotateTime = 0
                end
                
                -- Attempt to smooth the initial camera-panning, so it won't be as harsh for small quick adjustments.
                rotateTime = rotateTime * (1 - math.cos(math.min(self.mod_rotateSumTime, mod_half_pi)))
                
                local rotRad = math.sin(rotateTime / self.vehicle.maxRotTime)
                rotY = rotY + rotRad * modifierBackwards
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
