local TextureController = require("app.figure.TextureController") 

local TAG_ANIMATE = 0xfffff0

-- 人物方向
FigureDirection = {
    Up              = 8,    -- 上
    LeftAndUp       = 7,    -- 左上
    Left            = 6,    -- 左
    LeftAndDown     = 5,    -- 左下
    Down            = 4,    -- 下
    RightAndDown    = 3,    -- 右下
    Right           = 2,    -- 右
    RightAndUp      = 1,    -- 右上
    None            = 0
}

-- 人物状态
FigureState = {
    Death     = 7,  -- 死亡
    Hurt      = 6,  -- 伤害 
    Caster    = 5,  -- 投掷 
    Attack    = 4,  -- 攻击 
    Run       = 3,  -- 跑
    Walk      = 2,  -- 走
    Stand     = 1,
    None      = 0
}

-- 人物类
local Figure = class("Figure", function()
    return display.newSprite()
end)

function Figure:ctor(nType, nFigureNum)
    self.m_nState = FigureState.Stand
    self.m_nDirection = FigureDirection.Down
    self.m_nFrameRate = 0.5
    self.m_nTexturePathType = nType
    self.m_nFigureNum = math.floor(nFigureNum)
    self.m_nHairNum = 0
    self.m_nWeaponNum = 0
    self.m_spHair = nil
    self.m_spWeapon = nil
    self.m_pDelegate = nil
    
    TextureController.addSpriteFrames(self.m_nTexturePathType, self.m_nFigureNum, handler(self, self.updateFigure))

    self:setContentSize(256 * 0.8, 256 * 0.8)
end

-- 设置头发
function Figure:setHair(nHairNum)
    nHairNum = math.floor(nHairNum)
    
    if (self.m_spHair ~= nil) then
        self.m_spHair:removeFromParent()
        TextureController.subSpriteFrames(TexturePathType.Hair, self.m_nHairNum)
        self.m_spHair = nil
        self.m_nHairNum = 0
    end
    
    if (self.m_nTexturePathType == TexturePathType.Monster) then
        return
    end
    
    self.m_nHairNum = nHairNum * 10 + self.m_nFigureNum % 10
    if (0 == self.m_nHairNum) then
        return
    end

    TextureController.addSpriteFrames(TexturePathType.Hair, self.m_nHairNum, handler(self, self.updateFigure))
        
    self.m_spHair = cc.Sprite:create()
    self.m_spHair:setPosition(128*0.8, 128*0.8)
    self:addChild(self.m_spHair, 1, 999)
end

-- 设置武器
function Figure:setWeapon(nWeaponNum)
    if (self.m_spWeapon ~= nil) then
        self.m_spWeapon:removeFromParent()
        TextureController.subSpriteFrames(TexturePathType.Weapon, self.m_nWeaponNum)
        self.m_spWeapon = nil
        self.m_nWeaponNum = 0
    end
    
    if (self.m_nTexturePathType == TexturePathType.Monster) then
        return
    end
    
    self.m_nWeaponNum = nWeaponNum
    if (0 == self.m_nWeaponNum) then
        return
    end
        
    TextureController.addSpriteFrames(TexturePathType.Weapon, self.m_nWeaponNum, handler(self, self.updateFigure))
 
    self.m_spWeapon = cc.Sprite:create()
    self.m_spWeapon:setPosition(128*0.8, 128*0.8)
    self:addChild(self.m_spWeapon, 0, 888)
end

-- 设置状态和方向
function Figure:setFigureState(nState, nDirection)
    local bIsChange = false
    
    if (nState and nState ~= FigureState.None and nState ~= self.m_nState) then
        self.m_nState = nState
        bIsChange = true
    end
    
    if (nDirection and nDirection ~= FigureDirection.None and nDirection ~= self.m_nDirection) then
        self.m_nDirection = nDirection
        bIsChange = true
    end

    if (bIsChange) then
        self:updateFigure()
    end
end

local function getFrameRate(nState, nType)
    local nFrameRate = 0
    
    if (nType == TexturePathType.Figure) then
        if (nState == FigureState.Stand) then
            nFrameRate = 1/3.0
        elseif (nState == FigureState.Walk) then
            nFrameRate = 0.6/16.0
        elseif (nState == FigureState.Run) then
            nFrameRate = 0.6/16.0
        elseif (nState == FigureState.Attack) then
            nFrameRate = 1/8.0     
        elseif (nState == FigureState.Caster) then
            nFrameRate = 1/8.0
        elseif (nState == FigureState.Hurt) then
            nFrameRate = 1/8.0
        elseif (nState == FigureState.Death) then
            nFrameRate = 1/4.0
        end
    end
    
    if (nType == TexturePathType.Monster) then
        if (nState == FigureState.Stand) then
            nFrameRate = 1/5.0
        elseif (nState == FigureState.Walk) then
            nFrameRate = 0.6/8.0
        elseif (nState == FigureState.Run) then
            nFrameRate = 0.6/8.0
        elseif (nState == FigureState.Attack) then
            nFrameRate = 1/8.0
        elseif (nState == FigureState.Caster) then
            nFrameRate = 1/8.0
        elseif (nState == FigureState.Hurt) then
            nFrameRate = 1/8.0
        elseif (nState == FigureState.Death) then
            nFrameRate = 1/8.0
        end
    end
    
    return nFrameRate
end

