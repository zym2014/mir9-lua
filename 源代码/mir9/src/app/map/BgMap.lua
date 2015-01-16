local cjson = require("cjson")
local scheduler = require("framework.scheduler")
local BgMapFloorTile = require("app.map.BgMapFloorTile")
local PortalSprite = require("app.map.PortalSprite")
local MapPoint = require("app.map.MapPoint")
local NpcFigure = require("app.map.NpcFigure")

PortalInformation = class("PortalInformation")

function PortalInformation:ctor(key, mapID, born, point)
    self.key = key
    self.mapID = mapID
    self.born = born
    self.point = point
end

function PortalInformation:equals(other)
    return (self.key == other.key and 
        self.mapID == other.mapID and 
        self.born == other.born and 
        self.point.x == other.point.x and 
        self.point.y == other.point.y)
end

PortalInformationZero = PortalInformation.new(0, 0, 0, cc.p(0, 0))

local NpcInformation = class("NpcInformation")

function NpcInformation:ctor(key, direction, point)
    self.key = key
    self.direction = direction 
    self.point = point
end

function NpcInformation:equals(other)
    return  (self.key == other.key and 
        self.direction == other.direction and
        self.point.equals(other.point))
end
    
NPCDirection = {
    DownAndLeft     = 5,
    Down            = 4,
    RightAndDown    = 3
}

local OFF_SIZE = cc.p(128, 128)

-- 背景地图类
local BgMap = class("BgMap", function()
    return display.newNode()
end)

local RADIUS_PASSAGEWAY = 64

local TYPE_PROTAL = 100
local TYPE_BORN_POINT = 101
local TYPE_NPC = 200
local TYPE_ENEMY = 300
local TYPE_BACKGROUND_MUSIC = 400

function BgMap:ctor()
    self.m_gridRow = 0
    self.m_gridCol = 0
    self.m_gridSize = cc.size(0, 0)
    self.m_imageRow = 0
    self.m_imageCol = 0
    self.m_imageSize = cc.size(0, 0)
    self.m_bgSize = cc.size(0, 0)
    self.m_nMapID = 0
    self.m_playerLead = nil
    self.m_delegate = nil

    self.m_grid = {}
        
    self.m_arrPassageway = {}
    self.m_mapBornPoint = {}
    self.m_arrNpcInfo = {}
    self.m_arrEnemy = {}

    self.m_arrFloorTile = {}
    self.m_arrNpcFigure = {}
end

-- 加载地图
function BgMap:loadMap(nMapID)
    self.m_nMapID = nMapID
    
    self:readGirdData()
    self:readGoodsData()

    local path = string.format("map/s%d/min_s%d.jpg", self.m_nMapID, self.m_nMapID)
    self.m_spMap = display.newSprite(path)
    self.m_spMap:setAnchorPoint(cc.p(0, 0))
    self:addChild(self.m_spMap, BgMap.getZOrderZero(self))
    self.m_spMap:setScale(10/3.0)

    self:initBgMapFloorTile()
    self:initBgMapPassagewayImage()
    self:initNpcFigure()

    self:updateImageDisplay()

    --    if (self.m_backGroundMusic ~= "") then
    --        audio.playMusic(self.m_backGroundMusic, true)
    --        --audio.setBackgroundMusicVolume(0.2)
    --    end    
end

-- 卸载地图
function BgMap:unloadMap()
    self:killTimer_UpdateMap()
    self:setDelegate(nil)
    CCTextureCache:sharedTextureCache():removeUnusedTextures()
end

function BgMap:readGirdData()
    local path = string.format("map/s%d/data_gird_%d.json", self.m_nMapID, self.m_nMapID)
    local json_str = cc.FileUtils:getInstance():getStringFromFile(path)
    local json_value = cjson.decode(json_str)
    
    -- 地图宽高
    local width = json_value["mapW"]
    local height = json_value["mapH"]
    self.m_bgSize = cc.size(width, height)
    
    -- 
    local gWidth = json_value["mapGridW"]
    local gHeight = json_value["mapGridH"]
    self.m_gridSize = cc.size(gWidth, gHeight)
    MapPoint.setGridSize(self.m_gridSize)
    self.m_gridRow = math.ceil(width/self.m_gridSize.width)
    self.m_gridCol = math.ceil(height/self.m_gridSize.height)
    
    self:initGridData(json_value["mapFlagArr"])
    
    -- 切图宽高
    local iWidth = json_value["divideBlockW"]
    local iHeight = json_value["divideBlockH"]
    self.m_imageSize = cc.size(iWidth, iHeight)
    self.m_imageRow = math.ceil(width/self.m_imageSize.width)
    self.m_imageCol = math.ceil(height/self.m_imageSize.height)
end

