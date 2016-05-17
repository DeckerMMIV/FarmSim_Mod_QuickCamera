--
-- QuickCamera
--      By quick-tap'ing the camera-movement keys, rotation will snap to next nearest 45-degree, and zoom will be faster.
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2012-January
--
-- @notes
--          A special "thank you" to Templaer and his 'Camera' mod, from which I got inspiration to make this QuickCamera mod.
--

--[[
Suggestions
-----------

Wrongway
    An option to glance left or right returning to forward view would be very useful, but might not be easy to implement. 
    http://www.ls-uk.info/forum/index.php?topic=118579.msg789306#msg789306

Kyuss33
    I was wondering if anyone has a mod that allows you to adjust the height of your head or view in the cabin.
    I feel like I'm a 7 foot person in harvester's cabin view.I have seen quick camera mod that allows for saving previous cameras 
    but I don't think it adjust the up down or height in cabin
    http://forum.giants-software.com/viewtopic.php?f=831&t=77401
]]

QuickCamera = {};
--
local modItem = ModsUtil.findModItemByModName(g_currentModName);
QuickCamera.version = (modItem and modItem.version) and modItem.version or "?.?.?";
--
-- Default values
QuickCamera.quickRotateKeyTapMaxTimeMs  = 150;
QuickCamera.quickZoomDistance           = 15;
--
QuickCamera.panCamera_enabled = false
QuickCamera.panCamera_factor  = 0.6
--
QuickCamera.forceResetCamera = false;
QuickCamera.enableAutoResetCamera = false;
QuickCamera.useWorldXZRotation = false;

local math_pi_double  = math.pi*2
local math_pi_half    = math.pi/2
local math_pi_quarter = math.pi/4


function QuickCamera.postLoad(self, xmlFile)
    if not QuickCamera.constantsLoaded then
        QuickCamera.constantsLoaded = true

        if  self.isClient 
        and ModsSettings ~= nil 
        and ModsSettings.isVersion ~= nil 
        and ModsSettings.isVersion("0.2.0", "QuickCamera")
        then
            local modName = "QuickCamera";
            --
            local keyName = "cabinCameraPanning";
            QuickCamera.panCamera_enabled = ModsSettings.getBoolLocal( modName ,keyName ,"enabled" ,QuickCamera.panCamera_enabled)
            QuickCamera.panCamera_factor  = ModsSettings.getFloatLocal(modName ,keyName ,"factor"  ,QuickCamera.panCamera_factor )
            --
            keyName = "quickTapKeys";
            QuickCamera.quickRotateKeyTapMaxTimeMs = ModsSettings.getIntLocal(modName ,keyName ,"maxTimeMs"    ,QuickCamera.quickRotateKeyTapMaxTimeMs)
            QuickCamera.quickZoomDistance          = ModsSettings.getIntLocal(modName ,keyName ,"zoomDistance" ,QuickCamera.quickZoomDistance         )
        end
    end
end

