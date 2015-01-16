local scheduler = require("framework.scheduler")
local AttackSkillSystem = require("app.skill_system.AttackSkillSystem")
local NpcInfoSystem = require("app.map.NpcInfoSystem")
local PropSystem = require("app.prop_system.PropSystem")
local MapPoint = require("app.map.MapPoint")
local BgMap = require("app.map.BgMap")
local Player = require("app.figure.Player")
local Enemy = require("app.figure.Enemy")
local TextureController = require("app.figure.TextureController")
local PathAStar = require("app.map.PathAStar")
local CCTouchMouse = require("app.game_ui.CCTouchMouse")
local GameInfoUIController = require("app.game_ui.GameInfoUIController")
local GameLoading = require("app.scenes.GameLoading")

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

    
function MainScene:ctor()
--    ui.newTTFLabel({text = "Hello, World", size = 64, align = ui.TEXT_ALIGN_CENTER})
--        :pos(display.cx, display.cy)
--        :addTo(self)

    self.m_ptPlayerDirection = cc.p(0, 0) 
    self.m_touchMouse = nil
    self.m_bTouchProtected = false
    self.m_bIsPlayerMoveActions = false 
    self.m_bgMap = nil
    self.m_gameInfoUIController = nil
    self.m_mapEnemy = {}
    self.m_mapOtherPlayer = {}
    self.m_mapMPoint = {}
    self.m_waitReincarnationEnemy = nil
    self.m_mapProp = {}
    self.m_enemyDictionary = {}
    
    self:init()
end

function MainScene:onEnter()
    self.hPlayerMovement = scheduler.scheduleGlobal(handler(self, self.playerMovement), 0.5)
end

function MainScene:onExit()
    if (self.hPlayerMovement) then
        scheduler.unscheduleGlobal(self.hPlayerMovement)
        self.hPlayerMovement = nil
    end
end

function MainScene:init()
    g_mainScene = self
    
    self.m_mapPoint = {}
    self.m_bgMap = nil

    display.addSpriteFramesWithFile("texture_set/blood_return.plist", "texture_set/blood_return.png")

    g_attackSkillSystem = AttackSkillSystem.new()
    g_npcInfoSystem = NpcInfoSystem.new()
    g_propSystem = PropSystem.new()
    
    g_player = Player.new()
    g_player:retain()
    
    -- create touch layer
    self.layer = display.newLayer()
    self.layer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "began" then
            return self:onTouchBegan(event)
        elseif event.name == "moved" then
            self:onTouchMoved(event)
        elseif event.name == "ended" then
            self:onTouchEnded(event)
        elseif event.name == "cancel" then
            self:onTouchCancelled(event)
        end
    end)
    self:addChild(self.layer, -10000)

    self.layer:setTouchEnabled(true)
        
    self.m_spSel = display.newSprite("ui/tray_self.png")
    self.m_spSel:retain()
    
    self.m_touchMouse = CCTouchMouse.new()
    self.m_touchMouse:retain()
    
    self:replaceBgMap(GameLoading.m_mapID, GameLoading.m_born)
    
    --self:replaceBgMap(200, 1)
    --self:replaceBgMap(100, 4)
    
    self.m_gameInfoUIController = GameInfoUIController.new()
    self:addChild(self.m_gameInfoUIController)

    return true
end

function MainScene:replaceBgMap(nMapID, nBorn)
    self.m_mapMPoint = {}
    
    if (self.m_bgMap) then
        self.m_mapMPoint = {}
        self.m_bgMap:unloadMap()
        self.m_bgMap:removeFromParent()
    end
    
    --g_player = nil
    --g_player = Player.new()
    
    local player = g_player
    player:stand()
    
    self.m_enemyDictionary = {}
--    m_otherDictionary->removeAllObjects();
    
    local bgMap = BgMap.new()
    self:setCurrBgMap(bgMap)
    bgMap:loadMap(nMapID)
    bgMap:setDelegate(self)
    self:addChild(bgMap, -1)
    bgMap:addChildPlayerLead(player, nBorn)
    self.m_touchMouse:setPosition(-100, -100)
    bgMap:addChild(self.m_touchMouse, BgMap.getZOrderZero(bgMap))
    self.m_waitReincarnationEnemy = bgMap:getEnemeyMap()
    
    self.m_nEnemyID = 1000
    for i = 1, #self.m_waitReincarnationEnemy do
        local t = self.m_waitReincarnationEnemy[i]
        self:addEnemy(t.key, t.mpoint, self.m_nEnemyID)
        self.m_nEnemyID = self.m_nEnemyID + 1
    end
    
    self.m_waitReincarnationEnemy = {}
