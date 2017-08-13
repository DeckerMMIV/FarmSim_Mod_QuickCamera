--
-- QuickCamera sub-component: Camera steering rotation-fix for articulated vehicles.
--
-- @author  Decker_MMIV - fs-uk.com, modcentral.co.uk, forum.farming-simulator.com
-- @date    2017-08-xx
--

addConsoleCommand("modQuickCameraSteeringRotSpeed", "(QuickCamera) Modify steering rotation speed", "consoleCommandQuickCameraSteeringRotSpeed", QuickCamera)

QuickCamera.consoleCommandQuickCameraSteeringRotSpeed = function(self, arg1)
    local txt = "Not in an articulated vehicle, or current vehicle-camera not rotatable.\n"
    local updateCfgFile = false

    local function isCameraAcceptable(veh)
        return nil ~= veh and nil ~= veh.interpolatedRotatedTime and nil ~= veh.cameras and true == veh.cameras[veh.camIndex].isRotatable
    end

    local newValue = tonumber(arg1)
    arg1 = nil ~= arg1 and arg1:lower() or nil
    local curVeh = g_currentMission.controlledVehicle

    if "on" == arg1 then
        if isCameraAcceptable(curVeh) then
            if true == QuickCamera:steerRotFixApply(curVeh, curVeh.camIndex, nil, true) then
                txt = "Feature is turned ON for active camera.\n"
                updateCfgFile = true
            else
                txt = "Failed to turn on feature for active camera.\n"
            end
        end
    elseif "off" == arg1 then
        if isCameraAcceptable(curVeh) then
            if true == QuickCamera:steerRotFixApply(curVeh, curVeh.camIndex, nil, false) then
                txt = "Feature is turned OFF for active camera.\n"
                updateCfgFile = true
            else
                txt = "Failed to turn off feature for active camera.\n"
            end
        end
    elseif "toggle" == arg1 then
        if false ~= QuickCamera.steerRotFix_enabled then
            -- Disable
            QuickCamera.steerRotFix_enabled = false
            if true == QuickCamera:steerRotFixApply(nil, nil, nil, false) then
                txt = "Feature have been DISABLED for all affected vehicles.\n"
                updateCfgFile = true
            else
                txt = "Failed to disable feature.\n"
            end
        else
            -- Enable
            QuickCamera.steerRotFix_enabled = true
            if true == QuickCamera:steerRotFixApply(nil, nil, nil, true) then
                txt = "Feature have been ENABLED for all affected vehicles.\n"
                updateCfgFile = true
            else
                txt = "Failed to enable feature.\n"
            end
        end
    elseif nil == arg1 or nil ~= newValue then
        if isCameraAcceptable(curVeh) then
            if nil ~= newValue then
                if false == QuickCamera.steerRotFix_enabled then
                    txt =  "Feature is currently set to be disabled for all vehicles.\n"
                        .. "To enable it, issue this command with argument; TOGGLE\n"
                elseif true == QuickCamera:steerRotFixApply(curVeh, curVeh.camIndex, newValue, true) then
                    txt = ("Updated camera (#%d) rotYSteeringRotSpeed to: %.2f\n"):format(curVeh.camIndex, curVeh.cameras[curVeh.camIndex].rotYSteeringRotSpeed)
                    updateCfgFile = true
                else
                    txt = "Failed to update camera rotYSteeringRotSpeed\n"
                end
            else
                txt = ("This camera (#%d) rotYSteeringRotSpeed is: %.2f\n"):format(curVeh.camIndex, curVeh.cameras[curVeh.camIndex].rotYSteeringRotSpeed)
            end
        end
    else
        txt =  "Unknown argument.\n"
            .. "Syntax for the command is:\n"
            .. " > modQuickCameraSteeringRotSpeed\n"
            .. "   - to get current value for active camera.\n"
            .. " > modQuickCameraSteeringRotSpeed <NUMERIC-VALUE>\n"
            .. "   - to set new value for active camera.\n"
            .. " > modQuickCameraSteeringRotSpeed OFF\n"
            .. "   - turns off the feature for just this active camera.\n"
            .. " > modQuickCameraSteeringRotSpeed ON\n"
            .. "   - turns on the feature for just this active camera.\n"
            .. " > modQuickCameraSteeringRotSpeed TOGGLE\n"
            .. "   - to disable/enable the feature entirely for all affected vehicles.\n"
    end

    if updateCfgFile then
        QuickCamera:steerRotFix_SaveCfg(QuickCamera.cfgPath, QuickCamera.cfgFilename)
    end

    return txt
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
    local foundUserCfg = QuickCamera:steerRotFix_LoadCfg(QuickCamera.cfgPath, QuickCamera.cfgFilename)
    if false == foundUserCfg then
        QuickCamera:steerRotFix_SaveCfg(QuickCamera.cfgPath, QuickCamera.cfgFilename)
    end

    print("QuickCamera: Articulated vehicles steering rotation camera fix is; " .. (false == QuickCamera.steerRotFix_enabled and "Disabled" or "Enabled"))
    if false ~= QuickCamera.steerRotFix_enabled then
        print("QuickCamera: To modify steering rotation camera value, use console-command 'modQuickCameraSteeringRotSpeed'")
    end

    QuickCamera.prefixes = { g_modsDirectory:lower() }
    for _,attrs in pairs(g_dlcsDirectories) do
        if attrs.isLoaded then
            table.insert(QuickCamera.prefixes, attrs.path:lower())
        end
    end
