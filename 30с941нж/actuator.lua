require("valve")
-- Получаем параметры из json
local parameters = Style.GetParameterValues()
-- Свои переменные в lua начинаются с маленькой буквы
local dNom = parameters.Geometry.DN


--параметры электропривода
function cylinder(r, h)
    local base = CreateRightCircularCylinder(r, h)
return base
end

local gearboxLenght = 240-40

function GearboxBody()
    local flangeHeight = 15
    local flangeR = 100
    local centerBodyR = 90
    local centerBodyHeight = 96
    local centerBodyRadius = 18
    local topBodyR = 65
    local topBodyHeight = 83


    local generatrixCurve = CreatePolyline2D(
        {
        Point2D(0,0),
        Point2D(flangeR, 0),
        Point2D(flangeR-2, flangeHeight),
        Point2D(centerBodyR, flangeHeight),
        Point2D(centerBodyR, flangeHeight+centerBodyHeight-centerBodyRadius),
        Point2D(topBodyR, flangeHeight+centerBodyHeight),
        Point2D(topBodyR, flangeHeight+centerBodyHeight+topBodyHeight),
        Point2D(0,        flangeHeight+centerBodyHeight+topBodyHeight)
        }
    )

    local initialCurvePlacement = Placement3D(Point3D(0, 0, 0), Vector3D(1, 0, 0), Vector3D(0, 1, 0))
    local parameters =  RevolutionParameters(math.pi*2)
    solid = Revolve(generatrixCurve, initialCurvePlacement, CreateZAxis3D(), parameters)
    return solid
end

function Gearbox()

    local gearboxDiam = 92
    local gearboxHeight = 433
    vert = cylinder(gearboxDiam/2, gearboxHeight)
    hor = cylinder(gearboxDiam/2, gearboxLenght):Rotate(CreateYAxis3D(), math.pi/2):Shift(-gearboxLenght/2, 0, 110)  
    uniteGearbox = Unite(vert, hor)
    local handwheelDiam = 320
    local handwheelHeight = 30
    local handwheelOffset = 265
    handwheel = cylinder(handwheelDiam/2, handwheelHeight):Shift(0, 0, handwheelOffset) 
    uniteGearbox = Unite(uniteGearbox, handwheel)
   
    uniteGearbox = Unite(uniteGearbox, flange)
    return uniteGearbox
end

function Motor()
    local motorLenght = 240
    local motorDiam = 180
    local flangeT = 20
    flange = cylinder(100, flangeT):Rotate(CreateYAxis3D(), math.pi/2):Shift(-gearboxLenght/2-flangeT, 0, 110)
    motorBody = cylinder(motorDiam/2, motorLenght):Rotate(CreateYAxis3D(), math.pi/2):Shift(-flangeT-gearboxLenght/2-motorLenght, 0, 110)
    motorStep1 = cylinder(102/2, 108)
    motorStep2 = cylinder(112/2, 30):Shift(0, 0, 108)
    motorStep3 = cylinder(117/2, 34):Shift(0, 0, 138)
    uniteWeb = Unite(motorStep1, motorStep2)
    uniteWeb = Unite(uniteWeb, motorStep3):Rotate(CreateXAxis3D(), math.pi/2):Shift(-182, 0, 110)
    moto = Unite(uniteWeb, motorBody)
    moto = Unite(moto, flange)
    return moto
end


function Control()
    local controlUnitLenght = 214+20
    local controlUnitDiam = 200
    
    local knobLenght = 25
    local knobDiam = 32
    local controlBody = cylinder(controlUnitDiam/2, controlUnitLenght):Rotate(CreateYAxis3D(), math.pi/2):Shift(gearboxLenght/2, 0, 110)
    local knobBody1 = cylinder(knobDiam/2, knobLenght):Rotate(CreateYAxis3D(), math.pi/2):Shift(controlUnitLenght + gearboxLenght/2, 50, 84)
    local knobBody2 = cylinder(knobDiam/2, knobLenght):Rotate(CreateYAxis3D(), math.pi/2):Shift(controlUnitLenght + gearboxLenght/2, -50, 84)
    uniteControl = Unite(controlBody, knobBody1)
    uniteControl = Unite(uniteControl, knobBody2)

local controlFlahgeHeight = 180
local halfControlWindowLength = 130
local halfControlFlahgeLength = 112
local generatrixCurve = CreatePolyline2D(
        {
        Point2D(20,0),
        Point2D(controlFlahgeHeight-20, 0),
        Point2D(controlFlahgeHeight, 20),
        Point2D(controlFlahgeHeight,controlFlahgeHeight-20),
        Point2D(controlFlahgeHeight-20,controlFlahgeHeight),
        Point2D(20, controlFlahgeHeight),
        Point2D(0,controlFlahgeHeight-20),
        Point2D(0,20),
        Point2D(20,0)
        }
    )
local placement = Placement3D(Point3D(138, 0, controlFlahgeHeight/2+110), Vector3D(0, 1, 0), Vector3D(0, 0, 0))
local parameters = ExtrusionParameters (200, 200)
parameters.ForwardDirectionDepth = halfControlFlahgeLength
parameters.	ReverseDirectionDepth = halfControlFlahgeLength
solid = Extrude(generatrixCurve, parameters, placement)
uniteControl = Unite(uniteControl, solid)
controlWindow = cylinder(0.98*controlFlahgeHeight/2, halfControlWindowLength*2):Rotate(CreateXAxis3D(), math.pi/2):Shift(138+(0.98*controlFlahgeHeight/2), halfControlWindowLength, 110)
uniteControl = Unite(uniteControl, controlWindow)
return uniteControl
end