function BgMap:readGoodsData()
    local path = string.format("map/s%d/data_goods_%d.json", self.m_nMapID, self.m_nMapID)
    local json_str = cc.FileUtils:getInstance():getStringFromFile(path)
    local json_value = cjson.decode(json_str)
        
    for i = 1, #json_value["items"] do
        local goods = json_value["items"][i]
        
        local itemType = goods["itemType"]
        if (itemType == TYPE_PROTAL) then   -- 传送点
            local key = goods["itemSN"]
            local mapID = goods["portalToMap"]
            local born = goods["portalToPos"]
            local point = cc.p(goods["itemPosX"], goods["itemPosY"])
            local info = PortalInformation.new(key, mapID, born, point)
            table.insert(self.m_arrPassageway, info)
        elseif (itemType == TYPE_BORN_POINT) then   -- 
            local born = goods["itemSN"]
            local point = cc.p(goods["itemPosX"], goods["itemPosY"])
            self.m_mapBornPoint[born] = point
        elseif (itemType == TYPE_NPC) then  -- NPC
            local key = goods["itemSN"]
            local direction = goods["npcDirection"]
            if (not direction) then
                direction = NPCDirection.Down
            end
            local point = cc.p(goods["itemPosX"], goods["itemPosY"])
            local info = NpcInformation.new(key, direction, point)
            table.insert(self.m_arrNpcInfo, info)
        elseif (itemType == TYPE_ENEMY) then    -- 敌人
            local key = goods["itemSN"]
            local mpoint = MapPoint.new(cc.p(goods["itemPosX"], goods["itemPosY"]))
            table.insert(self.m_arrEnemy, {["key"] = key, ["mpoint"] = mpoint})
        elseif (itemType == TYPE_BACKGROUND_MUSIC) then -- 背景音乐        
            local key = goods["itemSN"]
            self.m_backGroundMusic = string.format("music/400/%d.mp3", key)
        end
    end
end

function BgMap:initGridData(json_value)
    -- self.m_grid = json_value
    
    for i = 0, self.m_gridCol-1 do
        self.m_grid[i] = {}
    end
    
    for i = 0, #json_value-1 do
        self.m_grid[math.floor(i/self.m_gridRow)][i%self.m_gridRow] = json_value[i+1]
    end
end

function BgMap:initBgMapFloorTile()
    for i = 0, self.m_imageCol-1 do
        for j = 0, self.m_imageRow-1 do
            local floorTile = BgMapFloorTile.new()
            local path = string.format("map/s%d/s%d_%d_%d.jpg", self.m_nMapID, self.m_nMapID, i, j)
            floorTile.m_fileName = path

            floorTile:setPosition(self.m_imageSize.width*j, self.m_imageSize.height*i)
            self:addChild(floorTile, BgMap.getZOrderZero(self)) -- z轴
            table.insert(self.m_arrFloorTile, floorTile)
        end
    end
end

function BgMap:initBgMapPassagewayImage()
    for i = 1, #self.m_arrPassageway do
        local point = self.m_arrPassageway[i].point
        point = MapPoint.new(point):getCCPointValue()
        
        -- 生成传送门
        local value = BgMap.getZOrder(point) -- z轴
        
        local sprite = PortalSprite.new("trans-")
        sprite:setPosition(point)
        self:addChild(sprite, value)
    end
end

function BgMap:initNpcFigure()
    for i = 1, #self.m_arrNpcInfo do
        local npc = NpcFigure.new(self.m_arrNpcInfo[i].key, self.m_arrNpcInfo[i].direction)
        npc:setPosition(self.m_arrNpcInfo[i].point)
        self:addChild(npc, BgMap.getZOrder(cc.p(npc:getPosition())))
        
        table.insert(self.m_arrNpcFigure, npc)
    end
end

function BgMap:updateImageDisplay()
    local rect = self:getShowRect()
    local rect2 = self:getHideRect()
    
    local nStartX = math.floor(rect.x / self.m_imageSize.width)
    local nStartY = math.floor(rect.y / self.m_imageSize.height)
    nStartX = math.max(nStartX, 0)
    nStartY = math.max(nStartY, 0)
    
    local nEndX = math.ceil((rect.x+rect.width) / self.m_imageSize.width)
    local nEndY = math.ceil((rect.y+rect.height) / self.m_imageSize.height)
    nEndX = math.min(nEndX, self.m_imageRow-1)
    nEndY = math.min(nEndY, self.m_imageCol-1)
    
    for i = nStartY, nEndY do
        for j = nStartX, nEndX do
            self.m_arrFloorTile[i*self.m_imageRow+j+1]:IntelligentDisplay(rect, rect2)
        end
    end
        
    -- 显示地砖
--    for i = 1, #self.m_arrFloorTile do
--        self.m_arrFloorTile[i]:IntelligentDisplay(rect, rect2)
--    end
    
    -- 显示NPC
    for i = 1, #self.m_arrNpcFigure do
        self.m_arrNpcFigure[i]:IntelligentDisplay(rect, rect2)
    end
    
    if (self.m_delegate) then
        self.m_delegate:updateImageDisplay(rect, rect2)
    end
    
--    CCTextureCache:sharedTextureCache():removeUnusedTextures()
end

