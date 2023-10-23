local parameters = Style.GetParameterValues()
local width = parameters.Geometry.SpWidth
local height = parameters.Geometry.SpHeight
local baseDiameter = parameters.Geometry.BodyDiameter
local baseHeight = parameters.Geometry.BodyHeight
local cupHeight = parameters.Geometry.cupHeight
local cupDiameter = parameters.Geometry.CupDiameter
local deflectorOffset = height+baseHeight-2

local base = CreateRightCircularCylinder(baseDiameter/2, baseHeight)


function Frame()
    local rectangle1 = CreateRectangle2D(Point2D(0, 0), 0, width, 4)
    local rectangle2 = CreateRectangle2D(Point2D(0, 0), 0, 6, 4)
    local placement1 = Placement3D(Point3D(0, 0, 0.75*height), Vector3D(0, 0, 1), Vector3D(1, 0, 0))
    local placement2 = Placement3D(Point3D(0, 0, height), Vector3D(0, 0, 1), Vector3D(1, 0, 0))
    local tip = Loft({rectangle1, rectangle2}, {placement1, placement2}):Shift(0, 0, baseHeight)
    local body = CreateBlock(width, 4, 0.75*height):Shift(0, 0, baseHeight)
    return Unite(body, tip)
end
math.rad(5)
function HorizontalDeflector()
	local vPlate = CreateBlock(width, width, 2):Rotate(CreateXAxis3D (), math.rad(-103,5)):Shift(0, -0.35*width, deflectorOffset)
	local hPlate = CreateBlock(width, 0.6*width, 2):Shift(0, 0, deflectorOffset)
	return Unite(vPlate, hPlate)
end

function Deflector()
	if parameters.Geometry.SpType == "Vertical" then
		return CreateRightCircularCylinder(1.2*width/2, 2) :Shift(0, 0, deflectorOffset)
	elseif parameters.Geometry.SpType == "Horizontal" then
		return HorizontalDeflector()
	end
end

local frame = Frame()
frame = Unite(frame,Deflector())

function Cup()
	local cup_p = CreateRightCircularCylinder(cupDiameter/2, cupHeight) :Shift(0,0, baseHeight)
	local cup_n = CreateRightCircularCylinder(0.5*cupDiameter-2, cupHeight) :Shift(0,0, baseHeight+2)
	local skirt = CreateRightCircularCylinder(0.5*cupDiameter + 5, 2) :Shift(0,0, baseHeight + cupHeight)
	local total = Unite(cup_p, skirt)
	local total = Subtract(total, cup_n)
	return total
end

local united = Unite(base, frame)

if  parameters.Geometry.InstallationType == "Recessed" then
	united = Unite(united, Cup())
end

united:Rotate(CreateYAxis3D(), math.pi) -- поворачиваем объединенный солид на 180°

local sprinkler = ModelGeometry()
sprinkler:AddSolid(united)

Style.SetDetailedGeometry(sprinkler)


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

--создаем условную геометрию
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






