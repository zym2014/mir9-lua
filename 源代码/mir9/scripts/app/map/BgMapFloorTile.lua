
-- 背景地图地砖类
local BgMapFloorTile = class("BgMapFloorTile", function()
    return display.newNode()
end)

local OFF_SIZE = cc.p(128, 128)

function BgMapFloorTile:ctor()
    self.m_fileName = nil
    self.m_sprite = nil
    self.m_bIsDisplay = false
end

function BgMapFloorTile:displayImageView()
    if (self.m_bIsDisplay == false) then
        self.m_bIsDisplay = true
        display.addImageAsync(self.m_fileName, function()
            local texture = CCTextureCache:sharedTextureCache():textureForKey(self.m_fileName)
            self:initWithImageView(texture)
        end)
    end
end

function BgMapFloorTile:hideImageView()
    if (self.m_bIsDisplay) then
        self.m_bIsDisplay = false
        if (self.m_sprite) then
            self.m_sprite:removeFromParent()
            self.m_sprite = nil
        end
        CCTextureCache:sharedTextureCache():removeTextureForKey(self.m_fileName)
    end
end

function BgMapFloorTile:initWithImageView(texture)
    if (not self.m_sprite) then
        self.m_sprite = CCSprite:createWithTexture(texture)
        self.m_sprite:setAnchorPoint(cc.p(0, 0))
        self:addChild(self.m_sprite)
    end
end

function BgMapFloorTile:IntelligentDisplay(rcShow, rcHide)
--    local x, y = self:getPosition()
--    local point = cc.PointAdd(cc.p(x, y), OFF_SIZE)
    if (not self.m_tmpPos) then
        self.m_tmpPos = cc.p(0, 0)
    end
    
    self.m_tmpPos.x, self.m_tmpPos.y = self:getPosition()
    self.m_tmpPos.x = self.m_tmpPos.x +  OFF_SIZE.x
    self.m_tmpPos.y = self.m_tmpPos.y +  OFF_SIZE.y
    
    if (rcShow:containsPoint(self.m_tmpPos)) then
        self:displayImageView()
    end
    
    if (not rcHide:containsPoint(self.m_tmpPos)) then
        self:hideImageView()
    end
end

return BgMapFloorTile