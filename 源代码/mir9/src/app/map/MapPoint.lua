
-- 
local MapPoint = class("MapPoint")

local GRID_SIZE = cc.size(60, 32)

function MapPoint:ctor(x, z)
    if (x and z) then
        self.x = math.floor(x)
        self.z = math.floor(z)
    elseif (x) then
        if type(x) == "number" then
            self.x = math.floor(x / 65536)
            self.z = math.floor(x % 65536)
        else
            self.x = math.floor(x.x/GRID_SIZE.width)
            self.z = math.floor(x.y/GRID_SIZE.height)
        end
    else
        self.x = 0
        self.z = 0
    end
end

function MapPoint:getValue()
    return self.x * 65536 + self.z
end

function MapPoint:getCCPointValue()
    local point = cc.p(self.x * GRID_SIZE.width, self.z * GRID_SIZE.height)
    return cc.pAdd(point, cc.p(GRID_SIZE.width/2, GRID_SIZE.height/2))
end

function MapPoint:getCCSizeValue()
    return cc.size(self.x * GRID_SIZE.width, self.z * GRID_SIZE.height)
end

-- 赋值
function MapPoint.set(left, right)
    left.x = right.x
    left.z = right.z
    return left
end

-- 相加
function MapPoint.add(left, right)
    return MapPoint.new(left.x + right.x, left.z + right.z)
end

-- 相减
function MapPoint.sub(left, right)
    return MapPoint.new(left.x - right.x, left.z - right.z)
end

-- 负号
function MapPoint.minus(self)
    return MapPoint.new(-self.x, -self.z)
end

-- 乘以一个数
function MapPoint.mul(self, a)
    return MapPoint.new(self.x * a, self.z * a)
end

-- 除以一个数
function MapPoint.div(self, a)
    error(a, "CCPoint division by 0.");
    return MapPoint.new(self.x / a, self.z / a)
end

-- 小于
function MapPoint.less(left, right)
    local a = left.x * 65536 + left.z
    local b = right.x * 65536 + right.z
    return (a < b)
end

-- 相等
function MapPoint.equals(left, right)
    local a = left.x * 65536 + left.z
    local b = right.x * 65536 + right.z
    return (a == b)
end

-- 对象值相等
function MapPoint.equalsObj(left, right)
    return (left.x == right.x and left.z == right.z)
end

function MapPoint:getMapPointVectorForDistance(lenght)
    local arrMPoint = {}
    local x = -lenght
    local z = -lenght
    while (true) do
        if (#arrMPoint == 8*lenght) then
            break
        end
        
        table.insert(arrMPoint, MapPoint.add(self, MapPoint.new(x, z)))
        
        if (#arrMPoint <= 2*lenght) then
            x = x + 1
        elseif (2*lenght < #arrMPoint and #arrMPoint <= 4*lenght) then
            z = z + 1
        elseif (4*lenght < #arrMPoint and #arrMPoint <= 6*lenght) then
            x = x - 1
        elseif (6*lenght < #arrMPoint and #arrMPoint < 8*lenght) then
            z = z - 1
        end
    end
    
    return arrMPoint
end

function MapPoint.setGridSize(size)
    GRID_SIZE = size
end

function MapPoint:getLength()
    return math.floor(math.max(math.abs(self.x), math.abs(self.z)))
end
    
function MapPoint:getDistance(mpoint)
    return math.floor(math.max(math.abs(mpoint.x - self.x), math.abs(mpoint.z - self.z)))
end


return MapPoint