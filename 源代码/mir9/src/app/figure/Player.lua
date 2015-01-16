local scheduler = require("framework.scheduler")
local MapPoint = require("app.map.MapPoint")
local PlayerController = require("app.figure.PlayerController")
local Monomer = require("app.figure.Monomer")
local GameLoading = require("app.scenes.GameLoading")

local TAG_MOVET = 0xfffff1
local TAG_FOLLOWATTACK = 0xfffff2
local TAG_COOLINGTIMEATTACK = 0xfffff3
local TAG_MOVETWAIT = 0xfffff4

-- 玩家类
local Player = class("Player", Monomer)

function Player:ctor()
    Player.super.ctor(self)
    
    self.m_isMoveActions = false
    self.m_willGoPoint = MapPoint.new(0, 0)
    
    local _playerController = PlayerController.sharePlayerController()
    self:setFigure(TexturePathType.Figure, _playerController.m_playerNumber)
    self:setHair(_playerController.m_hairNumber)
    self:setWeapon(_playerController.m_weaponsNumber)
    self:setTray()
    self:setBlood(100000)
    self:setBloodCap(100000)
    self:setTheAttack(2500)
    self:setVisualRange(100)
    self:addAttackSkill(1002)
    
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(...)
        self:update_(...)
    end)
    self:scheduleUpdate()
end

function Player:onEnter()
    Player.super.onEnter(self)
end

function Player:onExit()
    Player.super.onExit(self)
    self:stopAllActions()
    g_mainScene:getCurrBgMap():killTimer_UpdateMap()
    self:killTimer_DetectionReplaceBgMap()
end

function Player:update_(dt)
    if (not self.m_isMoveActions) then
        return
    end
    
    g_mainScene:getCurrBgMap():updateMap(dt)
    self:detectionReplaceBgMap(dt)
end

function Player:setTray()

end

function Player:detectionOfEachOther()
    Player.super.detectionOfEachOther(self)
    
    if (self.m_attackMonomerMajor) then
        self:detectionWhetherCounter()
    end
end

function Player:detectionWhetherCounter()
    self:followAttack()
end

function Player:runBy(mpoint)    
    local relust = Player.super.runBy(self, mpoint)
    
    if (relust.fTime ~= 0) then
        g_mainScene:insterMapPoint(self, relust.mpoint)
    end
    
    if (relust.fTime == 0 and relust.bIsCanNotFineTheWay == false) then
        self.m_willGoPoint = mpoint
        self:stopActionByTag(TAG_MOVETWAIT)
        self:delayCallBack(1 / 60.0, handler(self, self.waitRunBy)):setTag(TAG_MOVETWAIT)
        return relust
    end
        
    if (self.m_isMoveActions == false) then
--        g_mainScene:getCurrBgMap():setTimer_UpdateMap()
--        self:setTimer_DetectionReplaceBgMap()
        self.m_isMoveActions = true
    end
    
    return relust
end

function Player:waitRunBy()
    self:runBy(self.m_willGoPoint)
end

function Player:walkBy(mpoint)
    local relust = Player.super.walkBy(self, mpoint)
    
    if (relust.fTime ~= 0) then
        g_mainScene:insterMapPoint(self, relust.mpoint)
    end
    
    if (relust.fTime == 0 and relust.bIsCanNotFineTheWay == false) then
        self.m_willGoPoint = mpoint
        self:stopActionByTag(TAG_MOVETWAIT)
        self:delayCallBack(1 / 60.0, handler(self, self.waitWalkBy)):setTag(TAG_MOVETWAIT)
        return relust
    end
        
    if (self.m_isMoveActions == false) then
--        g_mainScene:getCurrBgMap():setTimer_UpdateMap()
--        self:setTimer_DetectionReplaceBgMap()
        self.m_isMoveActions = true
    end
    
    return relust
end

function Player:waitWalkBy()
    self:walkBy(self.m_willGoPoint)
end

function Player:goTo(mpoint)
    local relust = Player.super.goTo(self, mpoint)
    if (relust.fTime ~= 0 and relust.bIsCanNotFineTheWay == false) then
        g_mainScene:insterMapPoint(self, relust.mpoint)
    else
        self.m_willGoPoint = mpoint
        self:stopActionByTag(TAG_MOVETWAIT)
        self:delayCallBack(1 / 60.0, handler(self, self.waitGoTo)):setTag(TAG_MOVETWAIT)
    end

    return relust
end

