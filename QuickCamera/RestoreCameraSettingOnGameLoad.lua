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

Enterable.registerEventListeners = Utils.appendedFunction(Enterable.registerEventListeners, function(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Enterable)
end)

Enterable.onPostLoad = Utils.appendedFunction(Enterable.onPostLoad, function(self, savegame)
  local spec = self.spec_enterable
  local qcCamPos = nil
  local qcActiveCam = nil
  if nil ~= savegame then
    qcCamPos    = getXMLString(savegame.xmlFile, savegame.key..".enterable#qcCamPos")
    qcActiveCam = getXMLInt(savegame.xmlFile, savegame.key..".enterable#qcActiveCam")
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
  local spec = self.spec_enterable
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
  local qcCamPos = table.concat(camerasPositions, ";")
  setXMLString(xmlFile, key.."#qcCamPos", qcCamPos)
  setXMLInt(xmlFile, key.."#qcActiveCam", spec.camIndex)
end)

----

print(("Script loaded: RestoreCameraSettingOnGameLoad.lua - from %s (v%s)"):format(g_currentModName, g_modManager:getModByName(g_currentModName).version));
