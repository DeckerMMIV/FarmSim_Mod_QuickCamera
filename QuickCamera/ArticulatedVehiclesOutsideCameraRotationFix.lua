--
-- QuickCamera sub-component: 'Outside camera' rotation-fix for articulated wheelloaders.
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-September
--

Steerable.postLoad = Utils.appendedFunction(Steerable.postLoad, function(self, xmlFile)
    if not self.isClient then
        return
    end

    local newYRotSpeed = nil

    if self.customEnvironment == "pdlc_jcbPack" then
        if Utils.endsWith(self.configFileName, "/jcbPack/jcb/jcb435s.xml")      -- Wheelloader
        or Utils.endsWith(self.configFileName, "/jcbPack/jcb/jcbTM320s.xml")    -- Telehandler
        then
            newYRotSpeed = 0.8
        end
    elseif self.customEnvironment == "FS15_newHollandLoaderPack" then
        if Utils.endsWith(self.configFileName, "/FS15_newHollandLoaderPack/newHolland/newHollandW170C.xml")      -- Wheelloader
        then
            newYRotSpeed = 0.8
        end
    else
        if Utils.endsWith(self.configFileName, "/steerable/liebherr/liebherrL538.xml")      -- Wheelloader
        then
            newYRotSpeed = 0.8
        end
    end

    if ModsSettings ~= nil and ModsSettings.isVersion("0.2.0", "QuickCamera") then
        local modName = "QuickCamera"
        local keyName = "outsideCameraFix"
        
        local i=-1
        while true do
            i=i+1
            local tag = ("%s(%d)"):format(keyName, i)
            if not ModsSettings.hasKeyLocal(modName, tag) then
                if i == 1 then
                    ModsSettings.setStringLocal(modName, tag, "customEnvironment", "examplePack")
                    ModsSettings.setStringLocal(modName, tag, "fileNameEndsWith", "/exampleFolder/exampleVehicle.xml")
                    ModsSettings.setFloatLocal( modName, tag, "rotYSteeringRotSpeed", 0.8)
                end
                break
            end
            
            local customEnvironment = ModsSettings.getStringLocal(modName, tag, "customEnvironment", nil)
            local filenameEndsWith  = ModsSettings.getStringLocal(modName, tag, "fileNameEndsWith", nil)
            local rotSpeed          = ModsSettings.getFloatLocal( modName, tag, "rotYSteeringRotSpeed", nil)
                  
            if customEnvironment == nil or customEnvironment == self.customEnvironment then
                if filenameEndsWith ~= nil and Utils.endsWith(self.configFileName, filenameEndsWith) then
                    newYRotSpeed = rotSpeed
                    break
                end
            end
        end
    end
    
    if newYRotSpeed ~= nil then
        print("Articulated vehicle outside camera rotation-fix applied to: "..self.configFileName);
        for _,camera in pairs(self.cameras) do
            if  true  == camera.isRotatable 
            and false == camera.isInside 
            then
                camera.rotYSteeringRotSpeed = newYRotSpeed
            end
        end
    end
end);
