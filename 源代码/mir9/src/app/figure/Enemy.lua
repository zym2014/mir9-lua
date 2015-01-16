local scheduler = require("framework.scheduler")
local MapPoint = require("app.map.MapPoint")
local Monomer = require("app.figure.Monomer")
local FlutteringFairy = require("app.game_ui.FlutteringFairy")

-- 敌人类
local Enemy = class("Enemy", Monomer)

function Enemy:ctor(enemyID, roleNumber, weaponNumber)
    Enemy.super.ctor(self)
    
    self.m_enemyID = enemyID
    self.m_denPos = MapPoint.new(0, 0)
    self.m_isActive = true
    
    self:initWithEnemy(roleNumber, weaponNumber)
end

function Enemy:initWithEnemy(roleNumber, weaponNumber)
    self.m_fReactionInterval = 1.0
    
    self:setVisualRange(10)
    self:setFigure(TexturePathType.Monster, roleNumber)
    self:setWeapon(weaponNumber)
    
    return true
end

function Enemy:onEnter()
    Enemy.super.onEnter(self)
    local mpoint = MapPoint.new(cc.p(self:getPosition()))
    g_mainScene:insterMapPoint(self, mpoint)
end

function Enemy:onExit()
    Enemy.super.onExit(self)
    self:stopAllActions()
    self:killTimer_Patrol()
end

-- 启动计时器
function Enemy:setTimer_Patrol(fTime)
    self:killTimer_Patrol()
    self.hPatrol = scheduler.scheduleGlobal(handler(self, self.patrol), fTime)
end

-- 关闭计时器
function Enemy:killTimer_Patrol()
    if (self.hPatrol) then
        scheduler.unscheduleGlobal(self.hPatrol)
        self.hPatrol = nil
    end
end

-- 显示人物
function Enemy:showFigure()
    local point = cc.p(self:getPosition())
    if (not cc.rectContainsPoint(g_mainScene:getCurrBgMap():getShowRect(), point)) then
        return
    end

    Enemy.super.showFigure(self)
end

-- 隐藏人物
function Enemy:hideFigure()
    local point = cc.p(self:getPosition())
    if (cc.rectContainsPoint(g_mainScene:getCurrBgMap():getHideRect(), point)) then
        return
    end
    
    Enemy.super.hideFigure(self)
end

-- 跑
function Enemy:runBy(mpoint)
    local relust = Enemy.super.runBy(self, mpoint)
    
    if (relust.fTime ~= 0) then
        g_mainScene:insterMapPoint(self, relust.mpoint)
    end
    
    return relust
end

-- 走
function Enemy:walkBy(mpoint)
    local relust = Enemy.super.walkBy(self, mpoint)
    
    if (relust.fTime ~= 0) then
        g_mainScene:insterMapPoint(self, relust.mpoint)
    end
    
    return relust
end

-- 去到指定点
function Enemy:goTo(mpoint)
    g_mainScene:insterMapPoint(self, mpoint)
    
    return Enemy.super.goTo(self, mpoint)
end

function Enemy:detectionOfEachOther()
    Enemy.super.detectionOfEachOther(self)
    self:detectionWhetherCounter()
end

-- 检测是否反击
function Enemy:detectionWhetherCounter()
    if (not self.m_attackMonomerMajor) then
        self:setAttackMonomerMajor(self:getAgainstMeOfFirst())
    end
    
    if (not self.m_attackMonomerMajor) then
        self:patrol()
    else
        self:followAttackAndSetAttackMethods(self.m_attackMonomerMajor, self.m_attackSkillInfo.m_nNum)
    end
end

function Enemy:followAttack()
    self:killTimer_Patrol()
    
    Enemy.super.followAttack(self)
end

