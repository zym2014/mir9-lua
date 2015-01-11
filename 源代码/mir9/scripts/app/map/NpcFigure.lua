local LAlertView = require("app.game_ui.LAlertView")

local NpcFigure = class("NpcFigure", function()
    return display.newSprite()
end)

function NpcFigure:ctor(roleNumber, direction)
    self.m_npcInfo = nil
    self.m_direction = direction
    
    self.m_sprite = nil
    self.m_bIsDisplay = false
    self.m_fAnchorPoint = cc.p(0.5, 3/8.0)
    self.m_fSpriteRect = cc.rect(80, 64, 50, 96)

    self.m_npcInfo = g_npcInfoSystem:getNpcInfo(roleNumber)
    self.m_fileName = string.format("texture_npc/npc_%u_1_%d.png", self.m_npcInfo.m_nRID, self.m_direction)
    self.m_plistName = string.format("texture_npc/npc_%u_1_%d.plist", self.m_npcInfo.m_nRID, self.m_direction)
    
    self.m_arrAction = CCArray:create()
    self.m_arrAction:retain()
    
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
end

function NpcFigure:displayImageView()
    if (not self.m_bIsDisplay) then
        self.m_bIsDisplay = true
        
        display.addImageAsync(self.m_fileName, function()
            local texture = CCTextureCache:sharedTextureCache():textureForKey(self.m_fileName)
            self:initWithImageView(texture)
        end)
    end
end

function NpcFigure:hideImageView()
    if (self.m_bIsDisplay) then
        self.m_bIsDisplay = false

        if (self.m_sprite) then
            self.m_sprite:removeFromParent()
            self.m_sprite = nil
        end
        
        display.removeSpriteFrameByImageName(self.m_fileName)
        self.m_arrAction:removeAllObjects()
    end
end

function NpcFigure:initWithImageView(texture)
    if (not self.m_sprite) then
        CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(self.m_plistName, texture)
        
        self.m_sprite = CCSprite:create()
        self.m_sprite:setAnchorPoint(self.m_fAnchorPoint)
        self:addChild(self.m_sprite)
        
        self.m_spriteHigh = CCSprite:create()
        self.m_spriteHigh:setAnchorPoint(self.m_fAnchorPoint)
        self:addChild(self.m_spriteHigh)
        
        self.m_sprite:runAction(self:getActions())
        self.m_spriteHigh:runAction(self:getActions())
        
        self.m_spriteHigh:setVisible(false)
    end
end

function NpcFigure:IntelligentDisplay(rcShow, rcHide)
    local ptPos = cc.p(self:getPosition())
    
    if (rcShow:containsPoint(ptPos)) then
        self:displayImageView()
    end
    
    if (not rcHide:containsPoint(ptPos)) then
        self:hideImageView()
    end
end

function NpcFigure:getActions()
    if (self.m_arrAction:count() == 0) then
        local flag = 0
        while (true) do
            local frameName = string.format("npc_%u_1_%d_%02d.png", self.m_npcInfo.m_nRID, self.m_direction, flag)
            local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(frameName)
            if (not frame) then
                break
            end
            self.m_arrAction:addObject(frame)
            flag = flag + 1
        end        
    end
    
    if (self.m_arrAction:count() > 0) then
        local animation = cc.Animation:createWithSpriteFrames(self.m_arrAction, 1 / 5)
        local animate = cc.Animate:create(animation)
        local repeatForever = cc.RepeatForever:create(animate)
        return repeatForever
    end
    
    return nil
end

function NpcFigure:setHighlight()
    if (self.m_spriteHigh:isVisible() == false) then
        local blendFunc = ccBlendFunc:new()                                                                          
        blendFunc.src = GL_DST_COLOR                                                                                       
        blendFunc.dst = GL_ONE
        self.m_spriteHigh:setBlendFunc(blendFunc)
        
        self.m_spriteHigh:setVisible(true)
    end
end

function NpcFigure:setNormal()
    if (self.m_spriteHigh:isVisible() == true) then        
        self.m_spriteHigh:setVisible(false)
    end
end

function NpcFigure:onTouchBegan(event)
    if (not self.m_sprite) then
        return false
    end
    
    local point = cc.p(event.x, event.y)
    point = self.m_sprite:convertToNodeSpace(point)
    if (not self.m_fSpriteRect:containsPoint(point)) then
        return false
    end
    
    self:setHighlight()
    return true
end

function NpcFigure:onTouchMoved(event)
    if (not self.m_fSpriteRect:containsPoint(cc.p(event.x, event.y))) then
        self:setNormal()
    else
        self:setHighlight()
    end
end

function NpcFigure:onTouchEnded(event)
    self:setNormal()
    
    local alertView = LAlertView.new("", self.m_npcInfo.m_sSentence)
    alertView:show(handler(self, self.alertCallBack))
end

function NpcFigure:onTouchCancelled(event)

end

function NpcFigure:alertCallBack(nBtnID)
    if (nBtnID == 0) then
        
    end
end

return NpcFigure