function QuickCamera.update(self, superFunc, dt)
    -- TRICK: Do not allow Steerable:update() to switch camera. 
    -- This could break other mods that tests against InputBinding.CAMERA_SWITCH, but I know of none yet.
    local hasEvent = InputBinding.actions[InputBinding.CAMERA_SWITCH].hasEvent;
    InputBinding.actions[InputBinding.CAMERA_SWITCH].hasEvent = false;
    -- Execute the normal Steerable:update()
    superFunc(self, dt);
    --
    InputBinding.actions[InputBinding.CAMERA_SWITCH].hasEvent = hasEvent;

    --
    if not (self.isEntered and self.isClient and (not g_currentMission.isPlayerFrozen) and g_gui.currentGui == nil) then
        -- Player not in vehicle, or not active for input.
        self.qcPressKeyTime = nil;
    else
        -- The CAMERA_SWITCH now has two actions; 
        --      press-and-release(less than 500ms) -> switch camera
        --      press-and-hold(more than 500ms)    -> reset current camera
        if InputBinding.isPressed(InputBinding.CAMERA_SWITCH) then
            if self.qcPressKeyTime == nil then
                -- Press-key begun
                self.qcPressKeyTime = g_currentMission.time;
            elseif (g_currentMission.time - self.qcPressKeyTime) > 500 then
                -- Press-and-hold -> Reset current camera
                self.qcPressKeyTime = g_currentMission.time + 1000*60*60*24; -- 24 hours.
                QuickCamera.forceResetCamera = true;
                self.cameras[self.camIndex]:resetCamera();
                --
                self.cameras[self.camIndex].useWorldXZRotation = not self.cameras[self.camIndex].useWorldXZRotation;
                print(("QuickCamera: For camera-index #%d toggled 'useWorldXZRotation' to: %s"):format(self.camIndex, self.cameras[self.camIndex].useWorldXZRotation))
            end
        elseif self.qcPressKeyTime ~= nil then
            local keyDelay = g_currentMission.time - self.qcPressKeyTime;
            self.qcPressKeyTime = nil;
            if keyDelay > 0 and keyDelay < 500 then
                -- Press-and-release -> Switch to next camera
                QuickCamera.changeToCamera(self, (self.camIndex % self.numCameras) + 1);
            end
        end

        --
        if InputBinding.hasEvent(InputBinding.QuickCamToggleReset, true) then
            QuickCamera.enableAutoResetCamera = not QuickCamera.enableAutoResetCamera;
            QuickCamera.forceResetCamera = QuickCamera.enableAutoResetCamera;
            print("QuickCam: 'Auto-reset camera' is now set to: "..tostring(QuickCamera.enableAutoResetCamera));
        end
        
        -- Smooth'ish rotation
        if self.qc ~= nil then
            if self.qc.CamIndex == self.camIndex then
                if self.qc.accTime ~= nil then
                    self.qc.accTime = self.qc.accTime + dt;
                else
                    self.qc.accTime = 0;
                end;
                -- TODO: Fix the problem where it revolves 359 degrees, instead of just -1 degree.
                local newCamRot = Utils.getMovedLimitedValues(self.qc.CamSourceRot, self.qc.CamSourceRot, self.qc.CamTargetRot, 2, self.qc.CamTime, self.qc.accTime, true);
--print(string.format("%3d; sourceRot=%s; targetRot=%s; newCamRot=%s", self.qc.accTime, vec2str(self.qc.CamSourceRot), vec2str(self.qc.CamTargetRot), vec2str(newCamRot)));
                self.cameras[self.camIndex].rotX = newCamRot[1];
                self.cameras[self.camIndex].rotY = newCamRot[2];
                --
                if self.qc.accTime >= self.qc.CamTime then
                    self.qc = nil;
                end;
            else
                self.qc = nil;
            end;
        end;
        -- Detect action-keys for rotatable camera
        if self.cameras[self.camIndex].isRotatable then
            if InputBinding.hasEvent(InputBinding.QuickCamLockCustom, true) then
                local camera = self.cameras[self.camIndex];
                if camera.modQuickCamera == nil then
                    camera.modQuickCamera = {}
                    camera.modQuickCamera.origRot = {x=camera.origRotX, y=camera.origRotY}
                    camera.modQuickCamera.customRot = {x=camera.rotX, y=camera.rotY}
                    camera.origRotX,camera.origRotY = camera.rotX,camera.rotY
                    print("QuickCam: Updated to new rotation")
                else
                    camera.origRotX,camera.origRotY = camera.modQuickCamera.origRot.x,camera.modQuickCamera.origRot.y
                    camera.modQuickCamera = nil
                    print("QuickCam: Reverted to original rotation")
                end
            end
            --
            local quickCamEvent = nil;
            if self.qcQuickTapType ~= nil then
                if not InputBinding.isPressed(self.qcQuickTapType) then
                    if (g_currentMission.time - self.qcPressedTime) <= QuickCamera.quickRotateKeyTapMaxTimeMs then
                        -- pressed-and-released within the time limit threshold.
                        quickCamEvent = self.qcQuickTapType;
                    end;
                    self.qcQuickTapType = nil;
                end;
            elseif self.qcQuickTapType == nil then
                if     InputBinding.hasEvent(InputBinding.QuickCamForBack)  then quickCamEvent = InputBinding.QuickCamForBack;
                elseif InputBinding.hasEvent(InputBinding.QuickCamForward)  then self.qcQuickTapType = InputBinding.QuickCamForward;    self.qcPressedTime = g_currentMission.time;
                elseif InputBinding.hasEvent(InputBinding.QuickCamBackward) then self.qcQuickTapType = InputBinding.QuickCamBackward;   self.qcPressedTime = g_currentMission.time;
                elseif InputBinding.hasEvent(InputBinding.QuickCamLeft)     then self.qcQuickTapType = InputBinding.QuickCamLeft;       self.qcPressedTime = g_currentMission.time;
                elseif InputBinding.hasEvent(InputBinding.QuickCamRight)    then self.qcQuickTapType = InputBinding.QuickCamRight;      self.qcPressedTime = g_currentMission.time;
                elseif InputBinding.hasEvent(InputBinding.QuickCamLeft2)    then self.qcQuickTapType = InputBinding.QuickCamLeft2;      self.qcPressedTime = g_currentMission.time;
                elseif InputBinding.hasEvent(InputBinding.QuickCamRight2)   then self.qcQuickTapType = InputBinding.QuickCamRight2;     self.qcPressedTime = g_currentMission.time;
                end; 
            end;
            --
            if quickCamEvent ~= nil then