end

function MainScene:setCurrBgMap(bgMap)
    self.m_bgMap = bgMap
end

function MainScene:getCurrBgMap()
    return self.m_bgMap
end
    
-- 脱离战斗
function MainScene:OutOfCombat()
    self:showSelected(nil)
    self.m_gameInfoUIController:getOperationMenu():cancelHangUP()
end

function MainScene:isPointValid(mpoint)
    if (self.m_bgMap:getCurrentGridValue(mpoint) == 1) then
        return false
    end
    
    if (self:getMapPoint(mpoint)) then
        return false
    end
    
    return true
end

function MainScene:touchProtected()
    if (self.m_bTouchProtected == false) then
        return
    end
        
    self:stopActionByTag(0xff99)
    self.m_bTouchProtected = true
    local delayTime = cc.DelayTime:create(0.5)
    local callFunc = cc.CallFunc:create(handler(self, self.untouchProtected))
    local array = CCArray:create()
    array:addObject(delayTime)
    array:addObject(callFunc)
    local sequence = cc.Sequence:create(array)
    sequence:setTag(0xff99)
    self:runAction(sequence)
end

function MainScene:untouchProtected()
    self.m_bTouchProtected = false
end

function MainScene:updateImageDisplay(rcShow, rcHide)
    for key, enemy in pairs(self.m_enemyDictionary) do
        if (rcShow:containsPoint(cc.p(enemy:getPosition()))) then
            enemy:showFigure()
        end
        if (not rcHide:containsPoint(cc.p(enemy:getPosition()))) then
            enemy:hideFigure()
        end
    end
    
--    CCArray* otherPlayerKeys = m_otherDictionary->allKeys();
--    if (otherPlayerKeys)
--    {
--        for (unsigned int i=0; i<otherPlayerKeys->count(); i++)
--        {
--            int key = ((CCInteger*)otherPlayerKeys->objectAtIndex(i))->getValue();
--            OtherPlayer* otherPlayer = (OtherPlayer*)m_otherDictionary->objectForKey(key);
--            if (showRect.containsPoint(otherPlayer->getPosition()))
--            {
--                otherPlayer->showFigure();
--            }
--            if (!hideRect.containsPoint(otherPlayer->getPosition()))
--            {
--                otherPlayer->hideFigure();
--            }
--        }
--    }
end

function MainScene:insterMapPoint(monomer, mpoint)
    self.m_mapMPoint[monomer] = mpoint:getValue()
end

function MainScene:eraseMapPoint(monomer)
    self.m_mapMPoint[monomer] = nil
end

function MainScene:getMapPoint(mpoint)
    local bRet = false
    local value = mpoint:getValue()
    
    for k, v in pairs(self.m_mapMPoint) do
        if (v == value) then
            bRet = true
            break
        end
    end
    
    return bRet
end

function MainScene:insterMapPointForProp(var, mpoint)
    local value = mpoint:getValue()
    if (not self.m_mapProp[value]) then
        return false
    end
        
    self.m_mapProp[value] = var
    return true
end

function MainScene:eraseMapPointForProp(mpoint)
    self.m_mapProp[mpoint:getValue()] = nil
end

function MainScene:getMapPointForProp(mpoint)
    return self.m_mapProp[mpoint:getValue()]
end