function Player:waitGoTo()
    self:goTo(self.m_willGoPoint)
end

function Player:moveByEnd()
    if (g_mainScene:getPlayerMoveActions() == false) then
        Player.super.moveByEnd(self)
--        g_mainScene:getCurrBgMap():setTimer_UpdateMap()
--        self:setTimer_DetectionReplaceBgMap()
--        self.m_isMoveActions = false
    else
        g_mainScene:playerRunning()
    end
end

function Player:goBegin()
    Player.super.goBegin(self)
    
    if (self.m_isMoveActions) then
        return
    end

--    g_mainScene:getCurrBgMap():setTimer_UpdateMap()
--    self:setTimer_DetectionReplaceBgMap()
    self.m_isMoveActions = true
end

function Player:goEnd()
    Player.super.goEnd(self)
    g_mainScene:getCurrBgMap():killTimer_UpdateMap()
    self:killTimer_DetectionReplaceBgMap()
    self.m_isMoveActions = false
end

function Player:stand()
    Player.super.stand(self)
    self.m_isMoveActions = false
    self:detectionPropItems()
end

function Player:addAgainstMe(monomer, blood)
    Player.super.addAgainstMe(self, monomer, blood)
--    if (monomer) then
--        self:hurt()
--    end
    if (not self.m_attackMonomerMajor) then
        g_mainScene:showSelected(monomer)
    end
end

function Player:attackEnemy()
    self:stopActionByTag(TAG_COOLINGTIMEATTACK)
    local progress = g_mainScene:getGameInfoUIController():getOperationMenu():getCurrProgress()
    
    if (self.m_isCooling) then
        self:delayCallBack(0.1, handler(self, self.attackEnemy)):setTag(TAG_COOLINGTIMEATTACK)
        return false
    end
        
    if (not Player.super.attackEnemy(self)) then
        self:delayCallBack(0.1, handler(self, self.attackEnemy)):setTag(TAG_COOLINGTIMEATTACK)
        return false
    end
        
    if (progress) then
        progress:RunCoolingAction(self.m_attackSkillInfo.m_coolingTime)
    end
        
    return true
end

function Player:followAttack()
    Player.super.followAttack(self)
end

function Player:death()
    Player.super.death(self)
end

function Player:detectionReplaceBgMap(delay)
    local curBgMap = g_mainScene:getCurrBgMap()
    local mapPassageway = curBgMap:isMapPassageway(self)
    if (not mapPassageway:equals(PortalInformationZero)) then
        self:goTo(MapPoint.new(mapPassageway.point))
        --self:stopAllActions()
        --g_mainScene:getCurrBgMap():startUpdateMap()
        --self:startDetectionReplaceBgMap()
        --self:unscheduleUpdateVertexZ()
        GameLoading.runGameLoading(mapPassageway.mapID, mapPassageway.born)
        -- g_mainScene:replaceBgMap(mapPassageway.mapID, mapPassageway.born)
    end
end

function Player:detectionPropItems(delay)
    local x, y = self:getPosition()
    local position = MapPoint.new(x, y)
    
    local show = g_mainScene:getMapPointForProp(position)
    if (show) then
        g_mainScene:eraseMapPointForProp(position)
        show:removeFromParent()
    end
end

function Player:setBlood(var)
    Player.super.setBlood(self, var)
    if (g_mainScene:getGameInfoUIController()) then
        g_mainScene:getGameInfoUIController():updateBloodPro()
    end
end

function Player:setMagic(var)
    Player.super.setMagic(self, var)
    if (g_mainScene:getGameInfoUIController()) then
        g_mainScene:getGameInfoUIController():updateMagicPro()
    end
end

function Player:clearData()
    Player.super.clearData(self)
    self.m_isMoveActions = false
end

function Player:attacking()
    Player.super.attacking(self)
end

function Player:underAttack()
    
end

function Player:setFigureState(state, direction)
    Player.super.setFigureState(self, state, direction)
end

function Player:setTimer_DetectionReplaceBgMap()
    self:killTimer_DetectionReplaceBgMap()
    self.hDetectionReplaceBgMap = scheduler.scheduleGlobal(handler(self, self.detectionReplaceBgMap), 0.1)
end

function Player:killTimer_DetectionReplaceBgMap()
    if (self.hDetectionReplaceBgMap) then
        scheduler.unscheduleGlobal(self.hDetectionReplaceBgMap)
        self.hDetectionReplaceBgMap = nil
    end
end

return Player