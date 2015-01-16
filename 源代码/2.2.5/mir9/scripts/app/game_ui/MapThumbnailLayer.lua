local MapPoint = require("app.map.MapPoint")

local centerPoint = cc.p(72, 93)
local lenght = 60
local scale = 1000

local function createIndicator(size)
    return display.newRect(size, size, {color = ccc4f(255,255,255,255), fill = true})
end

local MapThumbnailScrollView = class("MapThumbnailScrollView", cc.ui.UIScrollView)

function MapThumbnailScrollView:ctor(params)
    MapThumbnailScrollView.super.ctor(self, params)
    self.m_rcView = params.viewRect
    self.m_bIsMoved = false
    self.m_beginPoint = cc.p(0, 0)
    self:initWithMap()
end

function MapThumbnailScrollView:initWithMap()
    self:setAnchorPoint(0, 0)
    self:setBounceable(false)
    
    local texture = g_mainScene:getCurrBgMap():getSmallMap():getTexture()
    self.m_scrollNode = CCSprite:createWithTexture(texture)
    self.m_scrollNode:setAnchorPoint(0, 0)
    self.m_scrollNode:setPosition(0, 0)
    self:addScrollNode(self.m_scrollNode)
    
    self.m_pEndPoint = createIndicator(8)
    self.m_pEndPoint:setLineColor(ccc4f(255,255,0,255))
    self.m_scrollNode:addChild(self.m_pEndPoint)
    self.m_pEndPoint:setPosition(-100, -100)
    
    local blink = CCBlink:create(0.5, 1)
    local repeatForever = CCRepeatForever:create(blink)
    self.m_pEndPoint:runAction(repeatForever)
    
    self.m_playerIndicator = display.newSprite("ui/self_indicator.png")
    self.m_scrollNode:addChild(self.m_playerIndicator)

    local x = g_player:getPositionX() * self.m_scrollNode:getContentSize().width / g_mainScene:getCurrBgMap():getBgSize().width
    local y = g_player:getPositionY() * self.m_scrollNode:getContentSize().height / g_mainScene:getCurrBgMap():getBgSize().height
    x = x - self.m_rcView.width / 2
    y = y - self.m_rcView.height / 2
    x = math.min(x, self.m_scrollNode:getContentSize().width - self.m_rcView.width)
    x = math.max(x, 0)
    y = math.min(y, self.m_scrollNode:getContentSize().height - self.m_rcView.height)
    y = math.max(y, 0)
    self.m_scrollNode:setPosition(-x, -y)
    
    self:scheduleUpdate()
end

function MapThumbnailScrollView:update_(dt)
    MapThumbnailScrollView.super.update_(self, dt)
    
    local x = g_player:getPositionX() * self.m_scrollNode:getContentSize().width / g_mainScene:getCurrBgMap():getBgSize().width
    local y = g_player:getPositionY() * self.m_scrollNode:getContentSize().height / g_mainScene:getCurrBgMap():getBgSize().height
    self.m_playerIndicator:setPosition(x, y)
end

function MapThumbnailScrollView:onTouch_(event)
    MapThumbnailScrollView.super.onTouch_(self, event)
    
    if "began" == event.name and not self:isTouchInViewRect(event) then
        return false
    end

    if event.name == "began" then
        local bRet = self:onTouchBegan(event)
        self:setTouchSwallowEnabled(bRet)
        return bRet
    elseif event.name == "moved" then
        self:onTouchMoved(event)
    elseif event.name == "ended" then
        self:onTouchEnded(event)
    elseif event.name == "cancel" then
        self:onTouchCancelled(event)
    end
end

function MapThumbnailScrollView:onTouchBegan(event)
    self.m_beginPoint = cc.p(event.x, event.y)
    return true
end

function MapThumbnailScrollView:onTouchMoved(event)
    local point = cc.p(event.x, event.y)
    if (cc.PointDistance(self.m_beginPoint, point) < 5) then
        self.m_bIsMoved = true
    end
end

function MapThumbnailScrollView:onTouchEnded(event)
    if (self.m_bIsMoved) then
        self.m_bIsMoved = false
        return
    end

    local point = cc.p(event.x, event.y)
    local point = self.m_scrollNode:convertToNodeSpace(point)
    self.m_pEndPoint:setPosition(point)
    local x = point.x * g_mainScene:getCurrBgMap():getBgSize().width / self.m_scrollNode:getContentSize().width
    local y = point.y * g_mainScene:getCurrBgMap():getBgSize().height / self.m_scrollNode:getContentSize().height
        
    g_player:goTo(MapPoint.new(cc.p(x, y)))
end

local MapThumbnailLayer = class("MapThumbnailLayer", function()
    return display.newLayer()
end)

