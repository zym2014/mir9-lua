local scheduler = require("framework.scheduler")
local BgMap = require("app.map.BgMap")
local GameSocket = require("app.GameSocket")
local TextureController = require("app.figure.TextureController")

-- 技能特效显示类
local SkillEffectShow = class("SkillEffectShow", function()
    return display.newNode()
end)

function SkillEffectShow:ctor(skillInfo, fHitDelay)
    self.m_skillInfo = skillInfo
    self.m_attacker = nil
    self.m_victim = nil
    self.m_spShow = nil
    self.m_spExplosion = nil
    self.m_spTail = nil
    self.m_fHitDelay = fHitDelay
    
    self.m_attacker = display.newNode()
    self.m_victim = display.newNode()
    
    self:setNodeEventEnabled(true)
end

function SkillEffectShow:onEnter()
    
end

function SkillEffectShow:onExit()
    if (self.m_attacker:getParent()) then
        self.m_attacker:removeFromParent()
    end
    if (self.m_victim:getParent()) then
        self.m_victim:removeFromParent()
    end
end

function SkillEffectShow.playSkillEffect(skillInfo, attacker, victim, fHitDelay)
    local skillEffectShow = SkillEffectShow.new(skillInfo, fHitDelay)
    if (skillEffectShow and skillEffectShow:init(attacker, victim)) then
        g_mainScene:getCurrBgMap():addChild(skillEffectShow)
        -- skillEffectShow:release()
        return skillEffectShow
    end
    return nil
end

function SkillEffectShow:init(attacker, victim)    
    if (not attacker or not victim) then
        return false
    end
    
    attacker:addChild(self.m_attacker)
    victim:addChild(self.m_victim)
    
    self:initWithShowSprite()
    
    if (self.m_skillInfo.m_casterSpecificID ~= 0) then
        local path = TextureController.getTexturePath(TexturePathType.SkillCaster, self.m_skillInfo.m_casterSpecificID)
        self:playCasterSpecific(path)
    end

    scheduler.performWithDelayGlobal(handler(self, self.emission), self.m_fHitDelay)
    
    return true
end

function SkillEffectShow:initWithShowSprite()
    self.m_spShow = cc.Sprite:create()
    self.m_spShow:setPosition(self.m_attacker:getParent():getHandPoint())
    g_mainScene:getCurrBgMap():addChild(self.m_spShow)
end