-- 更新人物状态
function Figure:updateFigure()
    self.m_nFrameRate = getFrameRate(self.m_nState, self.m_nTexturePathType)
    
    if (self.m_nDirection == FigureDirection.Left or 
        self.m_nDirection == FigureDirection.LeftAndUp or 
        self.m_nDirection == FigureDirection.LeftAndDown) then
        self:setRotationSkewY(180)
    else
        self:setRotationSkewY(0)
    end
    
    if (self.m_spWeapon) then
        if (self.m_nDirection == FigureDirection.Up) then
            self.m_spWeapon:setLocalZOrder(-1)
        else        
            self.m_spWeapon:setLocalZOrder(0)
        end
    end
    
    self:runActions()
end

function Figure:runActions()
    self:stopActionByTag(TAG_ANIMATE)
    
    local figurePath = TextureController.getTexturePath(self.m_nTexturePathType, self.m_nFigureNum)
    local animate = self:getRunActionsFromSprite(figurePath)
    
    if (self.m_nState == FigureState.Attack) then
        local delayTime = cc.DelayTime:create(animate:getDuration()/2)
        local callFunc1 = cc.CallFunc:create(handler(self, self.attacking))
        local callFunc2 = cc.CallFunc:create(handler(self, self.attackCompleted))
        self:runAction(cc.Sequence:create(delayTime, callFunc1, delayTime, callFunc2))
        
        animate:setTag(TAG_ANIMATE)
        self:runAction(animate)
    elseif (self.m_nState == FigureState.Caster) then
        local delayTime = cc.DelayTime:create(animate:getDuration()/2)
        local callFunc1 = cc.CallFunc:create(handler(self, self.attacking))
        local callFunc2 = cc.CallFunc:create(handler(self, self.attackCompleted))
        self:runAction(cc.Sequence:create(delayTime, callFunc1, delayTime, callFunc2))
        
        animate:setTag(TAG_ANIMATE)
        self:runAction(animate)
    elseif (self.m_nState == FigureState.Hurt) then
        local sequence = cc.Sequence:create(animate, cc.CallFunc:create(handler(self, self.hurtCompleted)))
        sequence:setTag(TAG_ANIMATE)
        self:runAction(sequence)
    elseif (self.m_nState == FigureState.Death) then
        self:runAction(cc.Sequence:create(animate, cc.CallFunc:create(handler(self, self.deathCompleted))))
    else
        local repeatForever = cc.RepeatForever:create(animate)
        repeatForever:setTag(TAG_ANIMATE)
        self:runAction(repeatForever)
    end
    
    if (self.m_spHair) then
        self.m_spHair:stopAllActions()
        
        local path = TextureController.getTexturePath(TexturePathType.Hair, self.m_nHairNum)
        local animate = self:getRunActionsFromSprite(path)
        if (self.m_nState > 3) then
            self.m_spHair:runAction(animate)
        else
            self.m_spHair:runAction(cc.RepeatForever:create(animate))
        end
    end
    
    if (self.m_spWeapon) then
        self.m_spWeapon:stopAllActions()
        
        local path = TextureController.getTexturePath(TexturePathType.Weapon, self.m_nWeaponNum)
        if (self.m_nState == FigureState.Death) then
            path = path .. string.sub(figurePath, -1)
        else
            path = path .. "0"
        end
        
        local animate = self:getRunActionsFromSprite(path)
        if (self.m_nState > 3) then
            self.m_spWeapon:runAction(animate)
        else
            self.m_spWeapon:runAction(cc.RepeatForever:create(animate))
        end
    end
end

function Figure:getRunActionsFromSprite(path)
    local nDirection = self.m_nDirection
    if (8 > nDirection and nDirection > 4) then
        nDirection = 8 - nDirection
    end

    local flag = 0
    local array = {}
    
    while (true) do
        local frameName = string.format("%s_%d_%d_%02d.png", path, self.m_nState, nDirection, flag)
        local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)
        if (not frame) then
            break
        end
        table.insert(array, frame)
        flag = flag + 1
    end
    
    local animation = cc.Animation:createWithSpriteFrames(array, self.m_nFrameRate)
    local animate = cc.Animate:create(animation)
    return animate
end

function Figure:attacking()
    if (self.m_pDelegate) then
        self.m_pDelegate:attacking()
    end
end

function Figure:attackCompleted()
    if (self.m_pDelegate) then
        self.m_pDelegate:attackCompleted()
    end
end

function Figure:hurtCompleted()
    if (self.m_pDelegate) then
        self.m_pDelegate:underAttack()
    end
end

function Figure:deathCompleted()
    if (self.m_pDelegate) then
        self.m_pDelegate:deathActionFinish()
    end
end

function Figure:setDelegate(delegate)
    self.m_pDelegate = delegate
end

-- 脚
function Figure:getAnchorPointWithFoot()
    local x = self:getContentSize().width / 2 / self:getContentSize().width
    local y = (self:getContentSize().height - 120) / self:getContentSize().height
    return cc.p(x, y)
end

-- 手
function Figure:getAnchorPointWithHand()
    local x = self:getContentSize().width / 2 / self:getContentSize().width
    local y = (self:getContentSize().height - 64) / self:getContentSize().height
    return cc.p(x, y)
end

function Figure:getAnchorPointCenter()
    return cc.p(0.5, 0.5)
end

-- 设置透明度
function Figure:setOpacityEx(opacity)
    self:setOpacity(opacity)
    
    if (self.m_spHair) then
        self.m_spHair:setOpacity(opacity)
    end
    
    if (self.m_spWeapon) then
        self.m_spWeapon:setOpacity(opacity)
    end
end

function Figure:getWeaponSprite()
    return self.m_spWeapon
end

return Figure