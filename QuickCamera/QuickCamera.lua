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
-- @history
--      v0.9(beta)  - Public version.
--      v0.91(beta) - Added custom input-bindings; QuickCam...
--      v0.92(beta) - Removed testing for analog input-axis, as it apparently causes problems
--                    using gamepads where look left/right is assigned to analog-stick. (Thank you Napalm)
--                  - Not using axis-bindings; AXIS_LOOK_UPDOWN_VEHICLE and AXIS_LOOK_LEFTRIGHT_VEHICLE.
--                    Instead provided new custom ones only for QuickCam, that must be assigned in Options->Control
--      v0.93(beta) - Added "smooth/progressive" quick-rotation, though there's still a bug where it will revolve 181+ degrees,
--                    instead of just negative 179+ degrees. Its some math that I havent quite figured out how to solve.
--  2012-November
--      v0.94       - Converted to FS2013
--                  - Removed digital-axis tests, as they were not used anyway (well I was not using them).
--  2013-June
--      v0.95       - Disabled the normal reset of camera position, when switching camera.
--                  - To reset camera, press-and-hold the CAMERA_SWITCH action-key.
--  2013-July
--      v0.96       - Remember last selected camera for vehicle.
--                  - Added option to enable/disable the "Reset of camera position". (default key LEFT ALT K)
--  2013-October
--      v0.97       - Fix for not being able to 'look back', in some mod-vehicles due to they had a "rotated camera".
--  2013-November
--      v0.98       - Ability to toggle useWorldXZRotation for selected camera.
--

--[[
Suggestions
-----------

Wrongway
    An option to glance left or right returning to forward view would be very useful, but might not be easy to implement. 
    http://www.ls-uk.info/forum/index.php?topic=118579.msg789306#msg789306
 
]]

QuickCamera = {};
--
local modItem = ModsUtil.findModItemByModName(g_currentModName);
QuickCamera.version = (modItem and modItem.version) and modItem.version or "?.?.?";
--
-- Default values, can be changed in-game using console commands.
QuickCamera.quickRotateKeyTapMaxTimeMs  = 150;
QuickCamera.quickZoomDistance           = 20;
--
QuickCamera.forceResetCamera = false;
QuickCamera.enableAutoResetCamera = false;
QuickCamera.useWorldXZRotation = false;

function QuickCamera:consoleCommandSetQuickRotateKeyTapMs(newTimeMs)
    if newTimeMs ~= nil then
        QuickCamera.quickRotateKeyTapMaxTimeMs = tonumber(newTimeMs);
    end;
    return "modQuickCameraRotateKeyTapMs = "..tostring(QuickCamera.quickRotateKeyTapMaxTimeMs);
end;
addConsoleCommand("modQuickCameraRotateKeyTapMs", "QuickCamera rotate key-tap max milliseconds.", "consoleCommandSetQuickRotateKeyTapMs", QuickCamera);

function QuickCamera:consoleCommandSetQuickZoomDistance(newDistance)
    if newDistance ~= nil then
        QuickCamera.quickZoomDistance = tonumber(newDistance);
    end;
    return "modQuickCameraZoomDistance = "..tostring(QuickCamera.quickZoomDistance);
end;
addConsoleCommand("modQuickCameraZoomDistance", "QuickCamera max zoom distance for key-tap.", "consoleCommandSetQuickZoomDistance", QuickCamera);


--function vec2str(v)
--    return string.format("%s,%s", tostring(v[1]), tostring(v[2]));
--end;

