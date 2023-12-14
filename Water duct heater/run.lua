local parameters = Style.GetParameterValues()
local width = parameters.Geometry.Width
local height = parameters.Geometry.Height
local depth = parameters.Geometry.Depth

local pipeDiameter = parameters.Geometry.PipeDiameter
local pipeSpacing = parameters.Geometry.PipeSpacing
local pipeLength = parameters.Geometry.PipeLength

local inletLength = parameters.Inlet.NippleLength
local inletDiam = parameters.Inlet.NominalDiameter
local outletLength = parameters.Outlet.NippleLength
local outletDiam = parameters.Outlet.NominalDiameter
-- это кубик корпуса
local body = CreateBlock(width, depth, height):Shift(0,0,-height/2)

function connector(r, h)
    local solid = CreateRightCircularCylinder(r,h)
    return solid
end
--Вентпатрубки
local inletPlace = Placement3D(
                         Point3D(-width / 2, 0, 0),
                         Vector3D(-1, 0, 0), Vector3D(0, 1, 0))
local inletConnector = connector(inletDiam/2, inletLength):Transform(inletPlace:GetMatrix())

local outletPlace = Placement3D(
                         Point3D(width / 2, 0, 0),
                         Vector3D(1, 0, 0), Vector3D(0, 1, 0))
local outletConnector = connector(outletDiam/2, outletLength):Transform(outletPlace:GetMatrix())
--
function waterconnector()
    --водяной патрубок
    local waterConnector = connector(pipeDiameter/2,pipeLength):Shift(0,0,-pipeLength)
   
    if parameters.Geometry.InstallationType == "Along" then
        --первый водяной партубок        
        local connector1Place = Placement3D(
                                            Point3D(width/2, -depth/2+pipeDiameter, pipeSpacing/2),
                                            Vector3D(-1, 0, 0), Vector3D(0, 1, 0))
        local water1Connector = waterConnector:Clone():Transform(connector1Place:GetMatrix())
        -- второй водяной патрубок        
        local connector2Place = Placement3D(
                                            Point3D(width/2, -depth/2+pipeDiameter, -pipeSpacing/2),
                                            Vector3D(-1, 0, 0), Vector3D(0, 1, 0))
        local water2Connector = waterConnector:Clone():Transform(connector2Place:GetMatrix())
        local unitedPipe = Unite(water1Connector, water2Connector)
         return unitedPipe
    else

--первый водяной партубок        
        local connector1Place = Placement3D(
                                            Point3D(-pipeDiameter, -depth/2, pipeSpacing/2),
                                            Vector3D(0, 1, 0), Vector3D(0, 1, 0))
        local water1Connector = waterConnector:Clone():Transform(connector1Place:GetMatrix())
-- второй водяной патрубок        
        local connector2Place = Placement3D(
                                            Point3D(pipeDiameter, -depth/2, -pipeSpacing/2),
                                            Vector3D(0, 1, 0), Vector3D(0, 1, 0))
        local water2Connector = waterConnector:Clone():Transform(connector2Place:GetMatrix())
--коллектор       
        local collector = connector(pipeDiameter/2, pipeSpacing+pipeDiameter)
        local collectorYOffsrt = -depth/2-0.3*pipeLength
        local collectorZOffsrt = -(pipeSpacing+pipeDiameter)/2
--первый водяной коллектор
        local collector1Place = Placement3D(
                            Point3D(-pipeDiameter, collectorYOffsrt, collectorZOffsrt),
                            Vector3D(0, 0, 1), Vector3D(0, 1, 0))
        local collector1 = collector:Clone():Transform(collector1Place:GetMatrix())
--второй водяной коллектор        
        local collector2Place = Placement3D(
                         Point3D(pipeDiameter, collectorYOffsrt, collectorZOffsrt),
                         Vector3D(0, 0, 1), Vector3D(0, 1, 0))
        local collector2 = collector:Clone():Transform(collector2Place:GetMatrix())
        
        local unitedCollector = Unite(collector1, collector2)
        local unitedCollector = Unite(unitedCollector, water1Connector)
        local unitedCollector = Unite(unitedCollector, water2Connector)
        
        return unitedCollector
    end
