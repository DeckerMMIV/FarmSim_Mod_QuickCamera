--
-- QuickCamera sub-component: Camera steering rotation-fix for articulated vehicles.
--
-- @author  Decker_MMIV - fs-uk.com, modcentral.co.uk, forum.farming-simulator.com
-- @date    2017-08-xx
--

addConsoleCommand("modQuickCameraSteeringRotSpeed", "(QuickCamera) Modify steering rotation speed", "consoleCommandQuickCameraSteeringRotSpeed", QuickCamera)

QuickCamera.consoleCommandQuickCameraSteeringRotSpeed = function(self, arg1)
    local curVeh = g_currentMission.controlledVehicle
    if nil == curVeh or nil == curVeh.cameras or true ~= curVeh.cameras[curVeh.camIndex].isRotatable then
        return "Not in a vehicle, or current vehicle-camera not rotatable"
    end
    
    local newValue = tonumber(arg1)
    if nil ~= newValue then
        QuickCamera:steerRotFixApply(curVeh, curVeh.camIndex, newValue)
    end
    print("This camera (#"..curVeh.camIndex..") rotYSteeringRotSpeed is: "..tostring(curVeh.cameras[curVeh.camIndex].rotYSteeringRotSpeed))
end

---

QuickCamera.modDir = g_currentModDirectory
QuickCamera.steerRotFixCfg = nil

QuickCamera.steerRotFixInit = function(self)
    if nil ~= g_dedicatedServerInfo then
        -- This fix is only for client-side
        return
    end
    if nil ~= QuickCamera.steerRotFixCfg then
        -- Already initialized
        return
    end

    QuickCamera.steerRotFixCfg = {}
    
    QuickCamera.cfgFilename = "QuickCamera_Config.xml"
    QuickCamera.cfgPath     = getUserProfileAppPath() .. "modsSettings/";
    
    QuickCamera:steerRotFix_LoadCfg(QuickCamera.modDir,  QuickCamera.cfgFilename)
    QuickCamera:steerRotFix_LoadCfg(QuickCamera.cfgPath, QuickCamera.cfgFilename)

    QuickCamera.prefixes = { g_modsDirectory:lower() }
    for _,attrs in pairs(g_dlcsDirectories) do
        if attrs.isLoaded then
            table.insert(QuickCamera.prefixes, attrs.path:lower())
        end
    end
end

QuickCamera.steerRotFixApply = function(self, vehicle, camIndex, newRotSpeed)
    if nil ~= g_dedicatedServerInfo then
        -- This fix is only for client-side
        return
    end
    if nil == vehicle or nil == vehicle.cameras or nil == vehicle.cameras[camIndex] then
        return
    end

    QuickCamera:steerRotFixInit();

    local vehCfg = QuickCamera:getSuffixConfigFileName(vehicle)
    local steerRotFix = Utils.getNoNil(QuickCamera.steerRotFixCfg[vehCfg], {})
    local found = false
    for _,attrs in pairs(steerRotFix) do
        if camIndex == attrs.camIndex then
            found = true
            attrs.rotSpeed = newRotSpeed
        end
    end
    if not found then
        table.insert(steerRotFix, {camIndex=camIndex, rotSpeed=newRotSpeed})
    end
    QuickCamera.steerRotFixCfg[vehCfg] = steerRotFix

    QuickCamera:steerRotFix_SaveCfg(QuickCamera.cfgPath, QuickCamera.cfgFilename)
    
    vehicle.cameras[camIndex].rotYSteeringRotSpeed = newRotSpeed
end

QuickCamera.getSuffixConfigFileName = function(self, vehicle)
    local configFileName = vehicle.configFileName:lower()
    if nil ~= vehicle.customEnvironment then
        for _,prefix in pairs(QuickCamera.prefixes) do
            if Utils.startsWith(configFileName, prefix) then
                configFileName = configFileName:sub(prefix:len())
                break
            end
        end
    end
    return configFileName
end

QuickCamera.steerRotFix_LoadCfg = function(self, path, filename)
    if nil ~= g_dedicatedServerInfo then
        -- This fix is only for client-side
        return
    end

    local pathFilename = path .. filename
