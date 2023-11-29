
-- Получаем параметры из json
local parameters = Style.GetParameterValues()
-- Свои переменные в lua начинаются с маленькой буквы
local dNom = parameters.Geometry.DN

--Это таблица с задвижками
tabValveParam={
    DN14 = {A = 49, B = 48, C = 58, D = 56, E = 102, t = 87,  F = 14, d = 21,3},
    DN19 = {A = 52, B = 57, C = 65, D = 56, E = 112, t = 95,  F = 19, d = 26,8},
    DN24 = {A = 66, B = 73, C = 79, D = 75, E = 153, t = 130, F = 24, d = 33,5}
}

function valve(DN)
    valveType = tabValveParam[DN]
    local contour = CreatePolyline3D({
        Point3D(-valveType.C, 0, 0),
        Point3D(-valveType.t, 0, 0),
        Point3D(-valveType.E, 0, -valveType.B)
    })
    
    FilletCorners3D(contour, valveType.F)
    local body = CreateSweptDiskSolid(valveType.F/2, 0, contour):ShowTangentEdges(false)
    local line = CreateLineSegment3D(Point3D(0,0,0), Point3D(-valveType.C,0,0))
    local connector = CreateSweptDiskSolid(valveType.d/2, 0, line)
    
    local ballContour = CreatePolyline2D({
        Point2D(0, 0),
        Point2D(0, valveType.d/2),
        Point2D(1.2*valveType.d, 1.3*valveType.d/2),
        Point2D(1.2*valveType.d, 0)
    })
    FilletCorners2D(ballContour, 5)
    local initialCurvePlacement = Placement3D(Point3D(-valveType.C-(1.1*valveType.d)/2, 0, 0), Vector3D(0, 1, 0), Vector3D(1, 0, 0))
    local parameters =  RevolutionParameters(math.pi*2)
    ball = Revolve(ballContour, initialCurvePlacement, CreateXAxis3D(), parameters):ShowTangentEdges(false)

    uniteBody = Unite(body, ball)
    uniteBody = Unite(uniteBody, connector)

    return uniteBody
end

function Cylinder(r, h)
    return CreateRightCircularCylinder(r, h)
end

local DN = dNom
valveType = tabValveParam[DN]
local shaft = Cylinder(valveType.d/4, valveType.A):Shift(-valveType.C, 0, 0)
valveShaft = Unite(valve(DN), shaft)
local handle = CreateBlock(valveType.D, valveType.d/2, valveType.d/4):Shift(-valveType.C-valveType.D/2, 0, valveType.A-valveType.d/4)
valveShaft = Unite(valveShaft, handle)
valveShaft:ShowTangentEdges(false)
local ring = Cylinder(valveType.d/1.5, 5):Rotate(CreateYAxis3D(), math.pi*3/2):Shift(-14, 0, 0)
valveShaft = Unite(valveShaft, ring)


local tower  = ModelGeometry(valveShaft)
tower:AddSolid(valveShaft)
Style.SetDetailedGeometry(tower)

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
                                   Vector3D(1, 0, 0), Vector3D(0, 1, 0))
local inletPort = Style.GetPort("Inlet")
SetPipeParameters(inletPort, parameters.Inlet)
inletPort:SetPlacement(rightPlacement)


--Условное изображение для оборуования

    valveType = tabValveParam[DN]
    local contour2D = CreatePolyline2D({
        Point2D(0, 0),
        Point2D(-valveType.t, 0),
        Point2D(-valveType.E, -valveType.B)
    })
    
    FilletCorners2D(contour2D, valveType.F)
    
    local ball = CreateCircle2D(Point2D(-valveType.C, 0),valveType.d/2)
    local handle2D = CreateLineSegment2D(Point2D(-valveType.C-valveType.D/2, valveType.A),Point2D(-valveType.C+valveType.D/2, valveType.A))
    local shaft2D = CreateLineSegment2D(Point2D(-valveType.C, 0),Point2D(-valveType.C, valveType.A))
    
    local outflow = CreatePolyline2D({
        Point2D(0, 0),
        Point2D(-valveType.t, 0),
        Point2D(-valveType.E, -valveType.d)
    })
    local outflowTop = CreateLineSegment2D(Point2D(-valveType.t, 0),Point2D(-valveType.E, valveType.d))



local symbolPlacement = Placement3D(Point3D(0, 0, 0), Vector3D(0, -1, 0), Vector3D(1, 0, 0))
local geometrySet = GeometrySet2D()
geometrySet:AddCurve(ball)
geometrySet:AddCurve(handle2D)
geometrySet:AddCurve(shaft2D)
geometrySet:AddLineColorSolidArea(FillArea(ball))
if parameters.Geometry.Purpose == "StandpipeTap" then
    geometrySet:AddCurve(contour2D)
  else
    geometrySet:AddCurve(outflow)
    geometrySet:AddCurve(outflowTop)
end
local symbolicGeometry = ModelGeometry()
symbolicGeometry:AddGeometrySet2D(geometrySet, symbolPlacement)

Style.SetSymbolicGeometry(symbolicGeometry)