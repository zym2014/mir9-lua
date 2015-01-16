FairyType = {
    AddExp = 0,
    AddBlood = 1,
    SubBlood = 2,
    SubMagic = 3    
}

-- 飞舞的精灵类
local FlutteringFairy = class("FlutteringFairy", function()
    return display.newNode()
end)

function FlutteringFairy:ctor()

end

function FlutteringFairy.addFairy(parent, point, fairyType, value, callfunc)
    local fairy = FlutteringFairy.new()
    fairy:initWithFairy(fairyType, value, callfunc)
    fairy:setPosition(cc.PointAdd(cc.p(parent:getPosition()), point))
    parent:getParent():addChild(fairy, 10)
    --fairy:release()
    return fairy
end

function FlutteringFairy:initWithFairy(fairyType, value, callfunc)
    value = math.abs(value)
    
    local str = ""
    local color = ccc3(255,255,255)
    
    if (fairyType == FairyType.AddExp) then
        str = string.format("获得经验:%d", value)
        color = ccc3(255,255,0)
    elseif (fairyType == FairyType.AddBlood) then
        str = string.format("+%d", value)
        color = ccc3(0,255,0)
    elseif (fairyType == FairyType.SubBlood) then
        str = string.format("-%d", value)
        color = ccc3(255,0,0)
    elseif (fairyType == FairyType.SubMagic) then
        str = string.format("-%d", value)
        color = ccc3(25, 18, 112)
    end
    
    self.m_fairy = CCLabelTTF:create(str, "Helvetica-Bold", 30)
    self.m_fairy:setPosition(cc.p(0, 0))
    self:addChild(self.m_fairy)
    self.m_fairy:setColor(color)
    
    self.m_fairy:setScale(2.0)
    self.m_fairy:setOpacity(0)
    
    local fadeIn = cc.FadeIn:create(0.1)
    local scaleTo = cc.ScaleTo:create(0.2, 1.0)
    local array = CCArray:create()
    array:addObject(fadeIn)
    array:addObject(scaleTo)
    local spawn = cc.Spawn:create(array)
    local easeBack = cc.EaseSineOut:create(spawn)
    local delayTime = cc.DelayTime:create(0.3)
    local fadeOut = cc.FadeOut:create(0.2)
    local callFunc = cc.CallFunc:create(callfunc)
    local finish = cc.CallFunc:create(handler(self, self.removeFromParent))
    local array2 = CCArray:create()
    array2:addObject(easeBack)
    array2:addObject(delayTime)
    array2:addObject(fadeOut)
    array2:addObject(callFunc)
    array2:addObject(finish)
    local sequence = cc.Sequence:create(array2)
    self.m_fairy:runAction(sequence)
end

function FlutteringFairy:getContentSize()
    return self.m_fairy:getContentSize()
end

return FlutteringFairy