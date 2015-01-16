-- 点击鼠标精灵类
local CCTouchMouse = class("CCTouchMouse", function()
    return display.newSprite()
end)

function CCTouchMouse:ctor()
    self.m_effectArray = CCArray:create()
    self.m_effectArray:retain()
    display.addSpriteFramesWithFile("ui/touch_mouse.plist", "ui/touch_mouse.png")
    if (self.m_effectArray:count() == 0) then
        local flag = 1
        while (true) do
            local frameName = string.format("touch_mouse_%02d.png", flag)
            local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(frameName)
            if (not frame) then
                break
            end
            self.m_effectArray:addObject(frame)
            flag = flag + 1
        end
    end
end

function CCTouchMouse:playEffect(point)
    self:setVisible(true)
    self:setPosition(point)
	local animation = cc.Animation:createWithSpriteFrames(self.m_effectArray, 1 / 15)
	local animate = cc.Animate:create(animation)
    local callFunc = cc.CallFunc:create(handler(self, self.setHide))
    local array = CCArray:create()
    array:addObject(animate)
    array:addObject(callFunc)
    local sequence = cc.Sequence:create(array)
    self:stopAllActions()
    self:runAction(sequence)
end

function CCTouchMouse:setHide()
    self:setVisible(false)
end

return CCTouchMouse