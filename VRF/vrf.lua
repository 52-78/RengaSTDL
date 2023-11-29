-- создание экземпляра ModelGeometry
local detailedGeometry = ModelGeometry()

-- объявление локальных переменных
local parameters = Style.GetParameterValues()

local height = parameters.Dimensions.bodyHeight
local width = parameters.Dimensions.bodyWidth
local length = parameters.Dimensions.bodyLength

-- создание детального отображения категории
-- создание профиля
local function makeProfile()
    local points = {
        Point2D(0, 0),
        Point2D(0, height),
        Point2D(width, height),
        Point2D(width, height / 8),
        Point2D(width / 3, 0),
        Point2D(0, 0)}
    local profile = CreatePolyline2D(points)
    FilletCornerAfterSegment2D(profile, 2, width / 4)
    return profile
end

-- задание ЛСК
local vrfPlacement = Placement3D(Point3D(0, 0, 0),
                                 Vector3D(-1, 0, 0),
                                 Vector3D(0, -1, 0))

-- дополнительные параметры для функции Extrude()
local extrusionParams = ExtrusionParameters(length)

-- создание твердотельной 3D-геометрии
local vrfSolid = Extrude(makeProfile(), extrusionParams, vrfPlacement)
    :Shift(length / 2, width / 2, 0)

-- добавление твердотельной 3D-геометрии в детальную геометрию
detailedGeometry:AddSolid(vrfSolid)

-- создание детальной геометрии стиля
Style.SetDetailedGeometry(detailedGeometry)

-- создание условного отображения категории
-- создание экземпляра ModelGeometry
local symbolicGeometry = ModelGeometry()

-- создание двумерных кривых для планарной геометрии
local contour = CreateRectangle2D(Point2D(0, 0), 0, length, width)
local letterS = CreateCompositeCurve2D({
                    CreateArc2DByThreePoints(Point2D(19.4, 23), Point2D(4.2, 30.4), Point2D(-12, 26)),
                    CreateArc2DByThreePoints(Point2D(-12, 26), Point2D(-16.4, 14.2), Point2D(-9, 4.2)),
                    CreateLineSegment2D(Point2D(-9, 4.2), Point2D(9, -4.2)),
                    CreateArc2DByThreePoints(Point2D(9, -4.2), Point2D(16.4, -14.2), Point2D(12, -26)),
                    CreateArc2DByThreePoints(Point2D(12, -26), Point2D(-4.2, -30.4), Point2D(-19.4, -23))})

-- создание экземпляра планарной геометрии
local geometry = GeometrySet2D()

-- задание ЛСК
local geometryPlacement = Placement3D(Point3D(0, 0, height), Vector3D(0, 0, 1), Vector3D(1, 0, 0))

-- добавление кривых и области заливки в планарную геометрию
geometry:AddCurve(contour):AddCurve(letterS)
geometry:AddMaterialColorSolidArea(FillArea(contour))

-- добавление планарной геометрии в модельную геометрию
symbolicGeometry:AddGeometrySet2D(geometry, geometryPlacement)

-- создание условной геометрии стиля
Style.SetSymbolicGeometry(symbolicGeometry)

-- создание портов трубопроводных систем
-- объявление локальных переменных
local halfWidth = width / 2
local halfLengthWithIndent50 = length / 2 - 50
local waterPortIntendation = parameters.WaterCoolant.portIndentation
local gasPortIntendation = parameters.GasCoolant.portIndentation
local drainagePortIntendation = parameters.Drainage.portIndentation

-- декартовы точки по-умолчанию
local waterCoolantOrigin = Point3D(0, 0, 0)
local gasCoolantOrigin = Point3D(0, 0, 0)
local drainageOrigin = Point3D(0, 0, 0)

-- размещение декартовых точек портов с учетом параметра connectionSide
if parameters.WaterCoolant.connectionSide == "right" then
    waterCoolantOrigin = Point3D(halfLengthWithIndent50,
                                 halfWidth - waterPortIntendation, 75)
else
    waterCoolantOrigin = Point3D(-halfLengthWithIndent50,
                                  halfWidth - waterPortIntendation, 75)
end

if parameters.GasCoolant.connectionSide == "right" then
    gasCoolantOrigin = Point3D(halfLengthWithIndent50,
                               halfWidth - gasPortIntendation, 50)
else
    gasCoolantOrigin = Point3D(-halfLengthWithIndent50,
                                halfWidth - gasPortIntendation, 50)
end

if parameters.Drainage.connectionSide == "right" then
    drainageOrigin = Point3D(halfLengthWithIndent50,
                             halfWidth - drainagePortIntendation, 25)
else
    drainageOrigin = Point3D(-halfLengthWithIndent50,
                              halfWidth - drainagePortIntendation, 25)
end

