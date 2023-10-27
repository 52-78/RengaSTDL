-- Получаем параметры из json
local parameters = Style.GetParameterValues()
-- Свои переменные в lua начинаются с маленькой буквы
local width = parameters.Geometry.Width 
local depth = parameters.Geometry.Depth
local height = parameters.Geometry.Height
local inletOffset = parameters.Inlet.InletOffset
local inletDiameter = parameters.Inlet.InletDiameter
local outlettOffset = parameters.Outlet.OutlettOffset
local outletDiameter = parameters.Outlet.OutletDiameter


function Body()
    local box = CreateBlock(width, depth, height)
    return box
end

function Nipple(r, l)
    local cylinder = CreateRightCircularCylinder(r, l)
    return cylinder
end


function Socket()
    local inletNipple
    local outletNipple
    outletNipple = Nipple(outletDiameter/2, 1.5*outletDiameter):Rotate(CreateYAxis3D(), math.pi/2):Shift(width/2, 0, outlettOffset)  
    inletNipple = Nipple(inletDiameter/2, 1.5*inletDiameter)
    
    if parameters.Inlet.InletPosition == "Vertical" then
        inletNipple:Shift((-width/2)+(inletDiameter), 0, height)
    else
        inletNipple:Rotate(CreateYAxis3D(), -math.pi/2):Shift(-width/2, 0, inletOffset)
    end
    UniteSocket = Unite(inletNipple, outletNipple)
    return UniteSocket
end

local unitedBody = Unite(Body(), Socket()) -- объединяем солиды, чтобы не было лишней геометрии и были правильные ребра
local trap = ModelGeometry()
trap:AddSolid(unitedBody) -- добавляем солиды к модельной геометрии
Style.SetDetailedGeometry(trap) -- добавляем модельную геометрию к стилю

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
local leftPlacement = Placement3D(Point3D(-(width/2 + 1.5*inletDiameter), 0, inletOffset),
                                  Vector3D(-1, 0, 0), Vector3D(0, 1, 0))

local topPlacement = Placement3D(Point3D((-width/2)+(inletDiameter), 0, height + 1.5*inletDiameter),
                                   Vector3D(0, 0, 1), Vector3D(0, 1, 0))

local rightPlacement = Placement3D(Point3D((width/2 + 1.5*outletDiameter), 0, outlettOffset),
                                   Vector3D(1, 0, 0), Vector3D(0, 1, 0))


local inletPort = Style.GetPort("Inlet")
local outletPort = Style.GetPort("Outlet")   

SetPipeParameters(inletPort, parameters.Inlet)
SetPipeParameters(outletPort, parameters.Outlet)

if parameters.Inlet.InletPosition == "Vertical" then
    inletPort:SetPlacement(topPlacement)
else
    inletPort:SetPlacement(leftPlacement)
  
end

outletPort:SetPlacement(rightPlacement)



--Создаем символьную геометрию

local rectangle = CreateRectangle2D(Point2D(0, -height/2), 0, width, height)


local modelGeometry = ModelGeometry()
local geometry2d = GeometrySet2D()
geometry2d:AddCurve(rectangle)
geometry2d:AddMaterialColorSolidArea(FillArea(rectangle))

-- тут смущают отрицательные смещения, возможно, что неправильно задан плейсмент
geometry2d:AddCurve(CreateLineSegment2D(Point2D(width/2 - 1.5*outletDiameter, -outlettOffset), Point2D(width/2 + 1.5*outletDiameter, -outlettOffset)))
geometry2d:AddCurve(CreateLineSegment2D(Point2D(width/2 - 1.5*outletDiameter, -outlettOffset), Point2D(width/2 - 1.5*outletDiameter, -outlettOffset/2)))
geometry2d:AddCurve(CreateLineSegment2D(Point2D(0, 0), Point2D(0, -outlettOffset)))

if parameters.Inlet.InletPosition == "Vertical" then
    geometry2d:AddCurve(CreateLineSegment2D(Point2D(-(width/2)+inletDiameter, -height), 
                                            Point2D(-(width/2)+inletDiameter, -(height + 1.5*inletDiameter))))
else
    geometry2d:AddCurve(CreateLineSegment2D(Point2D(-width/2, -inletOffset), 
                                            Point2D(-(width/2 + 1.5*inletDiameter), -inletOffset)))
end

--тут задаем плейсмент 
local symbolPlacement = Placement3D(Point3D(0, 0, 0), Vector3D(0, 1, 0), Vector3D(1, 0, 0))
modelGeometry:AddGeometrySet2D(geometry2d, symbolPlacement)

Style.SetSymbolicGeometry(modelGeometry)