function SkillEffectShow:playCasterSpecific(path)
    local figure = self.m_attacker:getParent():getFigure()
    
    local spWeapon = figure:getWeaponSprite()
    if (not spWeapon) then
        return
    end
    
    local sprite = cc.Sprite:create()
    local szWeapon = spWeapon:getContentSize()
    sprite:setPosition(szWeapon.width/2, szWeapon.height/2)
    szWeapon:addChild(sprite)
    
    local array = {}
    local flag = 0
    
    while (true) do
        local frameName = string.format("%s_%d0_%02d.png", path, figure:getDirection(), flag)
        local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)
        if (not spriteFrame) then
            break
        end
        table.insert(array, spriteFrame)
        flag = flag + 1
    end
    
    if (#array > 0) then
        local animation = cc.Animation:createWithSpriteFrames(array, 1 / 10)
        local animate = cc.Animate:create(animation)
        local callFunc = cc.CallFunc:create(handler(self, self.removeFromParent))
        local Sequence = cc.Sequence:create(animate, callFunc, nil)
        sprite:runAction(Sequence)
    else
        sprite:removeFromParent()
    end
end

function SkillEffectShow:emission(fDelay)
    self.hTrack = scheduler.scheduleGlobal(handler(self, self.track), 0)
    
    if (self.m_skillInfo.m_locusSpecificID ~= 0) then
        local path = TextureController.getTexturePath(TexturePathType.SkillLocus, self.m_skillInfo.m_locusSpecificID)
        self:playLocusSpecific(path)
        
        if (self.m_skillInfo.m_isTailing) then
            self:playTailing()
        end
    end
end

function SkillEffectShow:track(fDelay)
    local speed = self.m_skillInfo.m_flightSpeed / 60.0
    
    if (self.m_skillInfo.m_flightSpeed == 0) then
        speed = 0xffffffff
    end
    
    local lenght = cc.pGetDistance(cc.p(self.m_spShow:getPosition()), self:getDestination())
    local lenghtX = self:getDestination().x - self.m_spShow:getPositionX()
    local lenghtY = self:getDestination().y - self.m_spShow:getPositionY()
    local x = self.m_spShow:getPositionX() + speed * lenghtX / lenght
    local y = self.m_spShow:getPositionY() + speed * lenghtY / lenght
    local point = cc.p(x, y)
    
    if (lenght <= 64) then
        self.m_spShow:setVisible(false)
    end
    
    if (cc.pGetDistance(point, self:getDestination()) > speed) then
        self.m_spShow:setPosition(point)
        local high = self.m_attacker:getParent():getHandPointRelativeFootOffset()
        self.m_spShow:setLocalZOrder(BgMap.getZOrder(cc.pSub(point, high)) + 1)
    else
        self.m_spShow:setPosition(self:getDestination())
        if (self.hTrack) then
            scheduler.unscheduleGlobal(self.hTrack)
            self.hTrack = nil
        end
        self:hit()
    end
end

function SkillEffectShow:hit()
    if (self.m_skillInfo.m_explosionSpecificID ~= 0) then
        local path = TextureController.getTexturePath(TexturePathType.SkillExplosion, self.m_skillInfo.m_explosionSpecificID)
        self:playExplosionSpecific(path)
    else
        self:sendMessage()
        self:releaseThis()
    end
end

function SkillEffectShow:updateTailing(fDelay)
    local lenght = cc.pGetDistance(self:getDeparture(), cc.p(self.m_spShow:getPosition()))
    local lenghtX = self.m_spShow:getPositionX() - self:getDeparture().x
    local lenghtY = self.m_spShow:getPositionY() - self:getDeparture().y
    
    local angle_X = math.asin(lenghtY / lenght) * 180 / math.pi
    local angle_Y = math.asin(lenghtX / lenght) * 180 / math.pi

    local rotation = 0
    
    if (angle_X >= 0) then
        rotation = angle_Y - 90
    else
        rotation = 90 - angle_Y
    end
    
    local preferredSize = cc.size(0, 0)
    
    if (lenght < 30) then
        preferredSize.width = 0
    else
        preferredSize.width = lenght - 30
    end
    
    preferredSize.height = 5
    
    self.m_spTail:setPreferredSize(preferredSize)

    self.m_spTail:setRotation(rotation)
end

-- 播放拖尾特效
function SkillEffectShow:playTailing()
    self.m_spTail = CCScale9Sprite:create("ui/red.png")
    self.m_spTail:setPreferredSize(cc.size(0, 0))
    self.m_spTail:setAnchorPoint(1, 0.5)
    self.m_spTail:setPosition(0, 0)
    self.m_spShow:addChild(self.m_spTail, -1)
    
    self.hUpdateTailing = scheduler.scheduleGlobal(handler(self, self.updateTailing), 0)
end

function SkillEffectShow:playLocusSpecific(path)
    local rotation = self:getRotationWithLocusSpecific()
    
    local flag = 0
    
    local array = {}
    while (true) do
        local frameName = string.format("%s_%d_%02d.png", path, rotation, flag)
        local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)
        if (not spriteFrame) then
            break
        end
        table.insert(array, spriteFrame)
        flag = flag + 1
    end
    
    if (#array > 0) then
        local animation = cc.Animation:createWithSpriteFrames(array, 1 / 24)
        local animate = cc.Animate:create(animation)
        local repeatForever = cc.RepeatForever:create(animate)
        self.m_spShow:runAction(repeatForever)
    end
end

function SkillEffectShow:playExplosionSpecific(path)
    self.m_spExplosion = cc.Sprite:create()
    
    if (self.m_skillInfo.m_bIsThirdParty == true) then
        local point = cc.p(self.m_spShow:getPosition())
        self.m_spExplosion:setPosition(point)
        g_mainScene:getCurrBgMap():addChild(self.m_spExplosion)
        local high = self.m_attacker:getParent():getHurtPointRelativeFootOffset()
        self.m_spExplosion:setLocalZOrder(BgMap.getZOrder(cc.pSub(point, high)) + 1)
    else
        local victim = self.m_victim:getParent()
        if (not victim) then
            self:releaseThis()
            return
        end
        
        local x = victim:getContentSize().width * victim:getFigure():getAnchorPointCenter().x
        local y = victim:getContentSize().height * victim:getFigure():getAnchorPointCenter().y
        self.m_spExplosion:setPosition(x, y)
        self.m_victim:addChild(self.m_spExplosion)
    end
    
    local flag = 0
    
    local array = {}
    while (true) do
        local frameName = string.format("%s_%02d.png", path, flag)
        local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)
        if (not spriteFrame) then
            break
        end
        table.insert(array, spriteFrame)
        flag = flag + 1
    end
    
    if (#array > 0) then
        local animation = cc.Animation:createWithSpriteFrames(array, 1 / 24)
        local animate = cc.Animate:create(animation)
        local finish = cc.CallFunc:create(handler(self, self.releaseThis))
        local sequence1 = cc.Sequence:create(animate, finish)
        
        local delay = cc.DelayTime:create(animate:getDuration()/2)
        local callFunc = cc.CallFunc:create(handler(self, self.sendMessage))
        local sequence2 = cc.Sequence:create(delay, callFunc)
        
        local spawn = cc.Spawn:create(sequence1, sequence2)
        
        self.m_spExplosion:runAction(spawn)
    else
        self:sendMessage()
        self:releaseThis()
    end
end

function SkillEffectShow:getRotationWithLocusSpecific()
    local lenghtX = self:getDestination().x - self.m_spShow:getPositionX()
    local lenghtY = self:getDestination().y - self.m_spShow:getPositionY()
    lenghtY = lenghtY * math.sqrt(2)
    local lenght = math.sqrt(lenghtX * lenghtX + lenghtY * lenghtY)
    local angle_X = math.acos(lenghtX / lenght) * 180 / math.pi
    local angle_Y = math.acos(lenghtY / lenght) * 180 / math.pi

    local angle = angle_X
    if (angle_Y > 90) then
        angle = 360 - angle_X
    end
    
    local relust = 0
    
    if (math.abs(67.5 - angle) <= 11.25) then
        -- up2 right1
        relust = 5
    elseif (math.abs(45 - angle) <= 11.25) then
        -- up2 right2
        relust = 10
    elseif (math.abs(22.5 - angle) <= 11.25) then
        -- up1 right2
        relust = 15
    elseif (math.abs(0 - angle) <= 11.25) then
        -- right2
        relust = 20
    elseif (math.abs(337.5 - angle) <= 11.25) then
        -- right2 down1
        relust = 25
    elseif (math.abs(315 - angle) <= 11.25) then
        -- right2 down2
        relust = 30
    elseif (math.abs(292.5 - angle) <= 11.25) then
        -- right1 down2
        relust = 35
    elseif (math.abs(270 - angle) <= 11.25) then
        -- down2
        relust = 40
    elseif (math.abs(247.5 - angle) <= 11.25) then
        -- down2 left
        relust = 45
    elseif (math.abs(225 - angle) <= 11.25) then
        -- down2 left2
        relust = 50
    elseif (math.abs(202.5 - angle) <= 11.25) then
        -- down1 left2
        relust = 55
    elseif (math.abs(180 - angle) <= 11.25) then
        -- left2
        relust = 60
    elseif (math.abs(157.5 - angle) <= 11.25) then
        -- left2 up1
        relust = 65
    elseif (math.abs(135 - angle) <= 11.25) then
        -- left2 up2
        relust = 70
    elseif (math.abs(112.5 - angle) <= 11.25) then
        -- left up2
        relust = 75
    elseif (math.abs(90 - angle) <= 11.25) then
        -- up2
        relust = 80
    end
    
    return relust
end

function SkillEffectShow:getDestination()
    local point = cc.p(0, 0)
    if (not self.m_victim:getParent()) then
        self:releaseThis()
        return point
    end
    return self.m_victim:getParent():getHurtPoint()
end

function SkillEffectShow:getDeparture()
    if (not self.m_attacker:getParent()) then
        self:releaseThis()
        return cc.p(0, 0)
    end
    return self.m_attacker:getParent():getHandPoint()
end

function SkillEffectShow:sendMessage()
    if (self.m_skillInfo.m_bIsThirdParty) then
        if (self.m_skillInfo.m_explosionFanAngle == 360) then
            local arrMonomer = g_mainScene:getMonmerVecIsLenght(cc.p(self.m_spShow:getPosition()), self.m_skillInfo.m_explosionRadius)
            if (#arrMonomer == 0) then
                table.insert(arrMonomer, self.m_victim:getParent())
            end
            GameSocket.attackGroup(self.m_attacker:getParent(), arrMonomer, self.m_skillInfo.m_nNum)
        else
            
        end
    else
        GameSocket.attack(self.m_attacker:getParent(), self.m_victim:getParent(), self.m_skillInfo.m_nNum)
    end
end

function SkillEffectShow:releaseThis()
    if (self.m_spShow and self.m_spShow:getParent()) then
        self.m_spShow:removeFromParent()
        self.m_spShow = nil
    end
    if (self.m_spExplosion and self.m_spExplosion:getParent()) then
        self.m_spExplosion:removeFromParent()
        self.m_spExplosion = nil
    end
    if (self:getParent()) then
        self:removeFromParent()
    end
end

return SkillEffectShow