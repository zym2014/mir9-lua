-- 传送门精灵类
local PortalSprite = class("PortalSprite", function()
    return display.newSprite()
end)

function PortalSprite:ctor(path)
    self.m_path = path
    self.m_sprite = nil
    
    display.addSpriteFrames("texture_set/portal.plist", "texture_set/portal.png")
    self:init()
end

function PortalSprite:init()
    local size = cc.size(150, 60)
    self:setContentSize(size)
    
    self.m_sprite = cc.Sprite:create()
    self.m_sprite:setAnchorPoint(0.5, 0.3)
    self.m_sprite:setPosition(size.width/2, size.height/2)
    self:addChild(self.m_sprite)

    self:playAnimate()
    
    return true
end

-- 播放传送点动画
function PortalSprite:playAnimate()
    local i = 1
    local array = {}
    while (true) do
        local path = string.format("%s%04d.png", self.m_path, i)
        local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(path)
        if (not spriteFrame) then
            break
        end
        table.insert(array, spriteFrame)
        i = i + 1
    end
    local animation = cc.Animation:createWithSpriteFrames(array, 1 / 9)
    local animate = cc.Animate:create(animation)
    self.m_sprite:runAction(cc.RepeatForever:create(animate))
end

return PortalSprite