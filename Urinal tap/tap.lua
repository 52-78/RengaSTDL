
-- Получаем параметры из json
local parameters = Style.GetParameterValues()
-- Свои переменные в lua начинаются с маленькой буквы
local height = parameters.Geometry.Height
local depth = parameters.Geometry.Depth
local depthOffset = parameters.Geometry.DepthOffset
local bodyDiameter = parameters.Geometry.BodyDiameter

function Cylinder(radius, height)
  return CreateRightCircularCylinder(radius,height)
end

local pipeConnectorDiam = 21.3
local pipeConnectorHeight = 14
local connector = Cylinder(pipeConnectorDiam/2, pipeConnectorHeight)
local ring = Cylinder(1.2*bodyDiameter/2, 2):Shift(0, 0, pipeConnectorHeight)

--гайка
local nutR = 0.9*bodyDiameter/2
local nutH = 5
local bodyDepth = 0.8*depth-nutH-2
function nut(nutR,nutH)
    local points = {}
    local p0 = Point2D(-nutR,0)
    table.insert(points,p0)
    for i=1,6 do
        table.insert(points,p0:Clone():Rotate(Point2D(0,0),math.pi/3*i))
    end
    local contour = CreatePolyline2D(points)
    return Extrude(contour,ExtrusionParameters(nutH))--
end

local body = Cylinder(bodyDiameter/2, bodyDepth):Shift(0, 0, pipeConnectorHeight+2)
local knob = Cylinder(bodyDiameter/2, 0.2*depth):Shift(0, 0, pipeConnectorHeight+2+bodyDepth+nutH)
function pipe()
    local hose = Cylinder(8, height)
    local miniNut = nut(11,10):Shift(0, 0, bodyDiameter*0.8)
    local bottomRing = Cylinder(21, 2):Shift(0, 0, height-2)
    uniteBody = Unite(hose, miniNut)
    uniteBody = Unite(uniteBody, bottomRing)
    return uniteBody:Rotate(CreateXAxis3D(),math.pi/2):Shift(0, 0, depthOffset)
end



uniteBody = Unite(connector, ring)
uniteBody = Unite(uniteBody, body)
uniteBody = Unite(uniteBody, nut(nutR,nutH):Shift(0, 0, pipeConnectorHeight+2+bodyDepth))
uniteBody = Unite(uniteBody, knob)
uniteBody = Unite(uniteBody, pipe())
uniteBody:Rotate(CreateXAxis3D(),math.pi/2)


local tap  = ModelGeometry(uniteBody)
tap:AddSolid(uniteBody)
Style.SetDetailedGeometry(tap)

--Прячем номинальный диаметр (этот код пригодится нам не один раз)
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


--Размещаем порты
local rightPlacement = Placement3D(Point3D(0, 0, 0),
                                   Vector3D(0, 1, 0), Vector3D(0, 1, 0))
local inletPort = Style.GetPort("Inlet")
SetPipeParameters(inletPort, parameters.Inlet)
inletPort:SetPlacement(rightPlacement)


--Условное изображение для оборуования
local outflowTop = CreateLineSegment2D(Point2D(0, -height+bodyDiameter),Point2D(bodyDiameter, -height))
local outflow = CreateLineSegment2D(Point2D(0, -height+bodyDiameter),Point2D(-bodyDiameter, -height))

local ball = CreateCircle2D(Point2D(0, 0), bodyDiameter/2)
local isiBody = CreateLineSegment2D(Point2D(0, 0),Point2D(0, -height))


local symbolPlacement = Placement3D(Point3D(0, 0, 0), Vector3D(0, -1, 0), Vector3D(1, 0, 0))
local geometrySet = GeometrySet2D()
geometrySet:AddCurve(ball)
geometrySet:AddCurve(isiBody)
geometrySet:AddLineColorSolidArea(FillArea(ball))
geometrySet:AddCurve(outflow)
geometrySet:AddCurve(outflowTop)
local symbolicGeometry = ModelGeometry()
symbolicGeometry:AddGeometrySet2D(geometrySet, symbolPlacement)

Style.SetSymbolicGeometry(symbolicGeometry)

