
-- Получаем параметры из json
local parameters = Style.GetParameterValues()
-- Свои переменные в lua начинаются с маленькой буквы
local dNom = parameters.Geometry.DN

--Это таблица с задвижками
tabValveParam={
    DN50 = {L=180, D=160, d= 50, H = 291, H1 = 349,  D0 = 160},
    DN80 = {L=210, D=195, d= 80, H = 336, H1 = 419,  D0 = 160},
    DN100 = {L=230, D=215, d= 100, H = 385, H1 = 485,  D0 = 210},
    DN125 = {L=255, D=245, d= 125, H = 470, H1 = 600,  D0 = 210},
    DN150 = {L=280, D=280, d= 150, H = 558, H1 = 709,  D0 = 320},
    DN200 = {L=330, D=335, d= 200, H = 685, H1 = 892,  D0 = 320},
    DN250 = {L=450, D=405, d= 250, H = 854, H1 = 1110,  D0 = 400},
    DN300 = {L=500, D=460, d= 300, H = 998, H1 = 1307,  D0 = 460},
    DN350 = {L=550, D=520, d= 350, H = 1120, H1 = 1570,  D0 = 460},
    DN400 = {L=600, D=580, d= 400, H = 1440, H1 = 1850,  D0 = 502},
}

function cylinder(r, h)
    return CreateRightCircularCylinder(r, h)
end


function Pipe(DN)
    ValveParam = tabValveParam[DN]
    local pipe = cylinder(ValveParam.d*0.6, ValveParam.L):Rotate(CreateYAxis3D(), math.pi/2):Shift(-ValveParam.L/2, 0, 0)
    local pallet = cylinder(ValveParam.d*0.7, ValveParam.L/3):Rotate(CreateYAxis3D(), math.pi/2):Shift(-ValveParam.L/6, 0, 0)
    solid = Unite(pipe, pallet)
    local bodyHeight = (ValveParam.d+ValveParam.H)/2.3
    local bodyLength = ValveParam.L/3
    local body = CreateBlock(bodyLength,ValveParam.d*1.4, bodyHeight)
    local stem = CreateBlock(bodyLength,ValveParam.L/3, ValveParam.H)
    solid = Unite(solid, body)
    solid = Unite(solid, stem)
    solid:ShowTangentEdges(false)
    
    --фланцевая крышка
    --[[
    local rect2D = CreateRectangle2D(Point2D(ValveParam.L/2, 0), 0,  ValveParam.L*0.15, ValveParam.L/20)
    FilletCorners2D(rect2D, 5)
    local rect3D = CreateRectangle3D(Point3D(0, 0, 0), Vector3D(0, 0, 1), Vector3D(1, 0, 0), ValveParam.L*0.4, ValveParam.d*1.5)
    local cup = Evolve(rect2D, Placement3D(Point3D(0,0,bodyHeight - 0.5*(ValveParam.L/20)),Vector3D(1,0,0),Vector3D(1,0,0)),rect3D)
    ]]
    --фланцевая крышка без скруглений
    cup = CreateBlock(bodyLength*1.2,ValveParam.d*1.6, ValveParam.L/20):Shift(0, 0, bodyHeight)

    solid = Unite(solid, cup)
    return solid
end

tabFlangeType01={
    
    DN50 = {di=59,b=22,D=160,D1=125,h=3,D2=102},
    DN80 = {di=91,b=24,D=195,D1=160,h=3,D2=133},
    DN100 = {di=110,b=26,D=215,D1=180,h=3,D2=158},
    DN125 = {di=135,b=28,D=245,D1=210,h=3,D2=184},
    DN150 = {di=154,b=28,D=280,D1=240,h=3,D2=212},
    DN200 = {di=222,b=30,D=335,D1=295,h=3,D2=268},
    DN250 = {di=273,b=31,D=405,D1=355,h=3,D2=320},
    DN300 = {di=325,b=32,D=460,D1=410,h=4,D2=410},
    DN350 = {di=377,b=34,D=520,D1=470,h=4,D2=430},
    DN400 = {di=426,b=38,D=580,D1=525,h=4,D2=482},
}

function flangeType01(DN)
    flangeType = tabFlangeType01[DN]
    local contour = CreatePolyline2D({
        Point2D(flangeType.di/2,flangeType.b-flangeType.h),
        Point2D(flangeType.D/2,flangeType.b-flangeType.h),
        Point2D(flangeType.D/2,0),
        Point2D(flangeType.D2/2+flangeType.h,0),
        Point2D(flangeType.D2/2,-flangeType.h),
        Point2D(flangeType.di/2,-flangeType.h),
        Point2D(flangeType.di/2,flangeType.b-flangeType.h)
    })
    local flange = Revolve(contour,Placement3D(Point3D(0,0,0),Vector3D(0,-1,0),Vector3D(1,0,0)),CreateZAxis3D(),RevolutionParameters(math.pi*2))
    flange = Unite(flange,flange:Clone():Rotate(Axis3D(Point3D(0,0,-flangeType.h),Vector3D(0,1,0)),math.pi))
    return flange
end
--размещение фланцев (в параметрах сдвига ошибка на размер линзы)
local DN = dNom --  и этот должен быть из json
ValveParam = tabValveParam[DN] 
local leftFlange = flangeType01(DN):Rotate(CreateYAxis3D(), math.pi/2):Shift(-ValveParam.L/2 + flangeType.h, 0, 0)
local rightFlange = flangeType01(DN):Rotate(CreateYAxis3D(), math.pi*3/2):Shift(ValveParam.L/2 -flangeType.h, 0, 0)
uniteFlange = Unite(leftFlange, rightFlange)
uniteFlange = Unite(uniteFlange, Pipe(DN))


-- и второй вопрос, как луше делать, когда берется одно и тоже тело, и его нужно 2 штуки получить (слева и справа)?
--[[ альтернативный вариант задваивания солидов
local flangeBase = flangeType01("DN150")
local leftFlange = flangeBase:Clone():Rotate(CreateYAxis3D(), math.pi/2):Shift(-ValveParam.L/2, 0, 0)
local rightFlange =  flangeBase:Clone():Rotate(CreateYAxis3D(), math.pi*3/2):Shift(ValveParam.L/2, 0, 0)
]]
--[[это переехало в главный файл actuator.lua
local valve  = ModelGeometry()
valve:AddSolid(Pipe("DN150")) --тут DN из json
valve:AddSolid(uniteFlange)
Style.SetDetailedGeometry(valve)
]]



