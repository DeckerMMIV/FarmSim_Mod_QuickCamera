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
        if Utils.endsWith(self.configFileName, "/newHolland/newHollandW170C.xml")      -- Wheelloader
        then
            newYRotSpeed = 0.8
        end
    else
        if Utils.endsWith(self.configFileName, "/steerable/liebherr/liebherrL538.xml")      -- Wheelloader
        then
            newYRotSpeed = 0.8
        end
    end

    if  ModsSettings ~= nil 
    and ModsSettings.isVersion ~= nil 
    and ModsSettings.isVersion("0.2.0", "QuickCamera")
    then
        local modName = "QuickCamera"
        local keyName = "outsideCameraFix"
        
        local i=-1
        while true do
            i=i+1
            local tag = ("%s(%d)"):format(keyName, i)
            if not ModsSettings.hasKeyLocal(modName, tag) then
                if i == 0 then
                    tag = ("%s(%d)"):format(keyName, 0)
                    --ModsSettings.setStringLocal(modName, tag, "customEnvironment", nil)
                    ModsSettings.setStringLocal(modName, tag, "fileNameEndsWith", "/steerable/liebherr/liebherrL538.xml")
                    ModsSettings.setFloatLocal( modName, tag, "rotYSteeringRotSpeed", 0.8)
                    --
                    tag = ("%s(%d)"):format(keyName, 1)
                    ModsSettings.setStringLocal(modName, tag, "customEnvironment", "FS15_newHollandLoaderPack")
                    ModsSettings.setStringLocal(modName, tag, "fileNameEndsWith", "/newHolland/newHollandW170C.xml")
                    ModsSettings.setFloatLocal( modName, tag, "rotYSteeringRotSpeed", 0.8)
                    --
                    tag = ("%s(%d)"):format(keyName, 2)
                    ModsSettings.setStringLocal(modName, tag, "customEnvironment", "pdlc_jcbPack")
                    ModsSettings.setStringLocal(modName, tag, "fileNameEndsWith", "/jcbPack/jcb/jcb435s.xml")
                    ModsSettings.setFloatLocal( modName, tag, "rotYSteeringRotSpeed", 0.8)
                    --
                    tag = ("%s(%d)"):format(keyName, 3)
                    ModsSettings.setStringLocal(modName, tag, "customEnvironment", "pdlc_jcbPack")
                    ModsSettings.setStringLocal(modName, tag, "fileNameEndsWith", "/jcbPack/jcb/jcbTM320s.xml")
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
