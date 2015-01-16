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
    
    self.m_arrAction = {}
    
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
        
        display.addSpriteFrames(self.m_plistName, self.m_fileName, function(texture)
            self:initWithImageView(texture)
        end)
--        display.addImageAsync(self.m_fileName, function(texture)
--            -- local texture = cc.Director:getInstance():getTextureCache():getTextureForKey(self.m_fileName)
--            self:initWithImageView(texture)
--        end)
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
        self.m_arrAction = {}
    end
end

function NpcFigure:initWithImageView(texture)
    if (not self.m_sprite) then
        --cc.SpriteFrameCache:getInstance():addSpriteFrames(self.m_plistName, texture)
        
        self.m_sprite = cc.Sprite:create()
        self.m_sprite:setAnchorPoint(self.m_fAnchorPoint)
        self:addChild(self.m_sprite)
        
        self.m_spriteHigh = cc.Sprite:create()
        self.m_spriteHigh:setAnchorPoint(self.m_fAnchorPoint)
        self:addChild(self.m_spriteHigh)
        
        self.m_sprite:runAction(self:getActions())
        self.m_spriteHigh:runAction(self:getActions())
        
        self.m_spriteHigh:setVisible(false)
    end
end

function NpcFigure:IntelligentDisplay(rcShow, rcHide)
    local ptPos = cc.p(self:getPosition())
    
    if (cc.rectContainsPoint(rcShow, ptPos)) then
        self:displayImageView()
    end
    
    if (not cc.rectContainsPoint(rcHide, ptPos)) then
        self:hideImageView()
    end
end

function NpcFigure:getActions()
    if (#self.m_arrAction == 0) then
        local flag = 0
        while (true) do
            local frameName = string.format("npc_%u_1_%d_%02d.png", self.m_npcInfo.m_nRID, self.m_direction, flag)
            local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)
            if (not frame) then
                break
            end
            table.insert(self.m_arrAction, frame)
            flag = flag + 1
        end        
    end
    
    if (#self.m_arrAction > 0) then
        local animation = cc.Animation:createWithSpriteFrames(self.m_arrAction, 1 / 5)
        local animate = cc.Animate:create(animation)
        local repeatForever = cc.RepeatForever:create(animate)
        return repeatForever
    end
    
    return nil
end

function NpcFigure:setHighlight()
    if (self.m_spriteHigh:isVisible() == false) then
        self.m_spriteHigh:setBlendFunc(gl.DST_COLOR, gl.ONE)
        
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
    if (not cc.rectContainsPoint(self.m_fSpriteRect, point)) then
        return false
    end
    
    self:setHighlight()
    return true
end

function NpcFigure:onTouchMoved(event)
    if (not cc.rectContainsPoint(self.m_fSpriteRect, cc.p(event.x, event.y))) then
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