--print("QuickCamEvent="..tostring(quickCamEvent));
              --
              local forwardArch = { self.cameras[self.camIndex].origRotY - math_pi_half, self.cameras[self.camIndex].origRotY + math_pi_half }
              --
              local rotY = self.cameras[self.camIndex].rotY;
              while (rotY < -math_pi_double) do rotY = rotY + math_pi_double; end
              while (rotY >  math_pi_double) do rotY = rotY - math_pi_double; end
              --
              if (quickCamEvent == InputBinding.QuickCamBackward or (quickCamEvent == InputBinding.QuickCamForBack and (forwardArch[1] < rotY and rotY < forwardArch[2]))) then
                -- Look back
                self.qc = {};
                self.qc.CamIndex = self.camIndex;
                self.qc.CamTime = 250; -- milliseconds
                self.qc.CamSourceRot = {self.cameras[self.camIndex].rotX, rotY};
                self.qc.CamTargetRot = {self.cameras[self.camIndex].origRotX, (self.cameras[self.camIndex].origRotY - math.pi)};
              elseif (quickCamEvent == InputBinding.QuickCamForward or (quickCamEvent == InputBinding.QuickCamForBack and (forwardArch[1] >= rotY or rotY >= forwardArch[2]))) then
                -- Look forward
                self.qc = {};
                self.qc.CamIndex = self.camIndex;
                self.qc.CamTime = 250; -- milliseconds
                
                while ((rotY + math_pi_double) < forwardArch[1]) do rotY = rotY + math_pi_double; end
                while ((rotY - math_pi_double) > forwardArch[2]) do rotY = rotY - math_pi_double; end
                
                self.qc.CamSourceRot = {self.cameras[self.camIndex].rotX, rotY};
                self.qc.CamTargetRot = {self.cameras[self.camIndex].origRotX, self.cameras[self.camIndex].origRotY};
              elseif quickCamEvent == InputBinding.QuickCamLeft 
                  or quickCamEvent == InputBinding.QuickCamRight
                  or quickCamEvent == InputBinding.QuickCamLeft2
                  or quickCamEvent == InputBinding.QuickCamRight2
              then
                local dirY = math_pi_quarter; -- rotate left
                local angleSnap = 45
                if (quickCamEvent == InputBinding.QuickCamRight) then
                    dirY = -math_pi_quarter; -- rotate right
                elseif (quickCamEvent == InputBinding.QuickCamLeft2) then
                    dirY = math_pi_half; -- rotate left
                    angleSnap = 90
                elseif (quickCamEvent == InputBinding.QuickCamRight2) then
                    dirY = -math_pi_half; -- rotate right
                    angleSnap = 90
                end;
                
                self.qc = {};
                self.qc.CamIndex = self.camIndex;
                self.qc.CamTime = 100; -- milliseconds
                self.qc.CamSourceRot = {self.cameras[self.camIndex].rotX, rotY};
                
                ---- Quick-rotate and snap to nearest 45-degree angle.
                rotY = rotY + dirY; -- rotate
                --rotY = Utils.degToRad(45 * math.floor((math.deg(rotY) + 22.5)/45)); -- snap
                rotY = Utils.degToRad(angleSnap * math.floor((math.deg(rotY) + (angleSnap/2))/angleSnap)); -- snap
                
                self.qc.CamTargetRot = {self.cameras[self.camIndex].rotX, rotY};
              end;
            end;
        end;
        -- Detect action-keys for translatable camera
        if self.cameras[self.camIndex].allowTranslation then
            if self.qcTimeZoomOut == nil then
                if InputBinding.isPressed(InputBinding.QuickCamZoomOut) then
                    self.qcTimeZoomOut = g_currentMission.time; -- remember time of key-pressed-down
                end;
            elseif not InputBinding.isPressed(InputBinding.QuickCamZoomOut) then
                -- key-released, now figure out if time was short enough to quick-zoom camera.
                local diffMs = g_currentMission.time - self.qcTimeZoomOut;
                if (diffMs <= QuickCamera.quickRotateKeyTapMaxTimeMs) then
                    self.cameras[self.camIndex]:zoomSmoothly(QuickCamera.quickZoomDistance);
                end;
                
                self.qcTimeZoomOut = nil;
            end;
            --            
            if self.qcTimeZoomIn == nil then
                if InputBinding.isPressed(InputBinding.QuickCamZoomIn) then
                    self.qcTimeZoomIn = g_currentMission.time; -- remember time of key-pressed-down
                end;
            elseif not InputBinding.isPressed(InputBinding.QuickCamZoomIn) then
                -- key-released, now figure out if time was short enough to quick-zoom camera.
                local diffMs = g_currentMission.time - self.qcTimeZoomIn;
                if (diffMs <= QuickCamera.quickRotateKeyTapMaxTimeMs) then
                    self.cameras[self.camIndex]:zoomSmoothly(-QuickCamera.quickZoomDistance);
                end;
                
                self.qcTimeZoomIn = nil;
            end;
        end;