uniteActuator = Unite(GearboxBody(), Motor())
uniteActuator = Unite(uniteActuator, Gearbox())
uniteActuator = Unite(uniteActuator, Control())

local DN = dNom --"DN150" --  и этот должен быть из json
ValveParam = tabValveParam[DN]
uniteActuator:Shift(0, 0, ValveParam.H)

function EllipticalBottom()
local arc = CreateEllipticalArc2DByCenterStartEndPoints (Point2D(0,0), math.pi/2,radiusAlongYAxis, radiusAlongXAxis, Point2D(0,radiusAlongYAxis), Point2D(radiusAlongXAxis,0),true)
local initialCurvePlacement = Placement3D(Point3D(0, 0, 0), Vector3D(1, 0, 0), Vector3D(0, 1, 0))
local parameters =  RevolutionParameters(math.pi*2)
parameters.InwardOffset = 10
quarterArc = Revolve(arc, initialCurvePlacement, CreateZAxis3D(), parameters)
return quarterArc
end


function Flange()
    local flangeHeight = 100
    local flangeDiameter = 150
    local nippleDiameter = 100
    local flangeDepth = 20
    local nippleThickness = 8

    local generatrixCurve = CreatePolyline2D(
        {
        Point2D(nippleDiameter-nippleThickness,0),
        Point2D(nippleDiameter, 0),
        Point2D(nippleDiameter, flangeHeight-flangeDepth),
        Point2D(flangeDiameter,flangeHeight-flangeDepth),
        Point2D(flangeDiameter,flangeHeight),
        Point2D(nippleDiameter-nippleThickness,flangeHeight),
        Point2D(nippleDiameter-nippleThickness,0)
        }
    )

    local initialCurvePlacement = Placement3D(Point3D(0, 0, 0), Vector3D(1, 0, 0), Vector3D(0, 1, 0))
    local parameters =  RevolutionParameters(math.pi*2)
    solid = Revolve(generatrixCurve, initialCurvePlacement, CreateZAxis3D(), parameters)
    return solid
end

local tower  = ModelGeometry()
tower:AddSolid(uniteActuator)
tower:AddSolid(Pipe(dNom)) --тут DN из json "DN150"
tower:AddSolid(uniteFlange)
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
HideIrrelevantPortParams("Outlet")

--Размещаем порты
local leftPlacement = Placement3D(Point3D(-ValveParam.L/2, 0, 0),
                                  Vector3D(-1, 0, 0), Vector3D(0, 1, 0))

local rightPlacement = Placement3D(Point3D(ValveParam.L/2, 0, 0),
                                   Vector3D(1, 0, 0), Vector3D(0, 1, 0))


local inletPort = Style.GetPort("Inlet")
local outletPort = Style.GetPort("Outlet")

SetPipeParameters(inletPort, parameters.Inlet)
SetPipeParameters(outletPort, parameters.Outlet)

inletPort:SetPlacement(leftPlacement)
outletPort:SetPlacement(rightPlacement)

--УГО 
local function add_body(geometry, length, radius)
    local triangle_contour = CreatePolyline2D({Point2D(0, 0),
                                                    Point2D(length, -radius),
                                                    Point2D(length, radius),
                                                    Point2D(0, 0)})
  
    geometry:AddCurve(CreatePolyline2D({Point2D(-length, -radius),
                                              Point2D(-length, radius),
                                              Point2D(length, -radius),
                                              Point2D(length, radius),
                                              Point2D(-length, -radius)}))

    geometry:AddCurve(CreatePolyline2D({Point2D(-length-flangeType.b*2, -radius),
                                        Point2D(-length-flangeType.b*2, radius)}))

    geometry:AddCurve(CreatePolyline2D({Point2D(length+flangeType.b*2, -radius),
                                        Point2D(length+flangeType.b*2, radius)}))

  
    geometry:AddMaterialColorSolidArea(FillArea(triangle_contour))
    geometry:AddMaterialColorSolidArea(FillArea(triangle_contour:Clone():Rotate(Point2D(0, 0), math.pi)))
  end
      
  local function add_active_actuator(geometry, radius, height, drive)
    geometry:AddCurve(CreateLineSegment2D(Point2D(0, -radius), Point2D(0, height)))
  
    local circle_contour = CreateCircle2D(Point2D(0, height + drive), drive)
    geometry:AddCurve(circle_contour)
    geometry:AddMaterialColorSolidArea(FillArea(circle_contour))
  end
  
  function make_planar_geometry(length, radius, height, drive)
    local geometry = GeometrySet2D()
  
    local add_actuator =  add_active_actuator,
      
  
    add_body(geometry, length, radius)
    add_actuator(geometry, radius, height, drive)
  
    return geometry
  end

local radius = ValveParam.d/2
local length = ValveParam.L
local height = ValveParam.H
local drive  = ValveParam.L


Style.SetSymbolicGeometry(ModelGeometry():AddGeometrySet2D(make_planar_geometry(length, radius, height, drive)))