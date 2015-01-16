-- 点击鼠标精灵类
local CCTouchMouse = class("CCTouchMouse", function()
    return display.newSprite()
end)

function CCTouchMouse:ctor()
    display.addSpriteFrames("ui/touch_mouse.plist", "ui/touch_mouse.png")
    self.m_arrEffect = {}
    local flag = 1
    while (true) do
        local frameName = string.format("touch_mouse_%02d.png", flag)
        local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)
        if (not frame) then
            break
        end
        table.insert(self.m_arrEffect, frame)
        flag = flag + 1
    end
end

function CCTouchMouse:playEffect(point)
    self:setVisible(true)
    self:setPosition(point)
    local animation = cc.Animation:createWithSpriteFrames(self.m_arrEffect, 1 / 15)
	local animate = cc.Animate:create(animation)
    local callFunc = cc.CallFunc:create(handler(self, self.setHide))
    local sequence = cc.Sequence:create(animate, callFunc)
    self:stopAllActions()
    self:runAction(sequence)
end

function CCTouchMouse:setHide()
    self:setVisible(false)
end

return CCTouchMouse