--print("Attempt loading: "..pathFilename);
    if not fileExists(pathFilename) then
        return
    end

    local rootTag = "QuickCamera"
    local xmlFile = loadXMLFile(rootTag, pathFilename)
    if nil == xmlFile then
        print("QuickCamera: Failed loading: "..pathFilename)
    else
        QuickCamera.steerRotFix_enabled = Utils.getNoNil(getXMLBool(xmlFile, rootTag .. "#steeringRotationFixEnabled"), true)
    
        local i = 0
        while true do
            local tag = ("%s.%s(%d)"):format(rootTag, "steeringRotationFix", i)
            i=i+1
            local vehCfg = getXMLString(xmlFile, tag .. "#vehCfg")
            if nil == vehCfg then
                break
            end
            
            local steerRotFix = nil
            local j = 0
            while true do
                local tag2 = ("%s.camera(%d)"):format(tag, j)
                j=j+1
                local camIndex = getXMLInt(   xmlFile, tag2 .. "#camIdx")
                local rotSpeed = getXMLFloat( xmlFile, tag2 .. "#rotSpeed")
                if nil == camIndex or nil == rotSpeed then
                    break
                end
                steerRotFix = Utils.getNoNil(steerRotFix, {})
                table.insert(steerRotFix, {camIndex=camIndex, rotSpeed=rotSpeed})
            end
            
            if nil ~= steerRotFix then
                QuickCamera.steerRotFixCfg[vehCfg:lower()] = steerRotFix
            end
        end
        
        delete(xmlFile);
        xmlFile = nil;
        
        if false == QuickCamera.steerRotFix_enabled then
            print("QuickCamera: Articulated vehicles steering rotation camera fix is; Disabled")
        else
            print("QuickCamera: Articulated vehicles steering rotation camera fix settings ("..i..") loaded from; "..pathFilename)
        end
    end
end

QuickCamera.steerRotFix_SaveCfg = function(self, path, filename)
    if nil ~= g_dedicatedServerInfo then
        -- This fix is only for client-side
        return
    end

    local pathFilename = path .. filename
--print("Attempt saving: "..pathFilename);
    createFolder(path)
    
    local rootTag = "QuickCamera"
    local xmlFile = createXMLFile(rootTag, pathFilename, rootTag)
    if nil == xmlFile then
        print("QuickCamera: Failed saving: "..pathFilename)
    else
        setXMLBool(xmlFile, rootTag .. "#steeringRotationFixEnabled", Utils.getNoNil(QuickCamera.steerRotFix_enabled, true))
    
        local i=0
        for vehCfg,steerRotFix in pairs(QuickCamera.steerRotFixCfg) do
            local tag = ("%s.%s(%d)"):format(rootTag, "steeringRotationFix", i)
            i=i+1
            setXMLString(xmlFile, tag .. "#vehCfg", vehCfg:lower())
            local j=0
            for _,attrs in pairs(steerRotFix) do
                local tag2 = ("%s.camera(%d)"):format(tag, j)
                setXMLInt(   xmlFile, tag2 .. "#camIdx", attrs.camIndex)
                setXMLString(xmlFile, tag2 .. "#rotSpeed", ("%.2f"):format(attrs.rotSpeed))
            end
        end
        saveXMLFile(xmlFile)
        delete(xmlFile);
        xmlFile = nil;
    end
end

Steerable.postLoad = Utils.appendedFunction(Steerable.postLoad, function(self, xmlFile)
    QuickCamera:steerRotFixInit();

    if false ~= QuickCamera.steerRotFix_enabled then
        local steerRotFix = QuickCamera.steerRotFixCfg[QuickCamera:getSuffixConfigFileName(self)]
        if nil ~= steerRotFix then
            for _,attrs in pairs(steerRotFix) do
                local camera = self.cameras[attrs.camIndex]
                if nil ~= camera and true == camera.isRotatable then
                    camera.rotYSteeringRotSpeed = attrs.rotSpeed
                end
            end
        end
    end
end);
