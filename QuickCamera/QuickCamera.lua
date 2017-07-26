--
-- QuickCamera
--
-- @author  Decker_MMIV (DCK)
-- @contact fs-uk.com, modcentral.co.uk, forum.farming-simulator.com
-- @date    2016-11-xx
--
-- @notes
--          A special "thank you" to Templaer and his 'Camera' mod, from which I got inspiration to make this QuickCamera mod.
--

--[[
Suggestions
-----------

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
QuickCamera.quickZoomDistance           = 12.5;
--[[
QuickCamera.panCamera_enabled = false
QuickCamera.panCamera_factor  = 0.6
--
QuickCamera.forceResetCamera = false;
QuickCamera.enableAutoResetCamera = false;
QuickCamera.useWorldXZRotation = false;
--]]
local math_pi_double  = math.pi*2
local math_pi_half    = math.pi/2
local math_pi_quarter = math.pi/4
local math_pi_six     = math_pi_quarter + math_pi_quarter/2


--[[
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
--]]

function QuickCamera.update(self, dt)
    if not (self.isEntered and self.isClient and (not g_currentMission.isPlayerFrozen) and not g_gui:getIsGuiVisible()) then
        -- Player not in vehicle, or not active for input.
        self.qcPressKeyTime = nil;
    else
        -- Smooth'ish rotation
        if self.qc ~= nil then
            if self.qc.CamIndex == self.camIndex then
                if self.qc.accTime ~= nil then
                    self.qc.accTime = self.qc.accTime + dt;
                else
                    self.qc.accTime = 0;
                end;
                local newCamRot = Utils.getMovedLimitedValues(self.qc.CamSourceRot, self.qc.CamSourceRot, self.qc.CamTargetRot, 2, self.qc.CamTime, self.qc.accTime, true);
--print(string.format("%3d; sourceRot=%s; targetRot=%s; newCamRot=%s", self.qc.accTime, vec2str(self.qc.CamSourceRot), vec2str(self.qc.CamTargetRot), vec2str(newCamRot)));
                self.cameras[self.camIndex].rotX = newCamRot[1];
                self.cameras[self.camIndex].rotY = newCamRot[2];
                --
                if self.qc.peekFrom == nil and self.qc.accTime >= self.qc.CamTime then
                    self.qc = nil;
                end;
            else
                self.qc = nil;
            end;
        end;
        -- Detect action-keys for rotatable camera
        if self.cameras[self.camIndex].isRotatable then
--[[
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
--]]
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
              -- If reverse driving, then reverse looking forward/backward
              if self.reverserDirection == -1 and not self.cameras[self.camIndex].isInside then
                if     quickCamEvent == InputBinding.QuickCamForward  then quickCamEvent = InputBinding.QuickCamBackward
                elseif quickCamEvent == InputBinding.QuickCamBackward then quickCamEvent = InputBinding.QuickCamForward
                end
              end

              local forwardArch = { self.cameras[self.camIndex].origRotY - math_pi_half, self.cameras[self.camIndex].origRotY + math_pi_half }

              local rotY = self.cameras[self.camIndex].rotY;
              while (rotY < -math_pi_double) do rotY = rotY + math_pi_double; end
              while (rotY >  math_pi_double) do rotY = rotY - math_pi_double; end

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

                if (rotY > self.cameras[self.camIndex].origRotY + math.pi) then
                    rotY = rotY - math_pi_double
                end
                if (rotY < self.cameras[self.camIndex].origRotY - math.pi) then
                    rotY = rotY + math_pi_double
                end
                
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
                rotY = Utils.degToRad(angleSnap * math.floor((math.deg(rotY) + (angleSnap/2))/angleSnap)); -- snap

                self.qc.CamTargetRot = {self.cameras[self.camIndex].rotX, rotY};
              end;
            else
                if self.qc == nil then
                    local dirY = nil
                    if     InputBinding.isPressed(InputBinding.QuickCamPeekRight) then
                        dirY = -math_pi_six
                    elseif InputBinding.isPressed(InputBinding.QuickCamPeekLeft)  then
                        dirY = math_pi_six
                    end
                    if dirY ~= nil then
                        local rotY = self.cameras[self.camIndex].rotY;
                        while (rotY < -math_pi_double) do rotY = rotY + math_pi_double; end
                        while (rotY >  math_pi_double) do rotY = rotY - math_pi_double; end

                        self.qc = {};
                        self.qc.peekFrom = {self.cameras[self.camIndex].rotX, rotY}
                        self.qc.CamIndex = self.camIndex;
                        self.qc.CamTime = 100; -- milliseconds
                        self.qc.CamSourceRot = {self.cameras[self.camIndex].rotX, rotY};

                        rotY = rotY + dirY; -- rotate
                        self.qc.CamTargetRot = {self.cameras[self.camIndex].rotX, rotY};
                    end
                elseif self.qc.peekFrom ~= nil then
                    if  not InputBinding.isPressed(InputBinding.QuickCamPeekRight)
                    and not InputBinding.isPressed(InputBinding.QuickCamPeekLeft)
                    then
                        self.qc.accTime = 0
                        local camera = self.cameras[self.camIndex];
                        self.qc.CamSourceRot = { camera.rotX, camera.rotY }
                        self.qc.CamTargetRot = { self.qc.peekFrom[1], self.qc.peekFrom[2] }
                        self.qc.peekFrom = nil
                    end
                end
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

    end;
end;
Steerable.update = Utils.appendedFunction(Steerable.update, QuickCamera.update);

---------

function QuickCamera.player_update(self, dt)
    if self.isEntered and self.isClient
    and not self.walkingIsLocked and not self.walkingIsLocked
    and not g_currentMission.isPlayerFrozen and not g_gui:getIsGuiVisible()
    then
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
            if     InputBinding.hasEvent(InputBinding.QuickCamOnFootForBack)  then quickCamEvent       = InputBinding.QuickCamOnFootForBack;
            elseif InputBinding.hasEvent(InputBinding.QuickCamOnFootLeft)     then self.qcQuickTapType = InputBinding.QuickCamOnFootLeft;       self.qcPressedTime = g_currentMission.time;
            elseif InputBinding.hasEvent(InputBinding.QuickCamOnFootRight)    then self.qcQuickTapType = InputBinding.QuickCamOnFootRight;      self.qcPressedTime = g_currentMission.time;
            end;
        end

        if quickCamEvent ~= nil then
            if quickCamEvent == InputBinding.QuickCamOnFootForBack then
                self.rotY = self.rotY + math.pi
            elseif quickCamEvent == InputBinding.QuickCamOnFootLeft then
                self.rotY = self.rotY + math_pi_quarter
            elseif quickCamEvent == InputBinding.QuickCamOnFootRight then
                self.rotY = self.rotY - math_pi_quarter
            end
        end
    end;
end
Player.update = Utils.appendedFunction(Player.update, QuickCamera.player_update);


print(string.format("Script loaded: QuickCamera.lua (v%s)", QuickCamera.version));
