local parameters = Style.GetParameterValues()
local Length = parameters.Geometry.Length
local PipeDiameter = parameters.Geometry.PipeDiameter
local PipeSpacing = parameters.Geometry.PipeSpacing
local PipeCount = parameters.Geometry.PipeCount
local PlugDiameter = parameters.Geometry.PlugDiameter
local NippleDiameter = parameters.Geometry.NippleDiameter

-- создаем цилиндр и делаем нужное количество копий
function Body()
local cylinder = CreateRightCircularCylinder(PipeDiameter/2, Length):Rotate(CreateYAxis3D(), math.pi/2):Shift(0, 0, PipeDiameter/2) 
local cylinders = {}
for i=0, PipeCount-1 do
  local nextCylinder = cylinder:Clone():Shift(0, 0, PipeSpacing*i) 
  table.insert(cylinders, nextCylinder)
end
local pipe = Unite(cylinders)
return pipe
end


if PipeCount ~= 1 then
    PlugLength = (PipeCount - 1)*PipeSpacing
else PlugLength = 1    
end

function Nipple()
    local cylinder = CreateRightCircularCylinder(NippleDiameter/2, 1.5*NippleDiameter)
    return cylinder
end

local NippleOffset = PipeDiameter + PlugLength - NippleDiameter/2

function Socket()
    local InletNipple
    local AirNipple
    local OutletNipple
    
    
    InletNipple = Nipple():Rotate(CreateYAxis3D(), math.pi/2):Shift(Length, 0, NippleOffset)
    AirNipple = Nipple():Rotate(CreateYAxis3D(), -math.pi/2):Shift(0, 0, NippleOffset)
    OutletNipple = Nipple():Rotate(CreateYAxis3D(), -math.pi/2):Shift(0, 0, NippleDiameter/2)  
    
    UniteSocket = Unite(InletNipple, AirNipple)
    UniteSocket = Unite(UniteSocket, OutletNipple)

    return UniteSocket

end

local Plug1 = CreateRightCircularCylinder(PlugDiameter/2, PlugLength):Shift(Length - PlugDiameter, 0, 0):Shift(0, 0, PipeDiameter/2)
local Plug2 = CreateRightCircularCylinder(PlugDiameter/2, PlugLength):Shift(PlugDiameter, 0, 0):Shift(0, 0, PipeDiameter/2)
local United = Unite(Body(), Plug1)
local United = Unite(United, Plug2)
local United = Unite(United, Socket())

local register = ModelGeometry()
register:AddSolid(United)

Style.SetDetailedGeometry(register)

--Прячем номинальный диаметр
function SetPipeParameters(port, portParameters)
    local connectionType = portParameters.ConnectionType
    if connectionType == PipeConnectorType.Thread then
        port:SetPipeParameters(connectionType, portParameters.ThreadSize)
    else
        port:SetPipeParameters(connectionType, portParameters.NominalDiameter)
    end
end

function HideIrrelevantPortParams(portName)
    local isThread =
        Style.GetParameter(portName, "ConnectionType"):GetValue() ==
            PipeConnectorType.Thread
    Style.GetParameter(portName, "ThreadSize"):SetVisible(isThread)
    Style.GetParameter(portName, "NominalDiameter"):SetVisible(not isThread)
end
 
HideIrrelevantPortParams("Inlet")
HideIrrelevantPortParams("Outlet")
HideIrrelevantPortParams("AirRelease")

local OutletPortPlace = Placement3D(
                        Point3D(-1.5*NippleDiameter, 0, NippleDiameter/2),
                        Vector3D(-1, 0, 0), Vector3D(0, 1, 0))
                        local OutletPort = Style.GetPort("Outlet")
SetPipeParameters(OutletPort, parameters.Outlet)
OutletPort:SetPlacement(OutletPortPlace)


-- божественный вариант размещения портов от Сергея
local leftPlacement = Placement3D(Point3D(Length + 1.5*NippleDiameter, 0, NippleOffset),
                                  Vector3D(1, 0, 0), Vector3D(0, 1, 0))
local rightPlacement = Placement3D(Point3D(-1.5*NippleDiameter, 0, NippleOffset),
                                   Vector3D(-1, 0, 0), Vector3D(0, 1, 0))


local inletPort = Style.GetPort("Inlet")
local airReleasePort = Style.GetPort("AirRelease")

SetPipeParameters(inletPort, parameters.Inlet)
SetPipeParameters(airReleasePort, parameters.AirRelease)

if PipeCount % 2 == 0 then
    inletPort:SetPlacement(rightPlacement)
    airReleasePort:SetPlacement(leftPlacement)
else
    inletPort:SetPlacement(leftPlacement)
  airReleasePort:SetPlacement(rightPlacement)
end

-- Создаем условную геометрию 
-- Если PipeCount чётное, то
local UForm = CreatePolyline2D({Point2D(      -1.5*NippleDiameter, -NippleDiameter/2), 
                                Point2D(Length+1.5*NippleDiameter, -NippleDiameter/2), 
                                Point2D(Length+1.5*NippleDiameter, -NippleOffset), 
                                Point2D(      -1.5*NippleDiameter, -NippleOffset)})

-- Если PipeCount нечетное, то 
local ZForm = CreatePolyline2D({Point2D(      -1.5*NippleDiameter, -NippleDiameter/2),
                                Point2D(Length+1.5*NippleDiameter, -NippleDiameter/2),
                                Point2D(Length+1.5*NippleDiameter, -NippleOffset/2),
                                Point2D(      -1.5*NippleDiameter, -NippleOffset/2),
                                Point2D(      -1.5*NippleDiameter, -NippleOffset),
                                Point2D(Length+1.5*NippleDiameter, -NippleOffset)
                            })

local symbolPlacement = Placement3D(Point3D(0, 0, 0), Vector3D(0, 1, 0), Vector3D(1, 0, 0))

local symbol = GeometrySet2D()

if PipeCount % 2 == 0 then
    symbol:AddCurve(UForm)
else
  symbol:AddCurve(ZForm)
end

local symbolicGeometry = ModelGeometry()
symbolicGeometry:AddGeometrySet2D(symbol, symbolPlacement)

Style.SetSymbolicGeometry(symbolicGeometry)