-- создание функции rotateVectors, которая будет возвращать векторы осей Z и X в зависимости от параметра connectionDirection, задающего направление подключения.
local function rotateVectors(name)
    local direction = parameters[name].connectionDirection
    local side = parameters[name].connectionSide

    -- векторы по-умолчанию
    local vectorZ = Vector3D(0, 0, 1)
    local vectorX = Vector3D(1, 0, 0)

    if direction == "side" then
        if side == "right" then
            vectorZ = Vector3D(1, 0, 0)
            vectorX = Vector3D(0, 1, 0)
        else
            vectorZ = Vector3D(-1, 0, 0)
            vectorX = Vector3D(0, 1, 0)
        end
    elseif direction == "back" then
        vectorZ = Vector3D(0, 1, 0)
        vectorX = Vector3D(1, 0, 0)
    else
        vectorZ = Vector3D(0, 0, -1)
        vectorX = Vector3D(1, 0, 0)
    end
    local vectors = {z = vectorZ, x = vectorX}
    return vectors
end

-- создание функции setPipeAttributes, которая будет добавлять параметры соединения портам
local function setPipeAttributes(port, portParameters)
    return parameters[portParameters].connectorType == PipeConnectorType.Thread
        and port:SetPipeParameters(parameters[portParameters].connectorType, parameters[portParameters].threadSize)
        or port:SetPipeParameters(parameters[portParameters].connectorType, parameters[portParameters].nominalDiameter)
end

-- размещение портов трубопроводных систем и добавление к ним параметров соединения
Style.GetPort("WaterCoolant"):SetPlacement(Placement3D(waterCoolantOrigin,
                                            rotateVectors("WaterCoolant").z,
                                            rotateVectors("WaterCoolant").x))
setPipeAttributes(Style.GetPort("WaterCoolant"), "WaterCoolant")

Style.GetPort("GasCoolant"):SetPlacement(Placement3D(gasCoolantOrigin,
                                            rotateVectors("GasCoolant").z,
                                            rotateVectors("GasCoolant").x))
setPipeAttributes(Style.GetPort("GasCoolant"), "GasCoolant")

Style.GetPort("Drainage"):SetPlacement(Placement3D(drainageOrigin,
                                            rotateVectors("Drainage").z,
                                            rotateVectors("Drainage").x))
setPipeAttributes(Style.GetPort("Drainage"), "Drainage")

-- создание портов электрических систем
-- объявление локальных переменных
local halfHeight = height / 2
local direction = 1
local electricPortIntendation = parameters.ElectricConnectors.portIndentation
local distanceBetweenElectricPorts = parameters.ElectricConnectors.distanceBetweenPorts

--декартова точка портов по-умолчанию
local electricConnectorsOrigin = Point3D(-distanceBetweenElectricPorts,
                                        halfWidth - electricPortIntendation,
                                        halfHeight)

-- изменение точки вставки портов в зависимости от параметра portLocation
if parameters.ElectricConnectors.portLocation == "right" then
    electricConnectorsOrigin = Point3D(halfLengthWithIndent50,
                                        halfWidth - electricPortIntendation,
                                        halfHeight)
    direction = -1
elseif parameters.ElectricConnectors.portLocation == "left" then
    electricConnectorsOrigin = Point3D(-halfLengthWithIndent50,
                                        halfWidth - electricPortIntendation,
                                        halfHeight)
end

-- размещение портов электрических систем
Style.GetPort("PowerSupplyLine"):SetPlacement(Placement3D(
                                                electricConnectorsOrigin,
                                                Vector3D(0, 1, 0),
                                                Vector3D(1, 0, 0)))
Style.GetPort("ControlNetwork1"):SetPlacement(Placement3D(
                                                electricConnectorsOrigin
                                                :Shift(direction * distanceBetweenElectricPorts, 0, 0),
                                                Vector3D(0, 1, 0),
                                                Vector3D(1, 0, 0)))
Style.GetPort("ControlNetwork2"):SetPlacement(Placement3D(
                                                electricConnectorsOrigin
                                                :Shift(direction * distanceBetweenElectricPorts, 0, 0),
                                                Vector3D(0, 1, 0),
                                                Vector3D(1, 0, 0)))

-- настройка отображения параметров в диалоге стиля объекта
-- функция hideIrrelevantPortParam, которая в зависимости от выбранного вида соединения будет отображать в диалоге стиля объекта либо параметр nominalDiameter, либо threadSize.
local function hideIrrelevantPortParam(portName)
    local param = parameters[portName].connectorType == PipeConnectorType.Thread
      and "nominalDiameter" or "threadSize"
    Style.GetParameter(portName, param):SetVisible(false)
end

hideIrrelevantPortParam("WaterCoolant")
hideIrrelevantPortParam("GasCoolant")
hideIrrelevantPortParam("Drainage")