function QuickCamera.update(self, superFunc, dt)
    -- TRICK: Do not allow Steerable:update() to switch camera. 
    -- This could break other mods that tests against InputBinding.CAMERA_SWITCH, but I know of none yet.
    InputBinding.actions[InputBinding.CAMERA_SWITCH].hasEvent = false;
    
    -- Execute the normal Steerable:update()
    superFunc(self, dt);

    -- The CAMERA_SWITCH now has two actions; 
    --      press-and-release(less than 500ms) -> switch camera
    --      press-and-hold(more than 500ms)    -> reset current camera
    if InputBinding.isPressed(InputBinding.CAMERA_SWITCH) then
        if self.isEntered and self.isClient and self:getIsActiveForInput(false) then
            if self.qcPressKeyTime == nil then
                -- Press-key begun
                self.qcPressKeyTime = g_currentMission.time;
            elseif (g_currentMission.time - self.qcPressKeyTime) > 500 then
                -- Press-and-hold -> Reset current camera
                self.qcPressKeyTime = g_currentMission.time + 1000*60*60*24; -- 24 hours.
                QuickCamera.forceResetCamera = true;
                self.cameras[self.camIndex]:resetCamera();
                --
                --print("Toggles 'useWorldXZRotation' on cameras for vehicle.")
                --for _,cam in pairs(self.cameras) do
                --    cam.useWorldXZRotation = not cam.useWorldXZRotation;
                --end
                self.cameras[self.camIndex].useWorldXZRotation = not self.cameras[self.camIndex].useWorldXZRotation;
                print("Toggled 'useWorldXZRotation' to: "..tostring(self.cameras[self.camIndex].useWorldXZRotation))
            end
        else
            -- Player not in vehicle, or not active for input.
            self.qcPressKeyTime = nil;
        end
    elseif self.qcPressKeyTime ~= nil then
        local keyDelay = g_currentMission.time - self.qcPressKeyTime;
        self.qcPressKeyTime = nil;
        if keyDelay > 0 and keyDelay < 500 then
            -- Press-and-release -> Switch to next camera
            self.cameras[self.camIndex]:onDeactivate();
            self.camIndex = (self.camIndex % self.numCameras) + 1;
            self.cameras[self.camIndex]:onActivate();
        end
    end

    -- QuickCamera actions...
    if self.isEntered and self:getIsActive() then
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
--[[
                else
                    local inputW = InputBinding.getDigitalInputAxis(InputBinding.QuickCamAxisUpDown);
                    if InputBinding.isAxisZero(inputW) then
                        inputW = InputBinding.getAnalogInputAxis(InputBinding.QuickCamAxisUpDown);
                    end;
                    if self.qcQuickAxisUpDownType == nil then
                        --if not InputBinding.isAxisZero(inputW) then
                        if inputW > 0.5 or inputW < -0.5 then
--print("QuickCamAxisUpDown="..tostring(inputW));
                            self.qcPressedTime = g_currentMission.time; -- remember time of key-pressed-down
                            -- remember direction
                            if (inputW < 0) then
                                self.qcQuickAxisUpDownType = InputBinding.QuickCamForward;
                            else
                                self.qcQuickAxisUpDownType = InputBinding.QuickCamBackward;
                            end;
                        end;
                    elseif InputBinding.isAxisZero(inputW) then
                        -- key-released, now figure out if time was short enough.
                        if ((g_currentMission.time - self.qcPressedTime) <= QuickCamera.quickRotateKeyTapMaxTimeMs) then
                            quickCamEvent = self.qcQuickAxisUpDownType;
                        end;
                        self.qcQuickAxisUpDownType = nil;
                    end;
                    --
                    local inputZ = InputBinding.getDigitalInputAxis(InputBinding.QuickCamAxisLeftRight);
                    if InputBinding.isAxisZero(inputZ) then
                        inputZ = InputBinding.getAnalogInputAxis(InputBinding.QuickCamAxisLeftRight);
                    end;
                    if self.qcQuickAxisLeftRightType == nil then
                        --if not InputBinding.isAxisZero(inputZ) then
                        if inputZ > 0.5 or inputZ < -0.5 then
--print("QuickCamAxisLeftRight="..tostring(inputZ));
                            self.qcPressedTime = g_currentMission.time; -- remember time of key-pressed-down
                            -- remember direction
                            if (inputZ < 0) then
                                self.qcQuickAxisLeftRightType = InputBinding.QuickCamLeft;
                            else
                                self.qcQuickAxisLeftRightType = InputBinding.QuickCamRight;
                            end;
                        end;
                    elseif InputBinding.isAxisZero(inputZ) then
                        -- key-released, now figure out if time was short enough to quick-rotate camera.
                        if ((g_currentMission.time - self.qcPressedTime) <= QuickCamera.quickRotateKeyTapMaxTimeMs) then
                            quickCamEvent = self.qcQuickAxisLeftRightType;
                        end;
                        self.qcQuickAxisLeftRightType = nil;
                    end;
--]]
                end; 
            end;
            --
            if quickCamEvent ~= nil then
--print("QuickCamEvent="..tostring(quickCamEvent));
              --
              local forwardArch = { self.cameras[self.camIndex].origRotY - math.pi/2, self.cameras[self.camIndex].origRotY + math.pi/2 }
              --
              local rotY = self.cameras[self.camIndex].rotY;
              while (rotY < -math.pi*2) do rotY = rotY + math.pi*2; end
              while (rotY >  math.pi*2) do rotY = rotY - math.pi*2; end
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
                self.qc.CamSourceRot = {self.cameras[self.camIndex].rotX, rotY};
                self.qc.CamTargetRot = {self.cameras[self.camIndex].origRotX, self.cameras[self.camIndex].origRotY};
              elseif (quickCamEvent == InputBinding.QuickCamLeft or quickCamEvent == InputBinding.QuickCamRight) then
                local dirY = math.pi/4; -- rotate left
                if (quickCamEvent == InputBinding.QuickCamRight) then
                    dirY = -math.pi/4; -- rotate right
                end;
                
                self.qc = {};
                self.qc.CamIndex = self.camIndex;
                self.qc.CamTime = 100; -- milliseconds
                self.qc.CamSourceRot = {self.cameras[self.camIndex].rotX, rotY};
                
                ---- Quick-rotate and snap to nearest 45-degree angle.
                rotY = rotY + dirY; -- rotate
                rotY = Utils.degToRad(45 * math.floor((math.deg(rotY) + 22.5)/45)); -- snap
                
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
Steerable.update = Utils.overwrittenFunction(Steerable.update, QuickCamera.update);

-- Copied directly from (patch 1.4) Steerable:onEnter(), just to prohibit self.camIndex being set to 1.
function QuickCamera.onEnter(self, superFunc, isControlling)
    self.isControlled = true;
    if isControlling then
        self.isEntered = true;

-- Remember last selected camera! Do not switch to camera #1 every time.
        --self.camIndex = 1;
        self.camIndex = Utils.clamp(self.camIndex, 1, self.numCameras);
--        
        self.cameras[self.camIndex]:onActivate();
    end;

    self:startMotor(true);
    self:onActivateAttachments();
    if self.characterNode ~= nil then
        setVisibility(self.characterNode, true);
    end;
    g_currentMission.controlledVehicles[self] = self;
end;
Steerable.onEnter = Utils.overwrittenFunction(Steerable.onEnter, QuickCamera.onEnter);

--
function QuickCamera.resetCamera(self, superFunc)
    if QuickCamera.forceResetCamera then
        superFunc(self);
        QuickCamera.forceResetCamera = QuickCamera.enableAutoResetCamera;
    end;
end;
VehicleCamera.resetCamera = Utils.overwrittenFunction(VehicleCamera.resetCamera, QuickCamera.resetCamera);


print(string.format("Script loaded: QuickCamera.lua (v%s)", QuickCamera.version));