end

local united = Unite(inletConnector, outletConnector)
local united = Unite(united, body)
local united = Unite(united, waterconnector())
local heater = ModelGeometry()
heater:AddSolid(united)

Style.SetDetailedGeometry(heater)


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
HideIrrelevantPortParams("Water1")
HideIrrelevantPortParams("Water2")

-- Determine the position of the Inlet
local portPlace1 = Placement3D(
                         Point3D(width / 2 + 50, 0, 0),
                         Vector3D(1, 0, 0), Vector3D(0, 1, 0))
-- Configure the port
local port1 = Style.GetPort("Inlet")
port1:SetPlacement(portPlace1)
port1:SetDuctParameters(parameters.Inlet.ConnectionType,CircularProfile(parameters.Inlet.NominalDiameter))


-- Determine the position of the Inlet
local portPlace2 = Placement3D(
                         Point3D(-width / 2 - 50, 0, 0),
                         Vector3D(-1, 0, 0), Vector3D(0, 1, 0))
-- Configure the port
local port2 = Style.GetPort("Outlet")
port2:SetPlacement(portPlace2)
port2:SetDuctParameters(parameters.Outlet.ConnectionType,CircularProfile(parameters.Outlet.NominalDiameter))

if parameters.Geometry.InstallationType == "Along" then
-- Determine the position of the Water1

local portPlace3 = Placement3D(
                         Point3D(width/2+pipeLength, -depth/2+pipeDiameter, pipeSpacing/2),
                         Vector3D(1, 0, 0), Vector3D(0, 1, 0))
-- Configure the port
local port3 = Style.GetPort("Water1")
SetPipeParameters(port3, parameters.Water1)
port3:SetPlacement(portPlace3)


-- Determine the position of the Water2
local portPlace4 = Placement3D(
                            Point3D(width/2+pipeLength, -depth/2+pipeDiameter, -pipeSpacing/2),
                            Vector3D(1, 0, 0), Vector3D(0, 1, 0))
-- Configure the port
local port4 = Style.GetPort("Water2")
SetPipeParameters(port4, parameters.Water2)
port4:SetPlacement(portPlace4)

else
-- Determine the position of the Water1
local portPlace3 = Placement3D(
                         Point3D(-pipeDiameter, -depth/2-pipeLength, pipeSpacing/2),
                         Vector3D(0, -1, 0), Vector3D(0, 1, 0))
-- Configure the port
local port3 = Style.GetPort("Water1")
SetPipeParameters(port3, parameters.Water1)
port3:SetPlacement(portPlace3)


-- Determine the position of the Water2
local portPlace4 = Placement3D(
                         Point3D(pipeDiameter, -depth/2-pipeLength, -pipeSpacing/2),
                         Vector3D(0, -1, 0), Vector3D(0, 1, 0))
-- Configure the port
local port4 = Style.GetPort("Water2")
SetPipeParameters(port4, parameters.Water2)
port4:SetPlacement(portPlace4)
end



--создаем условную геометрию
--[[
local delta = CreatePolyline2D({Point2D(-height/2,0), Point2D(0, height), Point2D(height/2,0), Point2D(-height/2,0)})

local corner = CreatePolyline2D({Point2D(-height/2,height), Point2D(height/2, height), Point2D(height/2, 1.5*height)})

local symbolPlacement = Placement3D(Point3D(0, 0, 0), Vector3D(0, 1, 0), Vector3D(1, 0, 0))


local symbol = GeometrySet2D()
symbol:AddCurve(delta)
symbol:AddLineColorSolidArea(FillArea(delta))
if parameters.Geometry.SpType ~= "Vertical" then
  symbol:AddCurve(corner)
end
local symbolicGeometry = ModelGeometry()
symbolicGeometry:AddGeometrySet2D(symbol, symbolPlacement)


Style.SetSymbolicGeometry(symbolicGeometry)



]]