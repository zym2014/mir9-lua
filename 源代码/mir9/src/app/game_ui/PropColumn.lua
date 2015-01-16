local MapPoint = require("app.map.MapPoint")
local BgMap = require("app.map.BgMap")
local PropIconShow = require("app.prop_system.PropIconShow")

local GRID_WIDTH = 39
local GRID_HEIGHT = 35
local PROP_X = 88
local PROP_Y = 80
local COL = 10
local ROW = 6

local PropColumnMenu = class("PropColumnMenu", function()
    return display.newLayer()
end)

function PropColumnMenu:ctor()
    self.m_className = "PropColumnMenu"
    self.m_editProp = nil
    self.m_propVec = {}
    self:init()
end

function PropColumnMenu:onEnter()
    self:updatePropVecPoint()
end

function PropColumnMenu:init()
    local bg = display.newSprite("ui/prop_column.png")
    self:addChild(bg)
    
    self.m_propColumn = cc.LayerColor:create(cc.c4b(255, 255, 255, 0), GRID_WIDTH*COL, GRID_HEIGHT*ROW)
    self.m_propColumn:setContentSize(GRID_WIDTH*COL, GRID_HEIGHT*ROW)
    self.m_propColumn:setPosition(PROP_X, PROP_Y)
    bg:addChild(self.m_propColumn)
    
    local ptBg = cc.p(bg:getPosition())
    local szBg = bg:getContentSize()
    local szBtn = cc.size(57, 58)
    
    local PUSH_BUTTON_IMAGES = {
        normal = "ui/closed_normal.png",
        pressed = "ui/closed_selected.png",
        disabled = "ui/closed_normal.png",
    }

    local btn = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
    btn:setButtonSize(szBtn.width, szBtn.height)
    local ptBtn = cc.pAdd(ptBg, cc.p(szBg.width/2, szBg.height/2))
    ptBtn = cc.pSub(ptBtn, cc.p(szBtn.width/2, szBtn.height/2))
    btn:setPosition(ptBtn)
    btn:setAnchorPoint(0.5, 0.5)
    btn:onButtonClicked(handler(g_mainScene:getGameInfoUIController(), g_mainScene:getGameInfoUIController().removeSmallMenuAndButton))
    self:addChild(btn)
    
    for i = 1, 12 do
        self.m_propVec[i-1] = PropIconShow.new(g_propSystem:getPropInfo(i))
        self.m_propColumn:addChild(self.m_propVec[i-1])
    end

    self:updatePropVecPoint()
    
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "began" then
            local bRet = self:onTouchBegan(event)
            local rect = bg:getBoundingBox()
            local pt = bg:convertToNodeSpace(cc.p(event.x, event.y))
            --print("==============", rect.x, rect.y, rect.width, rect.height, pt.x, pt.y)
            if (cc.rectContainsPoint(bg:getBoundingBox(), pt)) then
                self:setTouchSwallowEnabled(true)
            else
                self:setTouchSwallowEnabled(false)
            end
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
    
    return true
end

function PropColumnMenu:updatePropVecPoint()
    for j = 0, ROW-1 do
        for i = 0, COL-1 do
            if (self.m_propVec[j*COL+i]) then
                self.m_propVec[j*COL+i]:setPosition(GRID_WIDTH * (i+0.5), GRID_HEIGHT * (ROW-j-0.5))
            end
        end
    end
end

function PropColumnMenu:getPropRect(i)
    local rect = cc.rect(0,0,0,0)
    local x = math.floor(i % COL)
    local y = math.floor(i / COL)
    rect.x, rect.y = GRID_WIDTH * x, GRID_HEIGHT * (ROW-y-1)
    local pt = self.m_propColumn:convertToWorldSpace(cc.p(rect.x, rect.y))
    rect.x, rect.y = pt.x, pt.y
    rect.width, rect.height = GRID_WIDTH, GRID_HEIGHT
    return rect
end

function PropColumnMenu:getPropPoint(i)
    local x = math.floor(i % COL)
    local y = math.floor(i / COL)
    return cc.p(GRID_WIDTH * (x+0.5), GRID_HEIGHT * (ROW-y-0.5))
end

function PropColumnMenu:propHoming(i)
    if (i < COL*ROW and self.m_propVec[i]) then
        local point = self:getPropPoint(i)
        self.m_propVec[i]:setPosition(point)
    end
end

function PropColumnMenu:swapProp(a, b)
    if (a < COL*ROW and b < COL*ROW) then
        local tmp = self.m_propVec[a]
        self.m_propVec[a] = self.m_propVec[b]
        self.m_propVec[b] = tmp
    end
    
    self:propHoming(a)
    self:propHoming(b)
end

