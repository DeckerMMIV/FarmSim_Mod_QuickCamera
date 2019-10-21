--
-- RestoreCameraSettingOnGameLoad for FS19
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
-- @date    2019-08-xx
--

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

local qcTemplateVehicleCamerasSettings = {}

local modsSettingsFolder = getUserProfileAppPath() .. "modsSettings/"
local qcFileName = Utils.getFilename("QuickCamera_Settings.xml",  modsSettingsFolder)

local function onGameStartup()
  if fileExists(qcFileName) then
    local xmlFile = loadXMLFile("QuickCamera", qcFileName, "quickCamera")
    if nil ~= xmlFile then
      print(("QuickCamera loading settings from: %s"):format(qcFileName))
      local i = 0
      while true do
        local key = ("quickCamera.templates.vehicle(%d)"):format(i)
        i=i+1
        if not hasXMLProperty(xmlFile, key) then
          break
        end
        local vehicleFileName = getXMLString(xmlFile, key .. "#name")
        local qcCamPos        = getXMLString(xmlFile, key .. "#qcCamPos")
        local qcActiveCam     = getXMLInt(   xmlFile, key .. "#qcActiveCam")
        if nil ~= vehicleFileName then
          qcTemplateVehicleCamerasSettings[vehicleFileName] = {
            qcActiveCam = qcActiveCam,
            qcCamPos    = qcCamPos
          }
        end
      end
      delete(xmlFile)
    end
  end
end

local function onGameTeardown()
  print(("QuickCamera saving settings to: %s"):format(qcFileName))
  createFolder(modsSettingsFolder)
  local xmlFile = createXMLFile("QuickCamera", qcFileName, "quickCamera")
  if nil ~= xmlFile then
    local i = 0
    for k,v in pairs(qcTemplateVehicleCamerasSettings) do
      local key = ("quickCamera.templates.vehicle(%d)"):format(i)
      i=i+1
      setXMLString(xmlFile, key .. "#name", k)
      setXMLString(xmlFile, key .. "#qcCamPos", v.qcCamPos)
      setXMLInt(   xmlFile, key .. "#qcActiveCam", v.qcActiveCam)
    end
    saveXMLFile(xmlFile)
    delete(xmlFile)
  end
end

if nil ~= g_client then
  --log("QuickCamera injecting")
  Mission00.load       = Utils.appendedFunction(Mission00.load, onGameStartup)
  FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, onGameTeardown)
end

----

local function getQcCamPos(spec)
  local camerasPositions = {}
  for i=1, table.getn(spec.cameras) do
    local camera = spec.cameras[i]
    if camera.isRotatable or camera.allowTranslation then
      local pitch = (camera.isRotatable      and (("%.3f"):format(camera.rotX))) or ""
      local zoom  = (camera.allowTranslation and (("%.3f"):format(camera.zoom))) or ""
      local camPos = ("%d,%s,%s"):format(i, pitch, zoom)
      table.insert(camerasPositions, camPos)
    end
  end
  return table.concat(camerasPositions, ";")
end

----

Enterable.registerEventListeners = Utils.appendedFunction(Enterable.registerEventListeners, function(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Enterable)
end)

Enterable.onPostLoad = Utils.appendedFunction(Enterable.onPostLoad, function(self, savegame)
  if not self.isClient then
    return
  end

  local spec = self.spec_enterable
  local qcCamPos = nil
  local qcActiveCam = nil

  if nil ~= savegame then
    -- Try get settings for singleplayer/savegame individual vehicles
    local key = savegame.key..".enterable"
    qcCamPos    = getXMLString(savegame.xmlFile, key.."#qcCamPos")
    qcActiveCam = getXMLInt(   savegame.xmlFile, key.."#qcActiveCam")
  end

  if (nil == qcCamPos or nil == qcActiveCam) and (nil ~= self.configFileName) then
    -- Try get settings from template-vehicle
    local template = qcTemplateVehicleCamerasSettings[self.configFileName]
    if nil ~= template then
      if nil == qcCamPos then
        qcCamPos    = template.qcCamPos
      end
      if nil == qcActiveCam then
        qcActiveCam = template.qcActiveCam
      end
    end
  end

  if nil ~= qcCamPos then
    local cams = StringUtil.splitString(";", qcCamPos)
    for _,camPos in pairs(cams) do
      local camPosParts = StringUtil.splitString(",", camPos)
      if 3 == table.getn(camPosParts) then
        local camIndex = tonumber(camPosParts[1])
        local pitch    = tonumber(camPosParts[2])
        local zoom     = tonumber(camPosParts[3])
        if nil ~= camIndex and camIndex >= 1 and camIndex <= table.getn(spec.cameras) then
          local camera = spec.cameras[camIndex]
          if nil ~= camera then
            if nil ~= pitch then
              camera.rotX = pitch
            end
            if nil ~= zoom then
              camera.zoomTarget = zoom
            end
          end
        end
      end
    end
  end

  if nil ~= qcActiveCam and qcActiveCam >= 1 and qcActiveCam <= table.getn(spec.cameras) then
    spec.camIndex = qcActiveCam
  end
end)

Enterable.saveToXMLFile = Utils.appendedFunction(Enterable.saveToXMLFile, function(self, xmlFile, key, usedModNames)
  if not self.isClient then
    return
  end

  local spec = self.spec_enterable
  local qcCamPos = getQcCamPos(spec)
  setXMLString(xmlFile, key.."#qcCamPos", qcCamPos)
  setXMLInt(   xmlFile, key.."#qcActiveCam", spec.camIndex)
end)

Enterable.leaveVehicle = Utils.prependedFunction(Enterable.leaveVehicle, function(self)
  if self.isClient and nil ~= self.configFileName then
    local spec = self.spec_enterable
    local template = {
      qcActiveCam = spec.camIndex,
      qcCamPos    = getQcCamPos(spec)
    }
    qcTemplateVehicleCamerasSettings[self.configFileName] = template
  end
end)

----

print(("Script loaded: RestoreCameraSettingOnGameLoad.lua - from %s (v%s)"):format(g_currentModName, g_modManager:getModByName(g_currentModName).version));
