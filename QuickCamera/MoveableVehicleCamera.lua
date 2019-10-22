--
-- MoveableVehicleCamera for FS19
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
-- @date    2019-04-xx
--

if not g_dedicatedServerInfo then

-- For debugging
local function log(...)
  if true then
      local txt = ""
      for idx = 1,select("#", ...) do
          txt = txt .. tostring(select(idx, ...))
      end
      print(string.format("%7ums ", g_time) .. txt);
  end
end;

----

MoveableVehicleCameraEnabler = {}

function MoveableVehicleCameraEnabler.prerequisitesPresent(specializations)
  return  true  == SpecializationUtil.hasSpecialization(Enterable     ,specializations)
      and true  == SpecializationUtil.hasSpecialization(AIVehicle     ,specializations)
      and false == SpecializationUtil.hasSpecialization(ConveyorBelt  ,specializations)
    --and false == SpecializationUtil.hasSpecialization(Locomotive    ,specializations)
end

function MoveableVehicleCameraEnabler.registerEventListeners(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onAIStart", MoveableVehicleCameraEnabler)
  SpecializationUtil.registerEventListener(vehicleType, "onAIEnd",   MoveableVehicleCameraEnabler)
end

function MoveableVehicleCameraEnabler:onAIStart()
  local rootAttacherVehicle = self:getRootVehicle()
  if rootAttacherVehicle ~= nil then
    if rootAttacherVehicle.addToolCameras ~= nil then
      if nil == self.modMoveableCamera then
        self.modMoveableCamera = MoveableVehicleCamera:new(self)
        self.modMoveableCamera:initialize()
      end
      rootAttacherVehicle:addToolCameras({self.modMoveableCamera})
    end
  end
end

function MoveableVehicleCameraEnabler:onAIEnd()
  local rootAttacherVehicle = self:getRootVehicle()
  if rootAttacherVehicle ~= nil then
    if rootAttacherVehicle.addToolCameras ~= nil then
      rootAttacherVehicle:removeToolCameras({self.modMoveableCamera})
    end
  end
end

----

MoveableVehicleCamera = {}

local MoveableVehicleCamera_mt = Class(MoveableVehicleCamera, VehicleCamera);

function MoveableVehicleCamera:new(vehicle, customMt)
  local instance = {}
  if customMt ~= nil then
      setmetatable(instance, customMt)
  else
      setmetatable(instance, MoveableVehicleCamera_mt)
  end
  instance.vehicle = vehicle
  instance.isActivated = false
  instance.limitRotXDelta = 0
  instance.raycastDistance = 0
  instance.normalX = 0
  instance.normalY = 0
  instance.normalZ = 0
  instance.raycastNodes = {}
  instance.disableCollisionTime = -1
  instance.lookAtPosition = {0,0,0}
  instance.lookAtLastTargetPosition = {0,0,0}
  instance.position = {0,0,0}
  instance.lastTargetPosition = {0,0,0}
  instance.lastInputValues = {}
  instance.lastInputValues.upDown = 0
  instance.lastInputValues.leftRight = 0

  instance.lastInputMoves = {}
  instance.lastInputMoves.upDown = 0
  instance.lastInputMoves.leftRight = 0
  instance.lastInputMoves.forwardBack = 0
  instance.lastInputMoves.mouseWheel = 0

  instance.isCollisionEnabled = not g_modIsLoaded["FS19_disableVehicleCameraCollision"]
  return instance
end

function MoveableVehicleCamera:delete()
  delete(self.cameraNode)
  self.cameraNode = nil
  setShadowFocusBox(0)
end

function MoveableVehicleCamera:initialize()
  self.zoom = 1
  self.zoomTarget = 1
  self.zoomLimitedTarget = -1
  self.transMin = nil
  self.transMax = nil

  self.cameraNode = createCamera("cameraFreeMoveable", math.rad(70), 0.1, 5000)
  link(self.vehicle.components[1].node, self.cameraNode)

  self.fovY = calculateFovY(self.cameraNode)
  setFovY(self.cameraNode, self.fovY)

  self.isRotatable = true
  self.limit = false
  self.rotateNode = self.cameraNode
  self.hasExtraRotationNode = false

  self.allowTranslation = false

  self.isInside = false
  self.useOutdoorSounds = true
  self.defaultLowPassGain = 1.0
  self.defaultVolume = 1.0

  self.shadowFocusBoxNode = nil

  self.rotYSteeringRotSpeed = nil
  self.useMirror = false
  self.useWorldXZRotation = false
  self.allowHeadTracking = false
  self.resetCameraOnVehicleSwitch = false

  self.positionSmoothingParameter = 0
  self.lookAtSmoothingParameter = 0

  self.cameraPositionNode = self.cameraNode


  self.origRotX, self.origRotY, self.origRotZ = getRotation(self.rotateNode)
  self.rotX = self.origRotX
  self.rotY = self.origRotY
  self.rotZ = self.origRotZ

  self.origTransX, self.origTransY, self.origTransZ = getTranslation(self.cameraPositionNode)
  self.transX = self.origTransX
  self.transY = self.origTransY
  self.transZ = self.origTransZ

  self.transDirX = 0
  self.transDirY = 5
  self.transDirZ = 0
end

function MoveableVehicleCamera:onActivate()
  VehicleCamera.onActivate(self)

  self.lastInputMoves.run = 0
  self.lastInputMoves.upDown = 0
  self.lastInputMoves.leftRight = 0
  self.lastInputMoves.forwardBack = 0
  self.lastInputMoves.mouseWheel = 0

  local dummy, actionEventId
  dummy, actionEventId = g_inputBinding:registerActionEvent(InputAction.QuickCamMoveUpDown,      self, MoveableVehicleCamera.actionEventMoveUpDown,      false, false, true,  true, nil); g_inputBinding:setActionEventTextVisibility(actionEventId, false)
  dummy, actionEventId = g_inputBinding:registerActionEvent(InputAction.QuickCamMoveLeftRight,   self, MoveableVehicleCamera.actionEventMoveLeftRight,   false, false, true,  true, nil); g_inputBinding:setActionEventTextVisibility(actionEventId, false)
  dummy, actionEventId = g_inputBinding:registerActionEvent(InputAction.QuickCamMoveForwardBack, self, MoveableVehicleCamera.actionEventMoveForwardBack, false, false, true,  true, nil); g_inputBinding:setActionEventTextVisibility(actionEventId, false)
  dummy, actionEventId = g_inputBinding:registerActionEvent(InputAction.AXIS_RUN,                self, MoveableVehicleCamera.actionEventMoveRun,         true,  true,  false, true, nil); g_inputBinding:setActionEventTextVisibility(actionEventId, false)
  -- dummy, actionEventId = g_inputBinding:registerActionEvent(InputAction.CAMERA_ZOOM_IN,          self, MoveableVehicleCamera.actionEventCameraFov,       true,  false, false, true,   1); g_inputBinding:setActionEventTextVisibility(actionEventId, false)
  -- dummy, actionEventId = g_inputBinding:registerActionEvent(InputAction.CAMERA_ZOOM_OUT,         self, MoveableVehicleCamera.actionEventCameraFov,       true,  false, false, true,  -1); g_inputBinding:setActionEventTextVisibility(actionEventId, false)
end

-- function MoveableVehicleCamera:mouseEvent(posX, posY, isDown, isUp, button)
--   log("MoveableVehicleCamera:mouseEvent(",posX,",",posY,",",isDown,",",isUp,",",button,")")
--   if isDown then
--     if button == Input.MOUSE_BUTTON_WHEEL_UP then
--       self.lastInputMoves.mouseWheel = self.lastInputMoves.mouseWheel + 1
--     elseif button == Input.MOUSE_BUTTON_WHEEL_DOWN then
--       self.lastInputMoves.mouseWheel = self.lastInputMoves.mouseWheel + -1
--     end
--   end
-- end

function MoveableVehicleCamera:actionEventCameraFov(actionName, inputValue, callbackState, isAnalog, isMouse)
  self.lastInputMoves.mouseWheel = self.lastInputMoves.mouseWheel + callbackState
end

function MoveableVehicleCamera:actionEventMoveRun(actionName, inputValue, callbackState, isAnalog, isMouse)
  self.lastInputMoves.run = inputValue
end

function MoveableVehicleCamera:actionEventMoveForwardBack(actionName, inputValue, callbackState, isAnalog, isMouse)
  inputValue = inputValue * 0.001 * (isMouse and 16.666 or g_currentDt)
  self.lastInputMoves.forwardBack = self.lastInputMoves.forwardBack + inputValue
end
function MoveableVehicleCamera:actionEventMoveLeftRight(actionName, inputValue, callbackState, isAnalog, isMouse)
  inputValue = inputValue * 0.001 * (isMouse and 16.666 or g_currentDt)
  self.lastInputMoves.leftRight = self.lastInputMoves.leftRight + inputValue
end
function MoveableVehicleCamera:actionEventMoveUpDown(actionName, inputValue, callbackState, isAnalog, isMouse)
  inputValue = inputValue * 0.001 * (isMouse and 16.666 or g_currentDt)
  self.lastInputMoves.upDown = self.lastInputMoves.upDown + inputValue
end


function MoveableVehicleCamera:update(dt)
  local moves = self.lastInputMoves

  if 0 ~= moves.forwardBack
  or 0 ~= moves.upDown
  or 0 ~= moves.leftRight then
    local rx,ry,rz = getRotation(self.cameraNode)

    local dirX = math.sin(ry) * moves.forwardBack + math.cos(ry) * moves.leftRight
    local dirZ = math.cos(ry) * moves.forwardBack - math.sin(ry) * moves.leftRight

    local moveFactor = 4.0
    if self.lastInputMoves.run ~= nil and self.lastInputMoves.run > 0 then
      moveFactor = 0.8
    end

    self.transDirZ = self.transDirZ + dirZ          * moveFactor
    self.transDirY = self.transDirY + moves.upDown  * moveFactor
    self.transDirX = self.transDirX + dirX          * moveFactor
    moves.forwardBack = 0
    moves.upDown      = 0
    moves.leftRight   = 0
  end

  if self.lastInputMoves.mouseWheel ~= 0 then
    if self.lastInputMoves.run ~= nil and self.lastInputMoves.run > 0 then
      self.fovY = self.fovY + math.rad(self.lastInputMoves.mouseWheel)
      self.fovY = MathUtil.clamp(self.fovY, math.rad(10), math.rad(170))
    else
      self.fovY = math.rad(70)
    end
    setFovY(self.cameraNode, self.fovY)
    self.lastInputMoves.mouseWheel = 0
  end

  VehicleCamera.update(self,dt)
end

----

print(("Script loaded: MoveableVehicleCamera.lua - from %s (v%s)"):format(g_currentModName, g_modManager:getModByName(g_currentModName).version));

end -- not g_dedicatedServerInfo