end

QuickCamera.steerRotFixApply = function(self, vehicle, camIndex, newRotSpeed, enabled)
    if nil ~= g_dedicatedServerInfo then
        -- This fix is only for client-side
        return nil
    end

    QuickCamera:steerRotFixInit();

    local function getSuffixConfigFileName(vehicle)
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

    local function updateCameraYSteeringRotSpeed(veh, attrs)
        local camera = veh.cameras[attrs.camIndex]
        if nil ~= camera and camera.isRotatable then
            if false == attrs.enabled then
                camera.rotYSteeringRotSpeed = camera.modQcOrigRotYSteeringRotSpeed
            else
                camera.rotYSteeringRotSpeed = attrs.rotSpeed
            end
        end
    end
    
    if nil == vehicle and nil == camIndex and nil == newRotSpeed and nil ~= enabled then
        -- Affect all vehicles
        for _,veh in pairs(g_currentMission.steerables) do
            if nil ~= veh.cameras then
                if false == enabled then
                    for _,camera in pairs(veh.cameras) do
                        if nil ~= camera.rotYSteeringRotSpeed then
                            camera.rotYSteeringRotSpeed = camera.modQcOrigRotYSteeringRotSpeed
                        end
                    end
                else
                    local vehCfg = getSuffixConfigFileName(veh)
                    local steerRotFix = QuickCamera.steerRotFixCfg[vehCfg]
                    if nil ~= steerRotFix then
                        for _,attrs in pairs(steerRotFix) do
                            updateCameraYSteeringRotSpeed(veh, attrs)
                        end
                    end
                end
            end
        end
        return true
    end

    if nil == vehicle or nil == vehicle.cameras then
        return false
    end
    
    local vehCfg = getSuffixConfigFileName(vehicle)
    local steerRotFix = Utils.getNoNil(QuickCamera.steerRotFixCfg[vehCfg], {})
    
    if nil ~= camIndex and (nil ~= newRotSpeed or nil ~= enabled) then
        local attrs = nil
        for _,elem in pairs(steerRotFix) do
            if camIndex == elem.camIndex then
                attrs = elem
                attrs.rotSpeed = Utils.getNoNil(newRotSpeed, attrs.rotSpeed)
                attrs.enabled = enabled
                break
            end
        end
        if nil == attrs then
            attrs = {camIndex=camIndex, rotSpeed=Utils.getNoNil(newRotSpeed,0), enabled=enabled}
            table.insert(steerRotFix, attrs)
            QuickCamera.steerRotFixCfg[vehCfg] = steerRotFix
        end
        updateCameraYSteeringRotSpeed(vehicle, attrs)
    elseif nil == camIndex and nil == newRotSpeed and nil == enabled then
        if false ~= QuickCamera.steerRotFix_enabled then
            for _,attrs in pairs(steerRotFix) do
                updateCameraYSteeringRotSpeed(vehicle, attrs)
            end
        end
    else
        return false
    end
    
    return true
end

QuickCamera.steerRotFix_LoadCfg = function(self, path, filename)
    if nil ~= g_dedicatedServerInfo then
        -- This fix is only for client-side
        return nil
    end

    local pathFilename = path .. filename
    if not fileExists(pathFilename) then
        return false
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
                local enabled  = getXMLBool(  xmlFile, tag2 .. "#enabled")
                local camIndex = getXMLInt(   xmlFile, tag2 .. "#camIdx")
                local rotSpeed = getXMLFloat( xmlFile, tag2 .. "#rotSpeed")
                if nil == camIndex or nil == rotSpeed then
                    break
                end
                steerRotFix = Utils.getNoNil(steerRotFix, {})
                table.insert(steerRotFix, {camIndex=camIndex, rotSpeed=rotSpeed, enabled=enabled})
            end
            
            if nil ~= steerRotFix then
                QuickCamera.steerRotFixCfg[vehCfg:lower()] = steerRotFix
            end
        end
        
        delete(xmlFile);
        xmlFile = nil;
    end

    return true
end

QuickCamera.steerRotFix_SaveCfg = function(self, path, filename)
    if nil ~= g_dedicatedServerInfo then
        -- This fix is only for client-side
        return
    end

    local pathFilename = path .. filename
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
                if nil ~= attrs.camIndex and nil ~= attrs.rotSpeed then
                    local tag2 = ("%s.camera(%d)"):format(tag, j)
                    j=j+1
                    if nil ~= attrs.enabled then
                        setXMLBool(xmlFile, tag2 .. "#enabled", attrs.enabled)
                    end
                    setXMLInt(   xmlFile, tag2 .. "#camIdx", attrs.camIndex)
                    setXMLString(xmlFile, tag2 .. "#rotSpeed", ("%.2f"):format(attrs.rotSpeed))
                end
            end
        end
        saveXMLFile(xmlFile)
        delete(xmlFile);
        xmlFile = nil;
    end
end

if nil == g_dedicatedServerInfo then
    Steerable.postLoad = Utils.appendedFunction(Steerable.postLoad, function(self, xmlFile)
        -- Only for vehicles using ArticulatedAxis.LUA
        if nil ~= self.interpolatedRotatedTime then
            for _,camera in pairs(self.cameras) do
                if nil ~= camera.rotYSteeringRotSpeed then
                    camera.modQcOrigRotYSteeringRotSpeed = camera.rotYSteeringRotSpeed
                end
            end
            
            QuickCamera:steerRotFixApply(self)
        end
    end);
end