--            
    end;
end;

function QuickCamera.changeToCamera(self, newCameraIndex)
    if self.camIndex ~= newCameraIndex then
        self.cameras[self.camIndex]:onDeactivate();
        self.camIndex = newCameraIndex;
        self.cameras[self.camIndex]:onActivate();
        
        -- FS15, enable/disable mirrors depending on camera's settings.
        if self.setMirrorVisible ~= nil and self.mirrorAvailable == true then
            self:setMirrorVisible(self.cameras[self.camIndex].useMirror == true)
        end;
    end
end

function QuickCamera.onEnter(self, superFunc, isControlling)
    -- Remember camera index before calling original function.
    local camIndex = Utils.clamp(self.camIndex, 1, self.numCameras);
    
    superFunc(self, isControlling)
    
    if isControlling then
      QuickCamera.changeToCamera(self, camIndex); -- Restore camera index
    end
end;


function QuickCamera.resetCamera(self, superFunc)
    if QuickCamera.forceResetCamera then
        superFunc(self);
        QuickCamera.forceResetCamera = QuickCamera.enableAutoResetCamera;
    end;
end;


Steerable.postLoad        = Utils.appendedFunction(Steerable.postLoad, QuickCamera.postLoad);
Steerable.update          = Utils.overwrittenFunction(Steerable.update, QuickCamera.update);
Steerable.onEnter         = Utils.overwrittenFunction(Steerable.onEnter, QuickCamera.onEnter);
VehicleCamera.resetCamera = Utils.overwrittenFunction(VehicleCamera.resetCamera, QuickCamera.resetCamera);

function QuickCamera.loadFromAttributesAndNodes(self, superFunc, xmlFile, key, resetVehicles)
    --
    if not resetVehicles and g_server ~= nil then
    end;
    --
    return superFunc(self, xmlFile, key, resetVehicles);
end;

function QuickCamera.getSaveAttributesAndNodes(self, superFunc, nodeIdent)
    local attributes;
    local nodes;
    attributes, nodes = superFunc(self, nodeIdent);
    --
    if false then
        local customCamerasRotation = nil
        for idx,camera in pairs(self.cameras) do
            if camera.modQuickCamera ~= nil and camera.modQuickCamera.customRot ~= nil then
                customCamerasRotation = Utils.getNoNil(customCamerasRotation, "") .. (' camera%dRot="%f %f %f"'):format(
                    idx,
                    camera.modQuickCamera.customRot.x,
                    camera.modQuickCamera.customRot.y,
                    camera.modQuickCamera.customRot.z
                )
            end
        end
        if customCamerasRotation ~= nil then
            nodes = nodes .. ('<modQuickCamera %s />\n'):format(customCamerasRotation)
        end
    end
    --
    return attributes, nodes;
end;

--Vehicle.loadFromAttributesAndNodes = Utils.overwrittenFunction(Vehicle.loadFromAttributesAndNodes, QuickCamera.loadFromAttributesAndNodes);
--Vehicle.getSaveAttributesAndNodes  = Utils.overwrittenFunction(Vehicle.getSaveAttributesAndNodes,  QuickCamera.getSaveAttributesAndNodes);



print(string.format("Script loaded: QuickCamera.lua (v%s)", QuickCamera.version));
