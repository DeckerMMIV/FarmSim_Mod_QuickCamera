--
-- QuickCamera
--      By quick-tap'ing the camera-movement keys, rotation will snap to next nearest 45-degree, and zoom will be faster.
--
-- @author  Decker    (ls-uk.info, Decker_MMIV)
-- @date    2012-January
--
-- @notes
--          A special "thank you" to Templaer and his 'Camera' mod, from which I got inspiration to make this QuickCamera mod.
--
-- @history
--          v0.9(beta)  - Public version.
--          v0.91(beta) - Added custom input-bindings; QuickCam...
--          v0.92(beta) - Removed testing for analog input-axis, as it apparently causes problems
--                        using gamepads where look left/right is assigned to analog-stick. (Thank you Napalm)
--                      - Not using axis-bindings; AXIS_LOOK_UPDOWN_VEHICLE and AXIS_LOOK_LEFTRIGHT_VEHICLE.
--                        Instead provided new custom ones only for QuickCam, that must be assigned in Options->Control
--          v0.93(beta) - Added "smooth/progressive" quick-rotation, though there's still a bug where it will revolve 181+ degrees,
--                        instead of just negative 179+ degrees. Its some math that I havent quite figured out how to solve.
--

--[[
Wrongway
    An option to glance left or right returning to forward view would be very useful, but might not be easy to implement. 
    http://www.ls-uk.info/forum/index.php?topic=118579.msg789306#msg789306
 
]]

QuickCamera = {};
-- Default values, can be changed in-game using console commands.
QuickCamera.quickRotateKeyTapMaxTimeMs  = 150;
QuickCamera.quickZoomDistance           = 20;

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

---
--function vec2str(v)
--    return string.format("%s,%s", tostring(v[1]), tostring(v[2]));
--end;
---
function QuickCamera:update(dt)
    if self:getIsActiveForInput() then
        --
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
        --
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
                else
                    local inputW = InputBinding.getDigitalInputAxis(InputBinding.QuickCamAxisUpDown);
                    --if InputBinding.isAxisZero(inputW) then
                    --    inputW = InputBinding.getAnalogInputAxis(InputBinding.QuickCamAxisUpDown);
                    --end;
                    if self.qcQuickAxisUpDownType == nil then
                        if not InputBinding.isAxisZero(inputW) then
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
                    --if InputBinding.isAxisZero(inputZ) then
                    --    inputZ = InputBinding.getAnalogInputAxis(InputBinding.QuickCamAxisLeftRight);
                    --end;
                    if self.qcQuickAxisLeftRightType == nil then
                        if not InputBinding.isAxisZero(inputZ) then
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
                end; 
            end;
            --
            if quickCamEvent ~= nil then
--print("QuickCamEvent="..tostring(quickCamEvent));
                ---- I'm awful at math, and radians do not make it any better.
              local rotY = math.deg(self.cameras[self.camIndex].rotY); -- convert to degrees
              -- Clamp into -360 to +360 range. There is probably a faster method, but I do not know it.
              while (rotY < -360) do rotY = rotY + 360; end;
              while (rotY >  360) do rotY = rotY - 360; end;
              --
              if (quickCamEvent == InputBinding.QuickCamBackward or (quickCamEvent == InputBinding.QuickCamForBack and ((rotY+90)%360 > 180))) then
                -- Look back
                self.qc = {};
                self.qc.CamIndex = self.camIndex;
                self.qc.CamTime = 250;
                self.qc.CamSourceRot = {self.cameras[self.camIndex].rotX, Utils.degToRad(rotY)};
                self.qc.CamTargetRot = {self.cameras[self.camIndex].origRotX, 0};
              elseif (quickCamEvent == InputBinding.QuickCamForward or (quickCamEvent == InputBinding.QuickCamForBack and ((rotY+90)%360 <= 180))) then
                -- Look forward
                self.qc = {};
                self.qc.CamIndex = self.camIndex;
                self.qc.CamTime = 250;
                self.qc.CamSourceRot = {self.cameras[self.camIndex].rotX, Utils.degToRad(rotY)};
                self.qc.CamTargetRot = {self.cameras[self.camIndex].origRotX, self.cameras[self.camIndex].origRotY};
              elseif (quickCamEvent == InputBinding.QuickCamLeft or quickCamEvent == InputBinding.QuickCamRight) then
                local dirY = 45; -- rotate left
                if (quickCamEvent == InputBinding.QuickCamRight) then
                    dirY = -45; -- rotate right
                end;
                
                self.qc = {};
                self.qc.CamIndex = self.camIndex;
                self.qc.CamTime = 100;
                self.qc.CamSourceRot = {self.cameras[self.camIndex].rotX, Utils.degToRad(rotY)};
                
                ---- Quick-rotate and snap to nearest 45-degree angle.
                rotY = rotY + dirY; -- rotate
                rotY = 45 * math.floor((rotY + 22.5)/45); -- snap
                
                self.qc.CamTargetRot = {self.cameras[self.camIndex].rotX, Utils.degToRad(rotY)};
              --elseif (quickCamEvent == InputBinding.QuickCamRight) then
              --  -- right
              --  self.cameras[self.camIndex].rotY = Utils.degToRad(rotY);
              --  ---- Quick-rotate and snap to nearest 45-degree angle.
              --  ---- I'm awful at math, and radians do not make it any better.
              --  self.qc = {};
              --  self.qc.CamIndex = self.camIndex;
              --  self.qc.CamTime = 100;
              --  self.qc.CamSourceRot = {self.cameras[self.camIndex].rotX, self.cameras[self.camIndex].rotY};
              --
              --  rotY = rotY - 45; -- rotate
              --  rotY = 45 * math.floor((rotY + 22.5)/45); -- snap
              --
              --  self.qc.CamTargetRot = {self.cameras[self.camIndex].rotX, Utils.degToRad(rotY)};
              end;
            end;
        end;
--
        if self.cameras[self.camIndex].allowTranslation then
            if self.qcTimeZoomOut == nil then
                if (InputBinding.isPressed(InputBinding.CAMERA_ZOOM_OUT) and InputBinding.getInputTypeOfDigitalAction(InputBinding.CAMERA_ZOOM_OUT) ~= InputBinding.INPUTTYPE_MOUSE_WHEEL) then
                    self.qcTimeZoomOut = g_currentMission.time; -- remember time of key-pressed-down
                end;
            elseif not InputBinding.isPressed(InputBinding.CAMERA_ZOOM_OUT) then
                -- key-released, now figure out if time was short enough to quick-zoom camera.
                local diffMs = g_currentMission.time - self.qcTimeZoomOut;
                if (diffMs <= QuickCamera.quickRotateKeyTapMaxTimeMs) then
                    self.cameras[self.camIndex]:zoomSmoothly(QuickCamera.quickZoomDistance);
                end;
                
                self.qcTimeZoomOut = nil;
            end;
--            
            if self.qcTimeZoomIn == nil then
                if (InputBinding.isPressed(InputBinding.CAMERA_ZOOM_IN) and InputBinding.getInputTypeOfDigitalAction(InputBinding.CAMERA_ZOOM_IN) ~= InputBinding.INPUTTYPE_MOUSE_WHEEL) then
                    self.qcTimeZoomIn = g_currentMission.time; -- remember time of key-pressed-down
                end;
            elseif not InputBinding.isPressed(InputBinding.CAMERA_ZOOM_IN) then
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

-- 
Steerable.update = Utils.appendedFunction(Steerable.update, QuickCamera.update);

print("Script loaded: QuickCamera.lua (v0.93 beta)");