function PropColumnMenu:onTouchBegan(event)
    local point = cc.p(event.x, event.y)
    
    local rect = cc.rect(0,0,0,0)
    local pt = self.m_propColumn:convertToWorldSpace(cc.p(0,0))
    rect.x, rect.y = pt.x, pt.y
    local size = self.m_propColumn:getContentSize()
    rect.width, rect.height = size.width, size.height
    
    if (not cc.rectContainsPoint(rect, point)) then
        return false
    end

    for i = 0, COL*ROW-1 do
        if (self.m_propVec[i] and cc.rectContainsPoint(self:getPropRect(i), point)) then
            self.m_propVec[i]:setVisible(false)
            self.m_editProp = PropIconShow.new(self.m_propVec[i].m_propInfo)
            self.m_editProp:setPosition(point)
            g_mainScene:getGameInfoUIController():addChild(self.m_editProp)
            self.m_editProp:setTag(i)
            self.m_editProp:setOpacity(127)
            break
        end
    end
    
    if (not self.m_editProp) then
        return false
    end

    return true
end

function PropColumnMenu:onTouchMoved(event)
    local point = cc.p(event.x, event.y)
    
    self.m_editProp:setPosition(point)
    
    local btn = g_mainScene:getGameInfoUIController():getOperationMenu():getDrugsBtn()
    
    local rect = cc.rect(0,0,0,0)
    local pt = btn:convertToWorldSpace(cc.p(0,0))
    rect.x, rect.y = pt.x, pt.y
    local size = btn:getContentSize()
    rect.width, rect.height = size.width, size.height
    if (cc.rectContainsPoint(rect, point)) then
        if (self.m_editProp:getOpacity() == 255) then
            return
        end
        self.m_editProp:setOpacity(255)
        btn:stopAllActions()
        local scaleTo = cc.ScaleTo:create(0.1, 1.1)
        btn:runAction(scaleTo)
    else
        if (self.m_editProp:getOpacity() == 127) then
            return
        end
        self.m_editProp:setOpacity(127)
        btn:stopAllActions()
        local scaleTo = cc.ScaleTo:create(0.1, 1.0)
        btn:runAction(scaleTo)
    end
end

function PropColumnMenu:onTouchEnded(event)
    local point = cc.p(event.x, event.y)
    
    local rect = cc.rect(0,0,0,0)
    local pt = self.m_propColumn:convertToWorldSpace(cc.p(0,0))
    rect.x, rect.y = pt.x, pt.y
    local size = self.m_propColumn:getContentSize()
    rect.width, rect.height = size.width, size.height
    
    if (cc.rectContainsPoint(rect, point)) then
        point = self.m_propColumn:convertToNodeSpace(point)
        local x = math.floor(point.x / GRID_WIDTH)
        local y = math.floor(point.y / GRID_HEIGHT)
        y = ROW - y - 1
        self.m_propVec[self.m_editProp:getTag()]:setVisible(true)
        self:swapProp(self.m_editProp:getTag(), y*COL+x)
    else
        if (self.m_editProp:getOpacity() == 255) then
            g_mainScene:getGameInfoUIController():getOperationMenu():addDrugs(2001)
            local btn = g_mainScene:getGameInfoUIController():getOperationMenu():getDrugsBtn()
            btn:stopAllActions()
            local scaleTo = cc.ScaleTo:create(0.1, 1.0)
            btn:runAction(scaleTo)
            self.m_propVec[self.m_editProp:getTag()]:removeFromParent()
            self.m_propVec[self.m_editProp:getTag()] = nil
        else
            local r = math.random()
            if (r == 1) then
                r = 0
            end
            
            local bgMap = g_mainScene:getCurrBgMap()
            local playerPosition = MapPoint.new(cc.p(g_player:getPosition()))
            
            local ptZero = MapPoint.new(0, 0)
            local point = ptZero
            local mapVec = {}
            local lenght = 1
            while (true) do
                mapVec = playerPosition:getMapPointVectorForDistance(lenght)
                local index = 0
                for index = 1, #mapVec do
                    if (not g_mainScene:getMapPointForProp(mapVec[index])) then
                        point = mapVec[index]
                    end
                end
                
                if (not point:equalsObj(ptZero)) then
                    break
                end
                
                lenght = lenght + 1 
            end
            
            local show = self.m_propVec[self.m_editProp:getTag()]
            self.m_propVec[self.m_editProp:getTag()] = nil
            show:setVisible(true)
            show:retain()
            show:removeFromParent()
            show:setPosition(point:getCCPointValue())
            bgMap:addChild(show, BgMap.getZOrderZero(bgMap))
            show:release()
            show:setScale(0.8)

            g_mainScene:insterMapPointForProp(show, point)
            
            show:setOpacity(0)
            local fadeIn = cc.FadeIn:create(0.1)
            local jumpBy = cc.JumpBy:create(0.3, cc.p(0, 0), 30, 1)
            local spawn = cc.Spawn:create(fadeIn, jumpBy)
            show:runAction(spawn)
        end
    end
    self.m_editProp:removeFromParent()
    self.m_editProp = nil
end

function PropColumnMenu:onTouchCancelled(event)

end

return PropColumnMenu