function Enemy:followTheTracks()
    local mpoint = self.m_attackMonomerMajor:ownAttackPoint(self, self.m_attackSkillInfo.m_attackDistance)
    if (mpoint:equalsObj(MapPoint.new(cc.p(0, 0)))) then
        return
    end
    mpoint = MapPoint.sub(mpoint, MapPoint.new(cc.p(self:getPosition())))
    local relust = self:walkBy(mpoint)
    local fTime = self.m_fReactionInterval + relust.fTime
    self:delayCallBack(fTime, handler(self, self.followAttack)):setTag(TAG_FOLLOWATTACK)
end

-- 超出可视范围
function Enemy:beyondVisualRange()
    self.m_attackMonomerMajor:removeAgainstMe(self)
    self:patrol()
    
    Enemy.super.beyondVisualRange(self)
end

-- 隔一段时间走动一下
function Enemy:patrol(fDelay)
    self:killTimer_Patrol()
    
    if (self.m_isCanMoved == false) then
        return
    end
    
    local symbol = math.floor(2 * math.random())
    local arcX = math.floor(10 * math.random())
    local arcY = math.floor(10 * math.random())
    local mpoint = MapPoint.new(self.m_denPos.x+arcX*symbol, self.m_denPos.z+arcY*symbol)
    local dirt = MapPoint.sub(mpoint, MapPoint.new(cc.p(self:getPosition())))
    self:walkBy(dirt)
    
    local fTime = math.floor(180 * math.random()) + 1
    self:setTimer_Patrol(fTime)
end

function Enemy:moveByEnd()
    Enemy.super.moveByEnd(self)
end

-- 死亡
function Enemy:death()
    if (self:getState() == FigureState.Death) then
        return
    end
    
    Enemy.super.death(self)
    
    local delayTime1 = cc.DelayTime:create(0.3)
    local delayTime2 = cc.DelayTime:create(0.3)
    local delayTime3 = cc.DelayTime:create(6)
    local fadeOut = cc.FadeOut:create(0.1)
    local callFunc1 = cc.CallFunc:create(handler(self, self.addExp))
    local callFunc2 = cc.CallFunc:create(handler(self, self.removeThis))
    local callFunc3 = cc.CallFunc:create(function()
        self:removeFromParent()
    end)
    local sequence = cc.Sequence:create(delayTime1, 
        callFunc1, delayTime2, callFunc2, delayTime3, fadeOut, callFunc3)
    self.m_nMonomer:runAction(sequence)
end

function Enemy:addAgainstMe(monomer, blood)
    Enemy.super.addAgainstMe(self, monomer, blood)
    self:hurt()
end

function Enemy:addExp()
    local fairy = FlutteringFairy.addFairy(self, cc.p(0, self:getContentSize().height*0.6), FairyType.AddExp, math.random()*20+990, handler(self, self.flutteringFairyFinish))
    self:pushFlutteringFairy(fairy)
end

function Enemy:removeThis()
    g_mainScene:removeEnemy(self)
    if (self.bloodBg) then
        self.bloodBg:removeFromParent()
        self.bloodBg = nil
    end
end

function Enemy:getRoleNumber()
    return self.m_nCurRoleNum
end

-- 攻击
function Enemy:attacking()
    Enemy.super.attacking(self)
end

-- 受到攻击
function Enemy:underAttack()
    Enemy.super.underAttack(self)
    
    if (self.m_nState == FigureState.Death) then
        return
    end
    
    if (self.m_attackMonomerMajor) then
        return
    end
    
    self:detectionWhetherCounter()
end

-- 设置人物状态
function Enemy:setFigureState(nState, nDirection)
    Enemy.super.setFigureState(self, nState, nDirection)
end

function Enemy:getDenPos()
    return self.m_denPos
end
 
function Enemy:setDenPos(mpoint)
    self.m_denPos = mpoint
end

function Enemy:getEnemyID()
    return self.m_enemyID
end

function Enemy:getActive()
    return self.m_isActive
end

function Enemy:setActive(bActive)
    self.m_isActive = bActive
end

return Enemy