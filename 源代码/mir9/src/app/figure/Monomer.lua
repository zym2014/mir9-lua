local scheduler = require("framework.scheduler")
local Figure = require("app.figure.Figure")
local MapPoint = require("app.map.MapPoint")
local BgMap = require("app.map.BgMap")
local TextureController = require("app.figure.TextureController")
local AttackSkillSystem = require("app.skill_system.AttackSkillSystem")
local SkillEffectShow = require("app.skill_system.SkillEffectShow")
local FlutteringFairy = require("app.game_ui.FlutteringFairy")

TAG_MOVET = 0xfffff1
TAG_FOLLOWATTACK = 0xfffff2
TAG_COOLINGTIMEATTACK = 0xfffff3
TAG_MOVETWAIT = 0xfffff4

MoveInfo = class("MoveInfo")

function MoveInfo:ctor(fTime, mpoint, bIsCanNotFineTheWay)    
    self.fTime = fTime
    self.mpoint = mpoint
    self.bIsCanNotFineTheWay = bIsCanNotFineTheWay
end

local Monomer = class("Monomer", function()
    return display.newSprite()
end)

function Monomer:ctor()
    self.m_nMonomer = nil
    self.m_nDirection = FigureDirection.Down
    self.m_nState = FigureState.Stand
    self.m_attackMonomerMajor = nil
    self.m_againstMeSet = {}
    self.m_attackTime = 0.5
    self.m_fReactionInterval = 0
    self.m_bIsCanMoved = true
    self.m_runSpeed = 1
    self.m_visualRange = 5
    self.m_bIsCooling = false
    self.m_attackSkillInfo = nil
    self.m_blood = 0
    self.m_magic = 0
    self.m_pTheAttack = 0
    self.m_nTexturePathType = TexturePathType.Figure
    self.m_nCurRoleNum = 0
    self.m_nCurHairNum = 0
    self.m_nCurWeaponNum = 0
    self.m_nCurEffectID = 0
    self.hUpdateVertexZ = 0
    self.m_mapAttackSkill = {}
    self.m_flutteringFairyDeque = {}
    
    self:addAttackSkill(1001)
    self.m_attackSkillInfo = g_attackSkillSystem:getAttackSkillInfo(1001)
    
    self:setNodeEventEnabled(true)
    self:setScale(1.0)
end

function Monomer:onEnter()
    self:showFigure()
end

function Monomer:onExit()
    self:stopAllActions()
    self:killTimer_UpdateVertexZ()
end

-- 设置人物
function Monomer:setFigure(nType, nRoleNum)
    self.m_nTexturePathType = nType
    
    self.m_nCurRoleNum = nRoleNum
    
    if (self.m_nTexturePathType ~= TexturePathType.Figure) then
        self.m_nCurWeaponNum = 0
    end
    
    if (self.m_nMonomer) then
        self:hideFigure()
        self:showFigure()
    end
end

-- 设置头发
function Monomer:setHair(nHairNum)
    if (self.m_nTexturePathType ~= TexturePathType.Figure) then
        return
    end
    
    self.m_nCurHairNum = nHairNum
    
    if (self.m_nMonomer) then
        self.m_nMonomer:setHair(self.m_nCurHairNum)
    end
end

-- 设置武器
function Monomer:setWeapon(nWeaponNum)
    if (self.m_nTexturePathType ~= TexturePathType.Figure) then
        return
    end
    
    self.m_nCurWeaponNum = nWeaponNum
        
    if (self.m_nMonomer) then
        self.m_nMonomer:setWeapon(self.m_nCurWeaponNum)
    end
end

-- 显示人物
function Monomer:showFigure()
    if (0 == self.m_nCurRoleNum) then
        return
    end
    
    if (self.m_nMonomer) then
        return
    end
    
    self.m_nMonomer = Figure.new(self.m_nTexturePathType, self.m_nCurRoleNum)
    self:setContentSize(self.m_nMonomer:getContentSize())
    self:setAnchorPoint(self.m_nMonomer:getAnchorPointWithFoot())
    local size = self:getContentSize()
    self.m_nMonomer:setPosition(size.width/2, size.height/2)
    self:addChild(self.m_nMonomer)
    self.m_nMonomer:setDelegate(self)
    self.m_nMonomer:setHair(self.m_nCurHairNum)
    self.m_nMonomer:setWeapon(self.m_nCurWeaponNum)
    self.m_nMonomer:setFigureState(self.m_nState, self.m_nDirection)
        
    local ptBlood = cc.p(size.width * self:getAnchorPoint().x, size.height * 0.8)
        
    self.bloodBg = display.newSprite("blood_box.png")
    self.bloodBg:setAnchorPoint(cc.p(0.5, 0.5))
    self.bloodBg:setPosition(ptBlood)
    self.bloodBg:setScale(0.3)
    self:addChild(self.bloodBg)
        
    self.bloodIn = display.newSprite("blood_in.png")
    self.bloodIn:setAnchorPoint(cc.p(0, 0))
    self.bloodBg:addChild(self.bloodIn)
