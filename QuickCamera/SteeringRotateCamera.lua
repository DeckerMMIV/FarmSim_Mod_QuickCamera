
VehicleCamera.updateRotateNodeRotation = function(self)
    local rotY = self.rotY;

-- Decker_MMIV >>
    --if self.rotYSteeringRotSpeed ~= 0 and self.vehicle.rotatedTime ~= nil then
    --    rotY = rotY + self.vehicle.rotatedTime*self.rotYSteeringRotSpeed;
    --end
    
    if self.isInside then
        if self.vehicle.rotatedTime ~= nil then
            local modifierBackwards = 1
            if (self.origRotY - math.pi/2) >= rotY or rotY >= (self.origRotY + math.pi/2) then
                modifierBackwards = -modifierBackwards
            end
            
            if self.vehicle.rotatedTime >= 0 then
                rotY = rotY + (1 - math.cos(self.vehicle.rotatedTime / self.vehicle.maxRotTime)) * modifierBackwards
                --rotY = rotY + (self.vehicle.rotatedTime / self.vehicle.maxRotTime) * modifierBackwards
            else
                rotY = rotY - (1 - math.cos(self.vehicle.rotatedTime / self.vehicle.minRotTime)) * modifierBackwards
                --rotY = rotY - (self.vehicle.rotatedTime / self.vehicle.minRotTime) * modifierBackwards
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

        local newDx = math.cos(self.rotX) * (math.cos(rotY)*dx + math.sin(rotY)*dz);
        local newDy = -math.sin(self.rotX);
        local newDz = math.cos(self.rotX) * (-math.sin(rotY)*dx + math.cos(rotY)*dz);

        newDx,newDy,newDz = worldDirectionToLocal(getParent(self.rotateNode), newDx,newDy,newDz);
        upx,upy,upz = worldDirectionToLocal(getParent(self.rotateNode), upx,upy,upz);

        setDirection(self.rotateNode, newDx,newDy,newDz, upx,upy,upz);
    else
        setRotation(self.rotateNode, self.rotX, rotY, self.rotZ);
    end;
end;