-- 更新地图计时器回调函数
function BgMap:updateMap(fDelay)
    if (not self.m_playerLead) then
        return
    end

    local x, y = self.m_playerLead:getPosition()
    local pMap = cc.pSub(cc.p(display.cx, display.cy), cc.p(x, y))
    
    pMap.x = math.max(pMap.x, display.width-self.m_bgSize.width)
    pMap.y = math.max(pMap.y, display.height-self.m_bgSize.height)
    pMap.x = math.min(pMap.x, 0)
    pMap.y = math.min(pMap.y, 0)
    
    self:setPosition(pMap)
    
    self:updateImageDisplay()
end

function BgMap:getCurrentGridValue(mpoint)
    local row = mpoint.x
    local col = mpoint.z
    local relust = 1
    
    if (1 < col and col < self.m_gridCol-1 and 1 < row and row < self.m_gridRow-1) then
        relust = self.m_grid[col][row]
    end
    
    return relust
end

function BgMap:isMapPassageway(node)
    for i = 1, #self.m_arrPassageway do
        local mapPassageway = self.m_arrPassageway[i]
        if (cc.pGetDistance(mapPassageway.point, cc.p(node:getPosition())) <= RADIUS_PASSAGEWAY) then
            return mapPassageway
        end
    end
    return PortalInformationZero
end

function BgMap:getEnemeyMap()
    return self.m_arrEnemy
end

function BgMap:addChildPlayerLead(node, bornPoint)
    local point = self.m_mapBornPoint[math.floor(bornPoint)]
    point = MapPoint.new(point):getCCPointValue()
    self:addChildPlayerLead_(node, point)
end

function BgMap:addChildPlayerLead_(node, point)
    local x, y = self:getPosition()
    local value = BgMap.getZOrder(cc.p(x, y))  -- z轴
    self.m_playerLead = node
    point = MapPoint.new(point)
    point = point:getCCPointValue()
    self.m_playerLead:setPosition(point)
    self:addChild(self.m_playerLead, value)
    self:updateMap()
end

function BgMap:getShowRect()
--    local rect = cc.rect(0, 0, 0, 0)
--    rect.origin = cc.PointSub(cc.p(0, 0), OFF_SIZE)
--    rect.origin = cc.PointSub(rect.origin, cc.p(self:getPosition()))
--    local point = cc.PointAdd(cc.p(display.width, display.height), cc.p(OFF_SIZE.x*2, OFF_SIZE.y*2))
--    rect.size = cc.size(point.x, point.y) 
--    return rect
    
    if (not self.m_tmpRect) then
        self.m_tmpRect = cc.rect(0, 0, 0, 0)
    end
        
    self.m_tmpRect.x = 0 - OFF_SIZE.x
    self.m_tmpRect.y = 0 - OFF_SIZE.y
    self.m_tmpRect.x = self.m_tmpRect.x - self:getPositionX()
    self.m_tmpRect.y = self.m_tmpRect.y - self:getPositionY()
    self.m_tmpRect.width = display.width + OFF_SIZE.x*2
    self.m_tmpRect.height = display.height + OFF_SIZE.y*2
    
    return self.m_tmpRect
end

function BgMap:getHideRect()
--    local rect = cc.rect(0, 0, 0, 0)
--    rect.origin = cc.PointSub(cc.p(0, 0), cc.p(OFF_SIZE.x * 2, OFF_SIZE.y * 2))
--    rect.origin = cc.PointSub(rect.origin, cc.p(self:getPosition()))
--    local point = cc.PointAdd(cc.p(display.width, display.height), cc.p(OFF_SIZE.x*4, OFF_SIZE.y*4))
--    rect.size = cc.size(point.x, point.y) 
--    return rect

    if (not self.m_tmpRect) then
        self.m_tmpRect = cc.rect(0, 0, 0, 0)
    end

    self.m_tmpRect.x = 0 - OFF_SIZE.x * 2
    self.m_tmpRect.y = 0 - OFF_SIZE.y * 2
    self.m_tmpRect.x = self.m_tmpRect.x - self:getPositionX()
    self.m_tmpRect.y = self.m_tmpRect.y - self:getPositionY()
    self.m_tmpRect.width = display.width + OFF_SIZE.x*4
    self.m_tmpRect.height = display.height + OFF_SIZE.y*4
    return self.m_tmpRect    
end

function BgMap.getZOrder(point)
    return (-point.y / 10.0)
end
    
function BgMap.getZOrderZero(bgMap)
    return (-bgMap.m_bgSize.height / 10.0)
end

function BgMap:setDelegate(delegate)
    self.m_delegate = delegate
end

function BgMap:getMapGrid()
    return self.m_grid
end

function BgMap:getGridRow()
    return self.m_gridRow
end

function BgMap:getGridCol()
    return self.m_gridCol
end

-- 开启更新地图计时器
function BgMap:setTimer_UpdateMap()
    self:killTimer_UpdateMap()
    self.hUpdateMap = scheduler.scheduleGlobal(handler(self, self.updateMap), 0.01)
end

-- 关闭更新地图计时器
function BgMap:killTimer_UpdateMap()
    if (self.hUpdateMap) then
        scheduler.unscheduleGlobal(self.hUpdateMap)
        self.hUpdateMap = nil
    end
end

function BgMap:getSmallMap()
    return self.m_spMap
end

function BgMap:getBgSize()
    return self.m_bgSize
end

return BgMap