end

-- 隐藏人物
function Monomer:hideFigure()
    if (not self.m_nMonomer) then
        return
    end
    self.m_nMonomer:removeFromParent()
    self.m_nMonomer = nil
    self.bloodBg:removeFromParent()
end

-- 设置人物状态
function Monomer:setFigureState(nState, nDirection)
    if (self.m_nState == FigureState.Death) then
        return
    end
    
    if (nState ~= FigureState.None) then
        self.m_nState = nState
    end
        
    if (nDirection ~= FigureDirection.None) then
        self.m_nDirection = nDirection
    end
        
    if (self.m_nMonomer) then
        self.m_nMonomer:setFigureState(nState, nDirection)
    end
end

-- 脚
function Monomer:getHandPointRelativeFootOffset()
    local anchorPoint
    if (self.m_nMonomer) then
        anchorPoint = cc.pSub(self.m_nMonomer:getAnchorPointWithHand(), cc.p(self:getAnchorPoint()))
    else
        anchorPoint = cc.p(0.5, 0.5)
    end
    local szContent = self:getContentSize()
    return cc.p(szContent.width * anchorPoint.x, szContent.height * anchorPoint.y)
end

-- 手
function Monomer:getHandPoint()
    local handRelativeFoot = self:getHandPointRelativeFootOffset()
    local point = cc.p(self:getPosition())
    return cc.pAdd(point, handRelativeFoot)
end

function Monomer:getHurtPointRelativeFootOffset()
    local anchorPoint
    if (self.m_nMonomer) then
        anchorPoint = cc.pSub(self.m_nMonomer:getAnchorPointCenter(), cc.p(self:getAnchorPoint()))
    else
        anchorPoint = cc.p(0.5, 0.5)
    end
    local szContent = self:getContentSize()
    return cc.p(szContent.width * anchorPoint.x, szContent.height * anchorPoint.y)
end

function Monomer:getHurtPoint()
    local hurtRelativeFoot = self:getHurtPointRelativeFootOffset()
    local point = cc.p(self:getPosition())
    return cc.pAdd(point, hurtRelativeFoot)
end

