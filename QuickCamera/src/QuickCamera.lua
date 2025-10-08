--
-- QuickCamera for FS25
--
-- @author  Decker_MMIV (DCK)
-- @contact forum.farming-simulator.com
-- @date    2024-11-xx
--

if not g_dedicatedServerInfo then

QuickCamera = {}

QuickCamera.quickTapThresholdMS = 300 -- Milliseconds. Below = quick-tap. Above = long-hold
QuickCamera.quickZoomFactorUnit = 15
QuickCamera.playerRunSpeedFactorMax = 23

-- For debugging
local qcLogging_enabled = false

function qcLog(...)
  if qcLogging_enabled then
    local txt = ""
    for idx = 1,select("#", ...) do
      txt = txt .. tostring(select(idx, ...))
    end
    print(string.format("[QuickCamera] %7ums ", g_time) .. txt)
  end
end

--
local modDirectory = g_currentModDirectory

source(modDirectory .. "src/QuickCameraVehicle.lua")
source(modDirectory .. "src/QuickCameraPlayer.lua")
source(modDirectory .. "src/OneButtonDirectionChangeAndFlipCamera.lua")


-- Delay the injection of VehicleCamera.update, so other mods can "get there first", whereafter QuickCamera can prepend its code to VehicleCamera.update.
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
    QuickCamera.quickTapThresholdMS = math.clamp(newMilliseconds, 100, 499)
  end
  print(("[QuickCamera] Key-tap threshold milliseconds (100..499): %.f"):format(QuickCamera.quickTapThresholdMS))
end

function QuickCamera:consoleCommandDebug(arg)
  if nil ~= arg then
    arg = string.lower(arg)
    if arg == "false" or arg == "0" then
      qcLogging_enabled = false
      print("[QuickCamera] Debug logging disabled.")
      return
    end
    if arg == "true" or arg == "1" then
      qcLogging_enabled = true
      print("[QuickCamera] Debug logging enabled.")
      return
    end
    print("[QuickCamera] Debug unknown argument.")
    return
  else
    qcLogging_enabled = true
    print("[QuickCamera] Debug logging enabled. - Use console-command 'modQuickCameraDebug false' to revert this setting.")
  end
end

addConsoleCommand("modQuickCameraKeyTapThresholdMS", "", "consoleCommandKeyTapThresholdMS", QuickCamera)
addConsoleCommand("modQuickCameraDebug",             "", "consoleCommandDebug",             QuickCamera)

--
qcLog("Script loaded: QuickCamera.lua - from ",g_currentModName," (v",g_modManager:getModByName(g_currentModName).version,")")

end -- not g_dedicatedServerInfo
