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