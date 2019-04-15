---- Register this specialization
local specTypeName = 'moveableVehicleCamera'

g_specializationManager:addSpecialization(specTypeName, 'MoveableVehicleCameraEnabler', Utils.getFilename('MoveableVehicleCamera.lua', g_currentModDirectory), true, nil) -- What does the last two arguments even do?

---- Add the specialization to specific vehicle-types
local modSpecTypeName = specTypeName

for vehTypeName,vehTypeObj in pairs( g_vehicleTypeManager.vehicleTypes ) do
  if  true  == SpecializationUtil.hasSpecialization(Enterable     ,vehTypeObj.specializations)
  and true  == SpecializationUtil.hasSpecialization(AIVehicle     ,vehTypeObj.specializations)
  and false == SpecializationUtil.hasSpecialization(ConveyorBelt  ,vehTypeObj.specializations)
--and false == SpecializationUtil.hasSpecialization(Locomotive    ,vehTypeObj.specializations)
  then
    g_vehicleTypeManager:addSpecialization(vehTypeName, modSpecTypeName)
    log("  MoveableVehicleCamera added to: ",vehTypeName)
  end
end