function MainScene:getPath(beginMPoint, endMPoint)
    local dequeMPoint = PathAStar.findPathByAStar(
        self.m_bgMap:getMapGrid(),
        self.m_bgMap:getGridRow(),
        self.m_bgMap:getGridCol(),
        4096, beginMPoint, endMPoint)

    local relust = {}
    
    local i = 1
    local endIndex = (#dequeMPoint) + 1
    
    while (i ~= endIndex) do
        if (i + 1 == endIndex) then
            table.insert(relust, dequeMPoint[i])
            break
        end
        
        local p1 = dequeMPoint[i]
        local p2 = dequeMPoint[i+1]
        
        if (#relust > 0 and MapPoint.equals(MapPoint.mul(MapPoint.sub(p1, relust[#relust]), 2), MapPoint.sub(p2, relust[#relust]))) then
            table.insert(relust, p2)
            i = i + 2
        else
            table.insert(relust, p1)
            i = i + 1
        end
    end
    
    return relust
end

function MainScene:getPathNextRunGrid(beginMPoint, endMPoint)
    local dequeMPoint = PathAStar.findPathByAStar(
        self.m_bgMap:getMapGrid(),
        self.m_bgMap:getGridRow(),
        self.m_bgMap:getGridCol(),
        64, beginMPoint, endMPoint)
    
    local relust = {}
    table.insert(relust, dequeMPoint[1])
    
    while (#dequeMPoint > 3) do
        table.remove(dequeMPoint)
    end
    
    if (#dequeMPoint == 2) then
        local p = dequeMPoint[2]
        table.insert(relust, p)
    elseif (#dequeMPoint > 2) then
        local p1 = dequeMPoint[2]
        local p2 = dequeMPoint[3]
        
        if (MapPoint.sub(p2, dequeMPoint[1]):equalsObj(MapPoint.sub(p1, dequeMPoint[1]):mul(2))) then
            table.insert(relust, p2)
        else
            table.insert(relust, p1)
        end
    end
    
    return relust
end

function MainScene:getPathNextWalkGrid(beginMPoint, endMPoint)
    local dequeMPoint = PathAStar.findPathByAStar(
        self.m_bgMap:getMapGrid(),
        self.m_bgMap:getGridRow(),
        self.m_bgMap:getGridCol(),
        64, beginMPoint, endMPoint)

    while (#dequeMPoint > 2) do
        table.remove(dequeMPoint)
    end
    
    return dequeMPoint
end

function MainScene:onTouchBegan(event)
    local point = cc.p(event.x, event.y)
    point = self.m_bgMap:convertToNodeSpace(point)
    
    if (not self:isVisible()) then
        return false
    end
    
    if (self.m_bTouchProtected) then
        return false
    end

    if (self:getSelected()) then
        if (self:getSelected():getRect():containsPoint(point)) then
            self.m_gameInfoUIController:getOperationMenu():commonAttack()
            return true
        else
            self:showSelected(nil)
        end
    end
        
--    CCArray* otherKeys = m_otherDictionary->allKeys()
--    if (otherKeys)
--    {
--        for (int i=0; i<otherKeys->count(); i++)
--        {
--            int key = ((CCInteger*)otherKeys->objectAtIndex(i))->getValue();
--            Monomer* mon = (Monomer*)m_otherDictionary->objectForKey(key);
--            if (mon->getRect().containsPoint(point))
--            {
--                this->showSelected(mon);
--                break;
--            }
--        }
--    }

    if (self.m_enemyDictionary) then
        for key, enemy in pairs(self.m_enemyDictionary) do
            if (enemy:getRect():containsPoint(point)) then
                self:showSelected(enemy)
                g_player:setAttackMonomerMajor(enemy)
                return true
            end
        end
    end

    if (not self:getSelected()) then
        self.m_ptPlayerDirection = self.m_bgMap:convertToWorldSpace(point)
        self:beginMoveActions()
        self:touchProtected()
        self.m_gameInfoUIController:getOperationMenu():cancelHangUP()
    end
    
--    this->unschedule(schedule_selector(MainScene:log));
--    this->schedule(schedule_selector(MainScene:log));
    return true
end

function MainScene:onTouchMoved(event)    
    if (not self.m_bIsPlayerMoveActions) then
        return
    end
    local point = cc.p(event.x, event.y)
    point = self.m_bgMap:convertToNodeSpace(point)
    self.m_ptPlayerDirection = self.m_bgMap:convertToWorldSpace(point)
    if (g_player:getState() ~= FigureState.Stand) then
        return
    end
    self:beginMoveActions()
end

function MainScene:onTouchEnded(event)
    self:stopMoveActions()
end

function MainScene:onTouchCancelled(event)
    
end

function MainScene:removeEnemy(enemy)
    table.insert(self.m_waitReincarnationEnemy, {["key"] = enemy:getRoleNumber(), ["mpoint"] = enemy:getDenPos()})
    self.m_mapMPoint[enemy] = nil
    self.m_enemyDictionary[enemy:getEnemyID()] = nil
    if (enemy == self:getSelected()) then
        self:showSelected(nil)
    end
    local fTime = math.random() * 5 + 3
    local callFunc = cc.CallFunc:create(handler(self, self.addEnemy_))
    local array = CCArray:create()
    array:addObject(cc.DelayTime:create(fTime))
    array:addObject(callFunc)
    local sequence = cc.Sequence:create(array)
    self:runAction(sequence)
    
    self.m_gameInfoUIController:getOperationMenu():intelligentSearch()
end

function MainScene:addEnemy(num, mpoint, tag)
    local enemy = Enemy.new(tag, num, 0)
    enemy:setPosition(mpoint:getCCPointValue())
    enemy:setDenPos(MapPoint.new(cc.p(enemy:getPosition())))
    self.m_bgMap:addChild(enemy)
    enemy:updateVertexZ()
    enemy:setAttackTime(1.0)
    
    if (num == 11000) then
        enemy:setBlood(32000)
        enemy:setBloodCap(32000)
        enemy:setTheAttack(500)
    elseif (num == 12000) then
        enemy:setBlood(128000)
        enemy:setBloodCap(128000)
        enemy:setTheAttack(1500)
    elseif (num == 30000) then
        enemy:setBlood(4000)
        enemy:setBloodCap(4000)
        enemy:setTheAttack(50)
        enemy:setActive(false)
    elseif (num == 26000) then
        enemy:setBlood(16000)
        enemy:setBloodCap(16000)
        enemy:setTheAttack(100)
        enemy:setCanMoved(false)
    else
        enemy:setBlood(8000)
        enemy:setBloodCap(8000)
        enemy:setTheAttack(30)
        enemy:setActive(false)
    end
    
    enemy:patrol()
    
    self.m_enemyDictionary[enemy:getEnemyID()] = enemy
    enemy:setTag(tag)
end

function MainScene:addEnemy_()
    local t = self.m_waitReincarnationEnemy[1]
    self:addEnemy(t.key, t.mpoint, self.m_nEnemyID)
    self.m_nEnemyID = self.m_nEnemyID + 1
    table.remove(self.m_waitReincarnationEnemy, 1)
end

function MainScene:getMonmerVecIsLenght(point, lenght)
    local arrEnemy = {}
    local mapEnemy = self.m_enemyDictionary
    if (mapEnemy) then
        for key, enemy in pairs(mapEnemy) do
            local x = point.x - enemy:getHurtPoint().x
            local y = point.y - enemy:getHurtPoint().y
            y = y / math.sqrt(2)
            if (math.sqrt(x * x + y * y) <= lenght) then
                table.insert(arrEnemy, enemy)
            end
        end
    end
    return arrEnemy
end

function MainScene:playerMovement(dt)
    if (not self.m_bgMap) then
        return
    end
    
    local arrEnemy = self:getMonmerVecIsLenght(cc.p(g_player:getPosition()), MapPoint.new(6, 1):getCCSizeValue().width)
    for i = 1, #arrEnemy do
        local enemy = arrEnemy[i]
        if ((enemy:getAttackMonomerMajor()) or (enemy:getActive() == false)) then
        else
            enemy:followAttackAndSetAttackMethods(g_player, 0)
        end
    end
end

-- 获取玩家的方向
function MainScene:getPlayerDirection()
    local relust
    
    local ptBegin = cc.p(g_player:getPosition())
    local ptEnd = cc.p(self.m_bgMap:convertToNodeSpace(self.m_ptPlayerDirection))
    
    local lenghtX = ptEnd.x - ptBegin.x
    local lenghtY = ptEnd.y - ptBegin.y
    local lenght = cc.PointDistance(ptBegin, ptEnd)
    local angle_X = math.acos(lenghtX / lenght) * 180 / math.pi
    local angle_Y = math.acos(lenghtY / lenght) * 180 / math.pi
    
    local angle = angle_X
    if (angle_Y > 90) then
        angle = 360 - angle_X
    end
    angle = angle * (math.pi / 180)
    local x = math.cos(angle)
    local y = math.sin(angle)
    local tan = math.abs(math.tan(angle))
    local tanMin = math.tan(22.5 * math.pi / 180)
    local tanMax = math.tan(67.5 * math.pi / 180)
    
    if (tanMin <= tan and tan < tanMax) then
        relust = MapPoint.new(x / math.abs(x), y / math.abs(y))
    elseif (tan < tanMin) then
        relust = MapPoint.new(x / math.abs(x), 0)
    else
        relust = MapPoint.new(0, y / math.abs(y))
    end
    
    relust = relust:mul(2)
    return relust
end

function MainScene:playerRunning(fDelay)
    if (self.m_gameInfoUIController:getOperationMenu():getMoveMethods() == 0) then
        g_player:runBy(self:getPlayerDirection())
    elseif (self.m_gameInfoUIController:getOperationMenu():getMoveMethods() == 1) then
        g_player:walkBy(self:getPlayerDirection())
    end
end

function MainScene:beginMoveActions()
    if (self.m_gameInfoUIController:getOperationMenu():getMoveMethods() == 2) then
        local point = self.m_bgMap:convertToNodeSpace(self.m_ptPlayerDirection)
        local mpoint = MapPoint.new(point)
        g_player:goTo(mpoint)
        self.m_touchMouse:playEffect(mpoint:getCCPointValue())
        return
    end
        
    if (g_player:isMoveRunning()) then
        return
    end
    self.m_bIsPlayerMoveActions = true
    g_player:setAttackMonomerMajor(nil)
    self:OutOfCombat()
    self:playerRunning()
end

function MainScene:stopMoveActions()
    self.m_bIsPlayerMoveActions = false
    self.m_ptPlayerDirection = cc.p(0, 0)
end

--function MainScene:AccurateMoveActions(point)
--    if (not m_isPlayerMoveActions) then
--        return
--    end
--    if (Player.sharePlayer():isMoveRunning()) then
--        return
--    end
--    self.m_playerDirection = point:getCCPointValue()
--    if (Player.sharePlayer():getState() ~= FigureState.Stand) then
--        return
--    end
--    self:beginMoveActions()
--end
--
--function MainScene:keyBackClicked()
----    if (CCDirector::sharedDirector()->getRunningScene()->getChildByTag(0xffffff)) then
----        return;
----    end
----    
----    LAlertView* alert = LAlertView::create("提示", "是否退出游戏?");
----    alert->addButtonWithTitle("是");
----    alert->addButtonWithTitle("否");
----    alert->show(this, Alert_selector(MainScene:alertCallBack));
----    alert->setTag(0xffffff);
--end
--
--function MainScene:keyMenuClicked()
--    
--end
--
--function MainScene:alertCallBack(nNum)
--    if (nNum == 0) then
--        CCDirector::sharedDirector()->end()
--    end
--end
--
--function MainScene:log(dt)
--    --MapPoint p = MapPoint(m_gMapPoint[Player::sharePlayer()])
--    --MapPoint q = MapPoint(Player::sharePlayer()->getPosition())
--    -- CCLog("playerRunning x=%d, z=%d, x=%d, z=%d ", p.x, p.z, q.x ,q.z)
--end

function MainScene:showSelected(monomer)
    if (self.m_spSel:getParent()) then
        self.m_spSel:removeFromParent()
    end
    
    if (monomer) then
        local x = monomer:getAnchorPoint().x * monomer:getContentSize().width
        local y = monomer:getAnchorPoint().y * monomer:getContentSize().height
        self.m_spSel:setPosition(x, y)
        monomer:addChild(self.m_spSel, -1)
        self.m_gameInfoUIController:getAttackEnemyInfo():showAttackInfo(monomer)
    end
end

function MainScene:getSelected()
    local monomer = self.m_spSel:getParent()
    if (not monomer) then
        if (self.m_gameInfoUIController:getAttackEnemyInfo()) then
            self.m_gameInfoUIController:getAttackEnemyInfo():hide()
        end
    end
    return monomer
end

function MainScene:getPlayerMoveActions()
    return self.m_bIsPlayerMoveActions
end

function MainScene:getEnemyDictionary()
    return self.m_enemyDictionary
end

function MainScene:getGameInfoUIController()
    return self.m_gameInfoUIController
end

return MainScene
