--
-- QuickCamera sub-component: 'Outside camera' rotation-fix for articulated wheelloaders.
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-September
--

Steerable.postLoad = Utils.appendedFunction(Steerable.postLoad, function(self, xmlFile)
    local applyFix = false;

    if self.customEnvironment == "pdlc_jcbPack" then
        if Utils.endsWith(self.configFileName, "/jcbPack/jcb/jcb435s.xml")      -- Wheelloader
        or Utils.endsWith(self.configFileName, "/jcbPack/jcb/jcbTM320s.xml")    -- Telehandler
        then
            applyFix = true
        end
    else
        if Utils.endsWith(self.configFileName, "/steerable/liebherr/liebherrL538.xml")      -- Wheelloader
        then
            applyFix = true
        end
    end

    if applyFix then
        print("Articulated vehicle outside camera rotation-fix applied to: "..self.configFileName);
        for _,camera in pairs(self.cameras) do
            if  true  == camera.isRotatable 
            and false == camera.isInside 
            then
                camera.rotYSteeringRotSpeed = 0.8
            end
        end
    end
end);
