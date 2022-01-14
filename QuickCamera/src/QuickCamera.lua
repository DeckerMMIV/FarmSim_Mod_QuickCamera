--
-- QuickCamera for FS22
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
-- @date    2021-11-xx
--

if not g_dedicatedServerInfo then

QuickCamera = {}

QuickCamera.quickTapThresholdMS = 150 -- Milliseconds. Below = quick-tap. Above = long-hold
QuickCamera.quickZoomFactorUnit = 15
QuickCamera.playerRunSpeedFactorMax = 15

-- For debugging
--function log(...)
--[[
  local txt = ""
  for idx = 1,select("#", ...) do
    txt = txt .. tostring(select(idx, ...))
  end
  print(string.format("[QuickCamera] %7ums ", g_time) .. txt)
--]]
--end
  
--
local modDirectory = g_currentModDirectory

source(modDirectory .. "src/QuickCameraVehicle.lua")
source(modDirectory .. "src/QuickCameraPlayer.lua")


-- Fix/work-around for #37 - Delay the injection of VehicleCamera.update, so FS22_CabView can "get there first", and then afterwards QuickCamera can prepend its code to VehicleCamera.update.
function QuickCamera:update(dt)
  self.delayCount = (self.delayCount or 0) + 1
  if self.delayCount == 10 then
    delayedInjection_VehicleCamera_Update()

    -- Calling this 'removeModEventListener', when actually called from a for-loop that iterates through the mod-event-listeners array, could cause issues!
    removeModEventListener(QuickCamera)
  end
end
addModEventListener(QuickCamera)

--
function QuickCamera:consoleCommandKeyTapThresholdMS(newMilliseconds)
  newMilliseconds = tonumber(newMilliseconds)
  if nil ~= newMilliseconds then
    QuickCamera.quickTapThresholdMS = MathUtil.clamp(newMilliseconds, 150, 499)
  end
  print(("[QuickCamera] Key-tap threshold milliseconds (150..499): %.f"):format(QuickCamera.quickTapThresholdMS))
end

addConsoleCommand("modQuickCameraKeyTapThresholdMS", "", "consoleCommandKeyTapThresholdMS", QuickCamera)

--print(("Script loaded: QuickCamera.lua - from %s (v%s)"):format(g_currentModName, g_modManager:getModByName(g_currentModName).version));

end -- not g_dedicatedServerInfo