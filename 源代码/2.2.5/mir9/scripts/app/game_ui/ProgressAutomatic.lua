local scheduler = require("framework.scheduler")

local ProgressAutomatic = class("ProgressAutomatic", function(sprite)
    return CCProgressTimer:create(sprite)
end)

function ProgressAutomatic:ctor(sprite)
    local sprite2 = CCSprite:createWithTexture(sprite:getTexture())
    sprite2:setColor(ccc3(100, 100, 100))
    local szContent = self:getContentSize()
    sprite2:setPosition(szContent.width/2, szContent.height/2)
    self:addChild(sprite2, -1)
    
    self:setNodeEventEnabled(true)
end

function ProgressAutomatic:onExit()
    if (self.handle) then
        scheduler.unscheduleGlobal(self.handle)
        self.handle = nil
    end
end

function ProgressAutomatic:RunCoolingAction(fDelay)
    if (self:getPercentage() < 100.0) then
        return
    end

    self:setPercentage(0)
    self.m_fInterval = 100 / (fDelay * 60)
    if (self.handle) then
        scheduler.unscheduleGlobal(self.handle)
        self.handle = nil
    end
    self.handle = scheduler.scheduleGlobal(handler(self, self.updateCoolingAction), 0)
end

function ProgressAutomatic:updateCoolingAction(dt)
    local fPercentage = self:getPercentage()
    local percentage = fPercentage + self.m_fInterval
    self:setPercentage(percentage)
    if (percentage >= 100.0) then
        if (self.handle) then
            scheduler.unscheduleGlobal(self.handle)
            self.handle = nil
        end
    end
end

function ProgressAutomatic:RunCoolingNotAction(fDelay)
    if (self:getPercentage() < 100.0) then
        return
    end
    
    self:setPercentage(0)

    local delayTime = cc.DelayTime:create(fDelay)
    local callFunc = cc.CallFunc:create(handler(self, self.setCoolingFalse))
    local sequence = cc.Sequence:create(delayTime, callFunc, nil)
    self:runAction(sequence)
end

function ProgressAutomatic:setCoolingFalse()
    self:setPercentage(100)
end

return ProgressAutomatic