function MapThumbnailLayer:ctor()
    local bg = display.newSprite("ui/bg_map_layer.png")
    bg:setPosition(display.cx, display.cy)
    self:addChild(bg)
    
    local bound = cc.rect(0, 0, 600, 480)
    self.m_nMap = MapThumbnailScrollView.new({viewRect = bound})
    self.m_nMap:setPosition(43, 43)
    bg:addChild(self.m_nMap)
    
    local szBg = bg:getContentSize()
    local szBtn = cc.size(57, 58)
    
    local PUSH_BUTTON_IMAGES = {
        normal = "ui/closed_normal.png",
        pressed = "ui/closed_selected.png",
        disabled = "ui/closed_normal.png",
    }
    
    local btn = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
    btn:setButtonSize(szBtn.width, szBtn.height)
    local point = cc.PointAdd(cc.p(bg:getPosition()), cc.p(szBg.width/2, szBg.height/2))
    point = cc.PointSub(point, cc.p(szBtn.width/2, szBtn.height/2))
    btn:setAnchorPoint(0.5, 0.5)
    btn:setPosition(point)
    btn:onButtonClicked(handler(self, self.onBtn_Close))
    self:addChild(btn)
end

function MapThumbnailLayer:onBtn_Close(event)
    self:removeFromParent()
end



local MapThumbnailMenu = class("MapThumbnailMenu", function()
    return display.newSprite("ui/mapThumbnail.png")
end)

function MapThumbnailMenu:ctor()
    self.m_mapEnemySp = {}
    self.m_arrEnemyKey = {}

    local bg = display.newSprite("ui/bg_mapThumbnail.png")
    bg:setAnchorPoint(0, 0)
    self:addChild(bg, -2)

    self.m_playerIndicator = createIndicator(4)
    self.m_playerIndicator:setPosition(centerPoint)
    self:addChild(self.m_playerIndicator, -1)

    self.m_pCoordinateTTF = CCLabelTTF:create("", "Helvetica-Bold", 12)
    self.m_pCoordinateTTF:setPosition(centerPoint.x, 16)
    self:addChild(self.m_pCoordinateTTF)

    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "began" then
            local bRet = self:onTouchBegan(event)
            self:setTouchSwallowEnabled(bRet)
            return bRet
        elseif event.name == "moved" then
            self:onTouchMoved(event)
        elseif event.name == "ended" then
            self:onTouchEnded(event)
        elseif event.name == "cancel" then
            self:onTouchCancelled(event)
        end
    end)
    self:setTouchEnabled(true)
    
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(...)
        self:update_(...)
    end)
    self:scheduleUpdate()
end

function MapThumbnailMenu:update_(dt)
    local mapEnemy = g_mainScene:getEnemyDictionary()

    if (not mapEnemy) then
        return
    end

    for i = 1, #self.m_arrEnemyKey do
        local key = self.m_arrEnemyKey[i]
        local enemy = mapEnemy[key]
        if (not enemy) then
            local enemyIndicator = self.m_mapEnemySp[key]
            self.m_mapEnemySp[key] = nil
            enemyIndicator:removeFromParent()
        else
            local distance = cc.PointDistance(cc.p(g_player:getPosition()), cc.p(enemy:getPosition()))
            if (distance > scale) then
                local enemyIndicator = self.m_mapEnemySp[key]
                self.m_mapEnemySp[key] = nil
                enemyIndicator:removeFromParent()
            end             
        end
    end
    self.m_arrEnemyKey = {}
    for key, enemy in pairs(mapEnemy) do
        local distance = cc.PointDistance(cc.p(g_player:getPosition()), cc.p(enemy:getPosition()))
        if (distance <= scale) then
            table.insert(self.m_arrEnemyKey, key)
            local distanceX = enemy:getPositionX() - g_player:getPositionX()
            local distanceY = enemy:getPositionY() - g_player:getPositionY()
            local x = lenght * distanceX/scale + centerPoint.x
            local y = lenght * distanceY/scale + centerPoint.y
            local enemyIndicator = self.m_mapEnemySp[key]
            if (not enemyIndicator) then
                enemyIndicator = createIndicator(2)
                enemyIndicator:setLineColor(ccc4f(255,0,0,255))
                self:addChild(enemyIndicator, -1)
                self.m_mapEnemySp[key] = enemyIndicator
            end
            enemyIndicator:setPosition(x, y)
        end
    end
    local point = cc.p(g_player:getPositionX()/10, g_player:getPositionY()/10)
    local str = string.format("X:%03d     Y:%03d", point.x, point.y)
    self.m_pCoordinateTTF:setString(str)
end

function MapThumbnailMenu:onTouchBegan(event)
    local point = cc.p(event.x, event.y)
    point = self:convertToNodeSpace(point)

    if (cc.PointDistance(point, centerPoint) <= lenght) then
        return true
    end

    return false
end

function MapThumbnailMenu:onTouchMoved(event)

end

function MapThumbnailMenu:onTouchEnded(event)
    if (g_mainScene:getGameInfoUIController():getChildByTag(0xff00f)) then
        return
    end
    local map = MapThumbnailLayer.new()
    g_mainScene:getGameInfoUIController():addChild(map, 0, 0xff00f)
end

function MapThumbnailMenu:onTouchCancelled(event)

end

return MapThumbnailMenu