function Monomer:getAgainstMeOfFirst()
    if (#self.m_againstMeSet <= 0) then
        return nil
    end

    return self.m_againstMeSet[1]
end

function Monomer:getRect()
    local ptPos = cc.p(self:getPosition())
    local szContent = self:getContentSize()
    local ptAnchor = self:getAnchorPoint()
    
    local off_x = szContent.width * 0.4
    local off_y = szContent.height * ptAnchor.y * 0.5

    local width = szContent.width * 0.3
    local height = szContent.height * 0.6
    
    local rect = cc.rect(0,0,0,0)
    rect.x, rect.y = off_x, off_y
    rect.width, rect.height = width, height
    
    local x = szContent.width * ptAnchor.x
    local y = szContent.height * ptAnchor.y
    
    local point = cc.p(x, y)
    point = cc.pSub(ptPos, point)

    local relustRect = rect
    relustRect.x = point.x + rect.x
    relustRect.y = point.y + rect.y
    
    return relustRect
end

function Monomer:getAlphaWithPoint(point)
    return 0
end

-- 走到左面
function Monomer:walkLeft()
    self:setFigureState(FigureState.Walk, FigureDirection.Left)
end

-- 走到右面
function Monomer:walkRight()
    self:setFigureState(FigureState.Walk, FigureDirection.Right)
end

-- 走到上面
function Monomer:walkUp()
    self:setFigureState(FigureState.Walk, FigureDirection.Up)
end

-- 走到下面
function Monomer:walkDown()
    self:setFigureState(FigureState.Walk, FigureDirection.Down)
end

-- 走到左上
function Monomer:walkLeftAndUp()
    self:setFigureState(FigureState.Walk, FigureDirection.LeftAndUp)
end

-- 走到右上
function Monomer:walkRightAndUp()
    self:setFigureState(FigureState.Walk, FigureDirection.RightAndUp)
end

-- 走到右下
function Monomer:walkRightAndDown()
    self:setFigureState(FigureState.Walk, FigureDirection.RightAndDown)
end

-- 走到左下
function Monomer:walkLeftAndDown()
    self:setFigureState(FigureState.Walk, FigureDirection.LeftAndDown)
end

-- 跑到左面
function Monomer:runLeft()
    self:setFigureState(FigureState.Run, FigureDirection.Left)
end

-- 跑到右面
function Monomer:runRight()
    self:setFigureState(FigureState.Run, FigureDirection.Right)
end

-- 跑到上面
function Monomer:runUp()
    self:setFigureState(FigureState.Run, FigureDirection.Up)
end

-- 跑到下面
function Monomer:runDown()
    self:setFigureState(FigureState.Run, FigureDirection.Down)
end

-- 跑到左上
function Monomer:runLeftAndUp()
    self:setFigureState(FigureState.Run, FigureDirection.LeftAndUp)
end

-- 跑到右上
function Monomer:runRightAndUp()
    self:setFigureState(FigureState.Run, FigureDirection.RightAndUp)
end

-- 跑到右下
function Monomer:runRightAndDown()
    self:setFigureState(FigureState.Run, FigureDirection.RightAndDown)
end

-- 跑到左下
function Monomer:runLeftAndDown()
    self:setFigureState(FigureState.Run, FigureDirection.LeftAndDown)
end

function Monomer:stand()
    self:setFigureState(FigureState.Stand, FigureDirection.None)
end

-- 伤害
function Monomer:hurt()
    if (self:getState() ~= FigureState.Death) then
        self:setFigureState(FigureState.Hurt, FigureDirection.None)
    end
end

-- 死亡
function Monomer:death()
    if (self:getState() ~= FigureState.Death) then
        self.m_nMonomer:stopAllActions()
        --self.m_nMonomer:unscheduleAllSelectors()
        self:stopAllActions()
        --self:unscheduleAllSelectors()
        self:setFigureState(FigureState.Death, FigureDirection.None)
        self:clearData()
    end
end

function Monomer:playEffect(node, path)
    if ((not node) or (not path) or (path == "")) then
        return
    end
        
    local array = {}
        
    local flag = 4
        
    while (true) do
        local fileName = string.format("%s%04d.png", path, flag)
        local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(fileName)
        if (not spriteFrame) then
            break
        end
        table.insert(array, spriteFrame)
        flag = flag + 1
    end

    if (#array == 0) then
        return
    end
        
    local sprite = cc.Sprite:createWithSpriteFrame(array[1])
    local x = self:getContentSize().width * self:getAnchorPoint().x
    local y = self:getContentSize().height * 0.65
    sprite:setPosition(x, y)
    node:addChild(sprite, 1000)
        
    local animation = cc.Animation:createWithSpriteFrames(array, 1 / 32)
    local animate = cc.Animate:create(animation)
    local callFunc = cc.CallFunc:create(function()
        sprite:removeFromParent()
    end)
    local sequence = cc.Sequence:create(animate, callFunc)
    sprite:runAction(sequence)
end

-- 恢复血量
function Monomer:bloodReturn(fBlood)
    local blood = math.min(self:getBlood() + fBlood, self:getBloodCap())
    self:setBlood(blood)
    self:updateBloodProgress()
    
    local point = cc.p(0, self:getContentSize().height * 0.5)
    local fairy = FlutteringFairy.addFairy(self, point, TypeAddBlood, fBlood, handler(self, self.flutteringFairyFinish))
    self:pushFlutteringFairy(fairy)
    self:playEffect(self, "addh-")
end

function Monomer:followAttack()
    self:stopActionByTag(TAG_FOLLOWATTACK)
    
    if (not self.m_attackMonomerMajor) then
        self:beyondVisualRange()
        return
    end
        
    if (self.m_attackMonomerMajor:getState() == FigureState.Death) then
        self:beyondVisualRange()
        return
    end
        
    if (self:isInTheAttackRange(self.m_attackMonomerMajor)) then        -- 敌人在攻击范围内
        self:attackEnemy()
    elseif (self:isInTheFieldOfView(self.m_attackMonomerMajor)) then    -- 敌人在可视范围内
        self:followTheTracks()
    else
        self:beyondVisualRange()
    end
end

function Monomer:followTheTracks()
    local mpoint = self.m_attackMonomerMajor:ownAttackPoint(self, self.m_attackSkillInfo.m_attackDistance)
    if (mpoint:equalsObj(MapPoint.new(0, 0))) then
        return
    end
    local point = cc.p(self:getPosition())
    local mpos = MapPoint.new(point)
    mpoint = MapPoint.sub(mpoint, mpos)
    local relust = self:runBy(mpoint)
    if (relust.fTime == 0) then
        return
    end
    local fTime = self.m_fReactionInterval + relust.fTime + 0.01
    self:delayCallBack(fTime, handler(self, self.followAttack)):setTag(TAG_FOLLOWATTACK)
end

function Monomer:isInTheAttackRange(monomer)
    local pos1 = cc.p(self:getPosition())
    local pos2 = cc.p(monomer:getPosition())
    
    local mpos1 = MapPoint.new(pos1)
    local mpos2 = MapPoint.new(pos2)
    
    local attackRange = self.m_attackSkillInfo.m_attackDistance
    
    if (mpos1:getDistance(mpos2) > attackRange) then
        return false
    end
    
    if (mpos1:equalsObj(mpos2)) then
        return false
    end
    
    if (self:isMoveRunning()) then
        return false
    end
        
    return true
end

function Monomer:isInTheFieldOfView(monomer)
    local pos1 = cc.p(self:getPosition())
    local pos2 = cc.p(monomer:getPosition())
    
    local mpos1 = MapPoint.new(pos1)
    local mpos2 = MapPoint.new(pos2)
    
    if (mpos1:getDistance(mpos2) <= self.m_visualRange) then
        return true
    end
    
    return false
end

function Monomer:beyondVisualRange()
    self:setAttackMonomerMajor(nil)
end

function Monomer:clearData()
    self.m_flutteringFairyDeque = {}
    
    for i = 1, #self.m_againstMeSet do
        local monomer = self.m_againstMeSet[i]
        monomer:removeAttackMonomerMajor(self)
    end
    self.m_againstMeSet = {}
    
    if (self.m_attackMonomerMajor) then
        self.m_attackMonomerMajor:removeAgainstMe(self)
        self:setAttackMonomerMajor(nil)
    end
end

function Monomer:followAttackAndSetAttackMethods(otherEnemy, nAttackSkillNum)
    if (nAttackSkillNum ~= 0) then
        if (not self.m_mapAttackSkill[nAttackSkillNum]) then
            return
        end
        self.m_attackSkillInfo = self.m_mapAttackSkill[nAttackSkillNum]
    end
    
    if (not otherEnemy) then
        return
    end
    
    if (self:getState() == FigureState.Death) then
        return
    end

    self:setAttackMonomerMajor(otherEnemy)
    self:followAttack()
end

function Monomer:ownAttackPoint(monomer, attackRange)
    local relust = MapPoint.new(0, 0)
    
    local mpos1 = MapPoint.new(cc.p(self:getPosition()))
    local mpos2 = MapPoint.new(cc.p(monomer:getPosition()))
    local lenght = math.min(mpos1:getDistance(mpos2), attackRange)
    
    if (attackRange == 1) then
        relust = mpos1
    else
        local x = -lenght
        local z = -lenght
        local arrMPoint = {}
        while (true) do
            if (#arrMPoint == 8*lenght) then
                break
            end
            
            table.insert(arrMPoint, MapPoint.new(x, z))
            
            if (#arrMPoint <= 2*lenght) then
                x = x + 1
            elseif (2*lenght < #arrMPoint and #arrMPoint <= 4*lenght) then
                z = z + 1
            elseif (4*lenght < #arrMPoint and #arrMPoint <= 6*lenght) then
                x = x - 1
            elseif (6*lenght < #arrMPoint and #arrMPoint < 8*lenght) then
                z = z - 1
            end
        end
        
        local l = 0xffff
        for i = 1, #arrMPoint do
            local mpoint = MapPoint.add(mpos2, arrMPoint[i])
            if ((not g_mainScene:isPointValid(mpoint)) or (mpoint:getDistance(mpos1) >= l)) then
            else
                relust = mpoint
                l = mpoint:getDistance(mpos1)
            end
        end
    end

    return relust
end

--function Monomer:standAndWatch(MapPoint point)
--{
--    M_INT lenghtX = mapSub(point, MapPoint(m_obPosition)).x;
--    M_INT lenghtY = mapSub(point, MapPoint(m_obPosition)).z;
--    float lenght = sqrtf(pow(lenghtX, 2) + pow(lenghtY, 2));
--    float pointX = lenghtX / lenght;
--    float pointY = lenghtY / lenght;
--    float angle_X = acosf(pointX) * 180 / M_PI;
--    float angle_Y = acosf(pointY) * 180 / M_PI;
--
--    float angle = angle_X;
--    if (angle_Y > 90)
--    {
--        angle = 360 - angle_X;
--    }
--    
--    FigureDirectionType dirType = this->getDirectionType(angle);
--
--    this->setFigureState(FStateStand, dirType);
--}

function Monomer:isMoveRunning()
    local x, y = self:getPosition()
    local pos = cc.p(x, y)
    local mpos = MapPoint.new(pos)
    return (cc.pGetDistance(mpos:getCCPointValue(), pos) >= 5.0)
end

function Monomer:actionsWithPoint(startMPoint, endMPoint)
    local callFunc = nil
    
    local array = {}
    
    if (startMPoint:equalsObj(endMPoint)) then
        return array
    end
    
    local lenghtX = endMPoint.x - startMPoint.x
    local lenghtY = endMPoint.z - startMPoint.z
    local lenght = math.sqrt(lenghtX * lenghtX + lenghtY * lenghtY)
    
    local gridNumber = startMPoint:getDistance(endMPoint)
    
    local fTime = 0.6 * startMPoint:getDistance(endMPoint) / self.m_runSpeed / gridNumber

    local pointX = lenghtX / lenght
    local pointY = lenghtY / lenght

    local angle_X = math.acos(pointX) * 180 / math.pi
    local angle_Y = math.acos(pointY) * 180 / math.pi
    
    local angle = angle_X
    if (angle_Y > 90) then
        angle = 360 - angle_X
    end
    
    local nType = math.floor(((angle + 22.5) % 360 ) / 45.0)
    
    if (lenght < 2) then
        if (nType == 0) then
            callFunc = cc.CallFunc:create(handler(self, self.walkRight))
        elseif (nType == 1) then
            callFunc = cc.CallFunc:create(handler(self, self.walkRightAndUp))
        elseif (nType == 2) then
            callFunc = cc.CallFunc:create(handler(self, self.walkUp))
        elseif (nType == 3) then
            callFunc = cc.CallFunc:create(handler(self, self.walkLeftAndUp))
        elseif (nType == 4) then
            callFunc = cc.CallFunc:create(handler(self, self.walkLeft))
        elseif (nType == 5) then
            callFunc = cc.CallFunc:create(handler(self, self.walkLeftAndDown))
        elseif (nType == 6) then
            callFunc = cc.CallFunc:create(handler(self, self.walkDown))
        elseif (nType == 7) then
            callFunc = cc.CallFunc:create(handler(self, self.walkRightAndDown))
        end
    else
        if (nType == 0) then
            callFunc = cc.CallFunc:create(handler(self, self.runRight))
        elseif (nType == 1) then
            callFunc = cc.CallFunc:create(handler(self, self.runRightAndUp))
        elseif (nType == 2) then
            callFunc = cc.CallFunc:create(handler(self, self.runUp))
        elseif (nType == 3) then
            callFunc = cc.CallFunc:create(handler(self, self.runLeftAndUp))
        elseif (nType == 4) then
            callFunc = cc.CallFunc:create(handler(self, self.runLeft))
        elseif (nType == 5) then
            callFunc = cc.CallFunc:create(handler(self, self.runLeftAndDown))
        elseif (nType == 6) then
            callFunc = cc.CallFunc:create(handler(self, self.runDown))
        elseif (nType == 7) then
            callFunc = cc.CallFunc:create(handler(self, self.runRightAndDown))
        end
    end
    
    table.insert(array, callFunc)
    
    local moveTo = cc.MoveTo:create(fTime, endMPoint:getCCPointValue())
    table.insert(array, moveTo)

    return array
end

function Monomer:actionsWithMoveTo(dequeMapPoint)
    local array = {}
    
    if (#dequeMapPoint <= 1) then
        return array
    end
    
    local callFunc1 = cc.CallFunc:create(handler(self, self.setTimer_UpdateVertexZ))
    local callFunc2 = cc.CallFunc:create(handler(self, self.killTimer_UpdateVertexZ))

    table.insert(array, callFunc1)
        
    for i = 2, #dequeMapPoint do
        local startMPoint = dequeMapPoint[i-1]
        local endMPoint = dequeMapPoint[i]
        local array2 = self:actionsWithPoint(startMPoint, endMPoint)
        for j = 1, #array2 do
            table.insert(array, array2[j])
        end
    end
    
    table.insert(array, callFunc2)
            
    return array
end

-- 跑
function Monomer:runBy(mpoint)
    local pos = cc.p(self:getPosition())
    local relust = MoveInfo.new(0.0, MapPoint.new(pos), false)
    
    if (self.m_bIsCanMoved == false) then
        return relust
    end
    
    local nState = self:getState()
    if (nState == FigureState.Death or 
        nState == FigureState.Attack or
        nState == FigureState.Caster or
        nState == FigureState.Hurt) then
        return relust
    end
    
    if (self:isMoveRunning()) then
        return relust
    end
        
    self:stopActionByTag(TAG_MOVET)
    self:stopActionByTag(TAG_FOLLOWATTACK)
    self:stopActionByTag(TAG_COOLINGTIMEATTACK)
        
    local mpos = MapPoint.new(pos)

    local dequeMPoint = g_mainScene:getPathNextRunGrid(mpos, MapPoint.add(mpos, mpoint))
        
    if (#dequeMPoint <= 1) then
        self:stand()
        relust.bIsCanNotFineTheWay = true
        return relust
    end
        
    local array = self:actionsWithMoveTo(dequeMPoint)
        
    local callFunc = cc.CallFunc:create(handler(self, self.moveByBegin))
    local callFunc2 = cc.CallFunc:create(handler(self, self.moveByEnd))
    table.insert(array, 1, callFunc)
    table.insert(array, callFunc2)
        
    local sequence = cc.Sequence:create(array)
    sequence:setTag(TAG_MOVET)
    self:runAction(sequence)
        
    relust.fTime = sequence:getDuration()
    relust.mpoint = dequeMPoint[#dequeMPoint]
    
    return relust
end

-- 走
function Monomer:walkBy(mpoint)
    local pos = cc.p(self:getPosition())
    local relust = MoveInfo.new(0.0, MapPoint.new(pos), false)
    
    if (self.m_bIsCanMoved == false) then
        return relust
    end
    
    local nState = self:getState()
    if (nState == FigureState.Death or 
        nState == FigureState.Attack or
        nState == FigureState.Caster or
        nState == FigureState.Hurt) then
        return relust
    end
    
    if (self:isMoveRunning()) then
        return relust
    end
        
    self:stopActionByTag(TAG_MOVET)
    self:stopActionByTag(TAG_FOLLOWATTACK)
    self:stopActionByTag(TAG_COOLINGTIMEATTACK)
        
    local mpos = MapPoint.new(pos)

    local dequeMPoint = g_mainScene:getPathNextWalkGrid(mpos, MapPoint.add(mpos, mpoint))

    if (#dequeMPoint <= 1) then
        self:stand()
        relust.bIsCanNotFineTheWay = true
        return relust
    end
        
    local array = self:actionsWithMoveTo(dequeMPoint)
        
    local callFunc = cc.CallFunc:create(handler(self, self.moveByBegin))
    local callFunc2 = cc.CallFunc:create(handler(self, self.moveByEnd))
    table.insert(array, 1, callFunc)
    table.insert(array, callFunc2)
        
    local sequence = cc.Sequence:create(array)
    sequence:setTag(TAG_MOVET)
    self:runAction(sequence)
        
    relust.fTime = sequence:getDuration()
    relust.mpoint = dequeMPoint[#dequeMPoint]
    
    return relust
end

-- 去到指定点
function Monomer:goTo(mpoint)
    local pos = cc.p(self:getPosition())
    local relust = MoveInfo.new(0.0, MapPoint.new(pos), false)
    
    if (self.m_bIsCanMoved == false) then
        return relust
    end
    
    local nState = self:getState()
    if (nState == FigureState.Death or 
        nState == FigureState.Attack or
        nState == FigureState.Caster or
        nState == FigureState.Hurt) then
        return relust
    end
    
    if (self:isMoveRunning()) then
        return relust
    end
    
    self:stopActionByTag(TAG_MOVET)
    self:stopActionByTag(TAG_FOLLOWATTACK)
    self:stopActionByTag(TAG_COOLINGTIMEATTACK)
        
    local begin = MapPoint.new(pos)
    local dequeMPoint = g_mainScene:getPath(begin, mpoint)
        
    if (#dequeMPoint <= 1) then
        self:stand()
        relust.bIsCanNotFineTheWay = true
        return relust
    end
        
    local array = self:actionsWithMoveTo(dequeMPoint)
        
    local callFunc = cc.CallFunc:create(handler(self, self.goBegin))
    local callFunc2 = cc.CallFunc:create(handler(self, self.goEnd))
    table.insert(array, 1, callFunc)
    table.insert(array, callFunc2)
    local sequence = cc.Sequence:create(array)
    sequence:setTag(TAG_MOVET)
    self:runAction(sequence)
        
    relust.fTime = sequence:getDuration()
    relust.mpoint = dequeMPoint[#dequeMPoint]

    return relust
end

-- 启动更新Z轴计时器
function Monomer:setTimer_UpdateVertexZ()
    self:killTimer_UpdateVertexZ()
    self.hUpdateVertexZ = scheduler.scheduleGlobal(handler(self, self.updateVertexZ), 0.1)
end

-- 关闭更新Z轴计时器
function Monomer:killTimer_UpdateVertexZ()
    if (self.hUpdateVertexZ) then
        scheduler.unscheduleGlobal(self.hUpdateVertexZ)
        self.hUpdateVertexZ = nil
    end
end

-- 更新Z轴计时器回调函数
function Monomer:updateVertexZ(fDelay)
    local point = cc.p(self:getPosition())
    local value = BgMap.getZOrder(point) -- z轴
    self:setLocalZOrder(value)
    
    if (not self.m_nMonomer) then
        return
    end
        
    if (g_mainScene:getCurrBgMap():getCurrentGridValue(MapPoint.new(point)) == 2) then
        if (self.m_nMonomer:getOpacity() == 128) then
            return
        end
            
        self.m_nMonomer:setOpacityEx(128)
        self.m_nMonomer:setColor(cc.c3b(166,166,166))
    else
        if (self.m_nMonomer:getOpacity() == 255) then
            return
        end
            
        self.m_nMonomer:setOpacityEx(255)
        self.m_nMonomer:setColor(cc.c3b(255,255,255))
    end
end

-- 添加攻击技能
function Monomer:addAttackSkill(skillNumber)
    local skillInfo = g_attackSkillSystem:getAttackSkillInfo(skillNumber)
    if (skillInfo) then
        self.m_mapAttackSkill[skillInfo.m_nNum] = skillInfo
        TextureController.addSpriteFrames(TexturePathType.SkillCaster, skillInfo.m_casterSpecificID)
        TextureController.addSpriteFrames(TexturePathType.SkillLocus, skillInfo.m_locusSpecificID)
        TextureController.addSpriteFrames(TexturePathType.SkillExplosion, skillInfo.m_explosionSpecificID)
    end
end

-- 删除攻击技能
function Monomer:subAttackSkill(skillNumber)
    local skillInfo = self.m_mapAttackSkill[skillNumber]
    if (skillInfo) then
        TextureController.subSpriteFrames(TexturePathType.SkillCaster, skillInfo.m_casterSpecificID)
        TextureController.subSpriteFrames(TexturePathType.SkillLocus, skillInfo.m_locusSpecificID)
        TextureController.subSpriteFrames(TexturePathType.SkillExplosion, skillInfo.m_explosionSpecificID)
    end
end

function Monomer:moveByBegin()

end

function Monomer:moveByEnd()
    self:stand()
end

function Monomer:goBegin()

end

function Monomer:goEnd()
    self:stand()
end

-- 攻击敌人
function Monomer:attackEnemy()
    if (not self.m_attackMonomerMajor) then
        return false
    end
        
    if (self.m_isCooling) then
        return false
    end
        
    self.m_isCooling = true
        
    self:stopActionByTag(TAG_MOVET)
        
    local nState = FigureState.Attack
    
    if (not self.m_attackSkillInfo) then
        self.m_attackSkillInfo = self.m_mapAttackSkill[1]
    end
        
    if (self.m_attackSkillInfo.m_nAttackType == 2) then
        nState = FigureState.Caster
    end
        
    local lenghtX = self.m_attackMonomerMajor:getPositionX() - self:getPositionX()
    local lenghtY = (self.m_attackMonomerMajor:getPositionY() - self:getPositionY()) * math.sqrt(2)
    local lenght = math.sqrt(lenghtX * lenghtX + lenghtY * lenghtY)
    local pointX = lenghtX / lenght
    local pointY = lenghtY / lenght
        
    local angle_X = math.acos(pointX) * 180 / math.pi
    local angle_Y = math.acos(pointY) * 180 / math.pi
        
    local angle = angle_X
    if (angle_Y > 90) then
        angle = 360 - angle_X
    end
        
    local nDirection = self:getDirectionType(angle)
    self:setFigureState(nState, nDirection)
    
    return true
end

-- 根据指定角度获取方向
function Monomer:getDirectionType(fAngle)
    local nDirection = FigureDirection.None
    
    local nType = math.floor(((math.floor(fAngle + 22.5)) % 360 ) / 45.0)
    
    if (nType == 0) then
        nDirection = FigureDirection.Right
    elseif (nType == 1) then
        nDirection = FigureDirection.RightAndUp
    elseif (nType == 2) then
        nDirection = FigureDirection.Up
    elseif (nType == 3) then
        nDirection = FigureDirection.LeftAndUp
    elseif (nType == 4) then
        nDirection = FigureDirection.Left
    elseif (nType == 5) then
        nDirection = FigureDirection.LeftAndDown
    elseif (nType == 6) then
        nDirection = FigureDirection.Down
    elseif (nType == 7) then
        nDirection = FigureDirection.RightAndDown
    end

    return nDirection
end

function Monomer:setCoolingFalse()
    self.m_isCooling = false
end

function Monomer:addAgainstMe(monomer, fBlood)
    if (self:getState() == FigureState.Death) then
        return
    end
    
    if (monomer:getState() == FigureState.Death) then
        return
    end
        
    local fairy = FlutteringFairy.addFairy(self, cc.p(0, self:getContentSize().height * 0.5), FairyType.SubBlood, self.m_blood-fBlood, handler(self, self.flutteringFairyFinish))
    self:pushFlutteringFairy(fairy)
    self:setBlood(fBlood)
    self:updateBloodProgress()

    local bFind = false
    for i = 1, #self.m_againstMeSet do
        local m = self.m_againstMeSet[i]
        if (m == monomer) then
            bFind = true
            break
        end
    end
    if (not bFind) then
        table.insert(self.m_againstMeSet, monomer)
    end
        
    if (self.m_blood > 0) then
        return
    end
        
    self:death()
end

function Monomer:detectionOfEachOther()
    
end

function Monomer:pushFlutteringFairy(fairy)
    if (#self.m_flutteringFairyDeque > 0) then
        for i = 1, #self.m_flutteringFairyDeque do
            local lastFairy = self.m_flutteringFairyDeque[i]
            local y = 30
            if (y > 0) then
                local moveBy = cc.MoveBy:create(0.15, cc.p(0, y))
                lastFairy:runAction(moveBy)
            end
        end
    end
    table.insert(self.m_flutteringFairyDeque, fairy)
end

function Monomer:flutteringFairyFinish()
    if (#self.m_flutteringFairyDeque > 0) then
        table.remove(self.m_flutteringFairyDeque, 1)
    end
end

function Monomer:detectionWhetherCounter()

end

-- 更新血条
function Monomer:updateBloodProgress()
    if (not self.bloodBg) then
        return
    end
        
    local rect = cc.rect(0,0,0,0)
    rect.width = self.bloodBg:getContentSize().width*self.m_blood/self.m_bloodCap
    rect.height = self.bloodIn:getContentSize().height
    rect.width = math.max(rect.width, 0)
    self.bloodIn:setTextureRect(rect)
end

function Monomer:removeAttackMonomerMajor(monomer)
    if (monomer == self.m_attackMonomerMajor) then
        self:setAttackMonomerMajor(nil)
    end
end

function Monomer:removeAgainstMe(monomer)
    for i = 1, #self.m_againstMeSet do
        local m = self.m_againstMeSet[i]
        if (m == monomer) then
            table.remove(self.m_againstMeSet, i)
            return
        end
    end
end

function Monomer:delayCallBack(fTime, callFunc)
    fTime = math.max(fTime, 0.0)
    local sequence = cc.Sequence:create(cc.DelayTime:create(fTime), cc.CallFunc:create(callFunc))
    self:runAction(sequence)
    return sequence
end

function Monomer:attacking()
    SkillEffectShow.playSkillEffect(self.m_attackSkillInfo, self, self.m_attackMonomerMajor, 0)
end

function Monomer:underAttack()
    self:setFigureState(FigureState.Stand, FigureDirection.None)
end

function Monomer:attackCompleted()
    self:setFigureState(FigureState.Stand, FigureDirection.None)
    self:delayCallBack(self.m_attackTime, handler(self, self.setCoolingFalse))
    self:delayCallBack(self.m_attackTime, handler(self, self.detectionOfEachOther)):setTag(TAG_FOLLOWATTACK)
end

function Monomer:deathActionFinish()
    self:setLocalZOrder(BgMap.getZOrderZero(g_mainScene:getCurrBgMap()))    -- z轴
end

function Monomer:getFigure()
    return self.m_nMonomer
end

function Monomer:getState()
    return self.m_nState
end

function Monomer:getDirection()
    return self.m_nDirection
end

function Monomer:getCanMoved()
    return self.m_isCanMoved
end

function Monomer:setCanMoved(bCanMoved)
    self.m_isCanMoved = bCanMoved
end

function Monomer:getRunSpeed()
    return self.m_runSpeed
end

function Monomer:setRunSpeed(runSpeed)
    self.m_runSpeed = runSpeed
end

function Monomer:getVisualRange()
    return self.m_visualRange
end

function Monomer:setVisualRange(visualRange)
    self.m_visualRange = visualRange
end

function Monomer:getBloodCap()
    return self.m_bloodCap
end

function Monomer:setBloodCap(bloodCap)
    self.m_bloodCap = bloodCap
end

function Monomer:getMagicCap()
    return self.m_magicCap
end

function Monomer:setMagicCap(magicCap)
    self.m_magicCap = magicCap
end

function Monomer:getBlood()
    return self.m_blood
end

function Monomer:setBlood(blood)
    self.m_blood = blood
end

function Monomer:getMagic()
    return self.m_magic
end

function Monomer:setMagic(magic)
    self.m_magic = m_magic
end

function Monomer:getTheAttack()
    return self.m_pTheAttack
end

function Monomer:setTheAttack(pTheAttack)
    self.m_pTheAttack = pTheAttack
end

function Monomer:getAttackTime()
    return self.m_attackTime
end

function Monomer:setAttackTime(attackTime)
    self.m_attackTime = attackTime
end

function Monomer:getAttackMonomerMajor()
    return self.m_attackMonomerMajor
end

function Monomer:setAttackMonomerMajor(attackMonomerMajor)
    self.m_attackMonomerMajor = attackMonomerMajor
end

return Monomer