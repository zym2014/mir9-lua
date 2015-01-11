local MapPoint = require("app.map.MapPoint")
local ProgressAutomatic = require("app.game_ui.ProgressAutomatic")
local GameLoading = require("app.scenes.GameLoading")

local TAG_PROGRESS_SKILL = 0xfffff

local LOperationMenu = class("LOperationMenu", function()
    return display.newLayer()
end)

function LOperationMenu:ctor()
    self.m_isHangUpAttack = false
    self.m_attackMethods = 1001
    self.m_moveMethods = 0
    self.m_direction = nil
    self.m_currProgress = nil
    self.m_operation = nil
    self:init()
end

function LOperationMenu:init()
    self.m_operation = CCNode:create()
    self.m_operation:setPosition(display.width, 0)
    self:addChild(self.m_operation)
    
    local PUSH_BUTTON_IMAGES = {
        normal = "ui/attack_normal.png",
        pressed = "ui/attack_selected.png",
        disabled = "ui/attack_normal.png",
    }

    local szBtn = cc.size(90, 90)
    local ptBtn = cc.PointAdd(cc.p(10, 10), cc.p(szBtn.width/2, szBtn.height/2))
    
    self.m_btnCommonAttack = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
    self.m_btnCommonAttack:setAnchorPoint(0.5, 0.5)
    self.m_btnCommonAttack:setButtonSize(szBtn.width, szBtn.height)
    self.m_btnCommonAttack:setPosition(-ptBtn.x, ptBtn.y)
    self.m_btnCommonAttack:onButtonClicked(handler(self, self.commonAttack))
    self.m_operation:addChild(self.m_btnCommonAttack)
    
    PUSH_BUTTON_IMAGES = {
        normal = "ui/groove_normal.png",
        pressed = "ui/groove_selected.png",
        disabled = "ui/groove_normal.png",
    }
    
    szBtn = cc.size(75, 75)
    ptBtn = {
        cc.PointAdd(cc.p(120, 10), cc.p(szBtn.width/2, szBtn.height/2)),
        cc.PointAdd(cc.p(110, 110), cc.p(szBtn.width/2, szBtn.height/2)),
        cc.PointAdd(cc.p(10, 120), cc.p(szBtn.width/2, szBtn.height/2))
    }
    
    self.m_btnSkillAttack = {}
    for i = 1, 3 do
        self.m_btnSkillAttack[i] = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
        self.m_btnSkillAttack[i]:setAnchorPoint(0.5, 0.5)
        self.m_btnSkillAttack[i]:setButtonSize(szBtn.width, szBtn.height)
--        self.m_btnSkillAttack[i].getButtonSize = function() -- UIPushButton:getContentSize()获取不了按钮大小
--            return cc.size(self.m_btnSkillAttack[i].scale9Size_[1], self.m_btnSkillAttack[i].scale9Size_[2])
--        end
        self.m_btnSkillAttack[i]:setPosition(-ptBtn[i].x, ptBtn[i].y)
        self.m_btnSkillAttack[i]:onButtonClicked(handler(self, self.skillAttack))
        self.m_operation:addChild(self.m_btnSkillAttack[i], 0, 0)
    end
    
    szBtn = cc.size(60, 60)
    ptBtn = cc.PointAdd(cc.p(210, 90), cc.p(szBtn.width/2, szBtn.height/2))
    
    self.m_btnDrugs = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
    self.m_btnDrugs:setAnchorPoint(0.5, 0.5)
    self.m_btnDrugs:setButtonSize(szBtn.width, szBtn.height)
    self.m_btnDrugs:setPosition(-ptBtn.x, ptBtn.y)
    self.m_btnDrugs:onButtonClicked(handler(self, self.useDrugs))
    self.m_operation:addChild(self.m_btnDrugs)
    
    szBtn = cc.size(60, 60)
    ptBtn = cc.PointAdd(cc.p(10, 215), cc.p(szBtn.width/2, szBtn.height/2))
    
    self.m_btnDelivery = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
    self.m_btnDelivery:setAnchorPoint(0.5, 0.5)
    self.m_btnDelivery:setButtonSize(szBtn.width, szBtn.height)
    self.m_btnDelivery:setPosition(-ptBtn.x, ptBtn.y)
    self.m_btnDelivery:onButtonClicked(handler(self, self.useDeliveryProp))
    self.m_operation:addChild(self.m_btnDelivery, 0, 0)
    
    PUSH_BUTTON_IMAGES = {
        normal = "ui/direction_head.png",
        pressed = "ui/direction_head.png",
        disabled = "ui/direction_head.png",
    }
    
    self.m_btnHangUp = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
    self.m_btnHangUp:setAnchorPoint(0.5, 0.5)
    self.m_btnHangUp:setButtonSize(95, 95)
    self.m_btnHangUp:setPosition(display.width-250, display.height-100)
    self.m_btnHangUp:setButtonLabel("normal", ui.newTTFLabel({
        text = "自动攻击",
        fontName = "fonts/Marker Felt.ttf",
        size = 15
    }))
    self.m_btnHangUp:onButtonClicked(handler(self, self.hangUpAttack))
    self:addChild(self.m_btnHangUp, 0, 0xfffffff0)
    
    local btnMoveMethods = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
    btnMoveMethods:setAnchorPoint(0.5, 0.5)
    btnMoveMethods:setButtonSize(95, 95)
    btnMoveMethods:setPosition(100, display.height-200)
    btnMoveMethods:setButtonLabel("normal", ui.newTTFLabel({
        text = "取消跑步",
        fontName = "fonts/Marker Felt.ttf",
        size = 15
    }))
    btnMoveMethods:onButtonClicked(handler(self, self.moveMethods))
    self:addChild(btnMoveMethods)
    
    --self:addSkillIcon(1, 1002)
	self:addSkillIcon(2, 2007)
	self:addSkillIcon(3, 2005)
    return true
end

function LOperationMenu:getSkillAttackBtn(number)
    if (number > 3 or number <= 0) then
        return nil
    end
    
    return self.m_btnSkillAttack[number]
end

function LOperationMenu:addSkillIcon_(btn, skillNumber)
    g_player:subAttackSkill(btn:getTag())
    
    if (btn:getChildByTag(TAG_PROGRESS_SKILL) == self.m_currProgress) then
        self.m_currProgress = nil
    end
    btn:removeChildByTag(TAG_PROGRESS_SKILL)

    for i = 1, 3 do
        if (skillNumber == self.m_btnSkillAttack[i]:getTag()) then
            if (self.m_btnSkillAttack[i]:getChildByTag(TAG_PROGRESS_SKILL) == self.m_currProgress) then
                self.m_currProgress = nil
            end
            self.m_btnSkillAttack[i]:removeChildByTag(TAG_PROGRESS_SKILL)
            self.m_btnSkillAttack[i]:setTag(0)
        end
    end
    
    local str = string.format("ui/skill/skill_%d.png", skillNumber)
    local texture = CCTextureCache:sharedTextureCache():addImage(str)
    if (texture) then
        local progressTimer = ProgressAutomatic.new(CCSprite:createWithTexture(texture))
        progressTimer:setType(kCCProgressTimerTypeRadial)
        --local szBtn = btn:getContentSize()
        local szBtn = cc.size(0, 0)
        progressTimer:setPosition(szBtn.width/2, szBtn.height/2)
        btn:addChild(progressTimer, 1, TAG_PROGRESS_SKILL)
        progressTimer:setPercentage(100)

        progressTimer:setScale(1.8)
    end
    
    btn:setTag(skillNumber)
    
    g_player:addAttackSkill(skillNumber)
end

function LOperationMenu:addSkillIcon(btnNumber, skillNumber)
    local btn = self.m_btnSkillAttack[btnNumber]
    self:addSkillIcon_(btn, skillNumber)
end

function LOperationMenu:addDrugs(drugsNumber)
    self.m_drugsBtn:removeChildByTag(TAG_PROGRESS_SKILL)
    
    local str = string.format("ui/skill/skill_%d.png", drugsNumber)
    local sprite = display(str)
    local szBtn = self.m_btnDrugs:getContentSize()
    sprite:setPosition(szBtn.width / 2, szBtn.height / 2)
    self.m_btnDrugs:addChild(sprite, 1, TAG_PROGRESS_SKILL)
    sprite:setScale(1.2)
    
    self.m_btnDrugs:setTag(drugsNumber)
end

-- 普通攻击按钮
function LOperationMenu:commonAttack(event)
    self.m_currProgress = nil
    self.m_attackMethods = 1001
    self:attack()
end

-- 技能攻击按钮
function LOperationMenu:skillAttack(event)
    local btn = event.target
    if (btn:getTag() == 0) then
        return
    end
    
    self.m_currProgress = btn:getChildByTag(TAG_PROGRESS_SKILL)
    self.m_attackMethods = btn:getTag()
    self:attack()
end

-- 使用药物疗伤按钮
function LOperationMenu:useDrugs(event)
    g_player:bloodReturn(5000)
    self.m_btnDrugs:removeChildByTag(TAG_PROGRESS_SKILL)
    self.m_btnDrugs:setTag(0)
end

-- 使用传送卷按钮
function LOperationMenu:useDeliveryProp(event)
    local r = math.random()

    if (r == 1) then
        r = 0
    end
    
    GameLoading.runGameLoading(100, r * 4 + 1)
    --g_mainScene:replaceBgMap(100, r * 4 + 1)
end

function LOperationMenu:skillAttackCooling(progress)
    
end

-- 攻击
function LOperationMenu:attack()
    if (not g_mainScene:getSelected()) then
        g_mainScene:showSelected(g_player:getAgainstMeOfFirst())
    end
    
    local attackMonomerMajor = g_mainScene:getSelected()
    
    if (not attackMonomerMajor) then
        local ptPlayer = MapPoint.new(cc.p(g_player:getPosition()))
        local array = {}
        local mapEnemy = g_mainScene:getEnemyDictionary()
        if (mapEnemy) then
            for key, enemy in pairs(mapEnemy) do
                local ptEnemy = MapPoint.new(cc.p(enemy:getPosition()))
                if (ptPlayer:getDistance(ptEnemy) <= g_player:getVisualRange()) then
                    table.insert(array, enemy)
                end
            end
        end
        
        for i = 1, #array do
            local enemy = array[i]
            
            if (not attackMonomerMajor) then
                attackMonomerMajor = enemy
            else
                local ptEnemy = MapPoint.new(cc.p(enemy:getPosition()))
                local ptAttackMonomer = MapPoint.new(cc.p(attackMonomerMajor:getPosition()))
                if (ptPlayer:getDistance(ptEnemy) < ptPlayer:getDistance(ptAttackMonomer)) then
                    attackMonomerMajor = enemy
                end
            end
        end
        
        g_mainScene:showSelected(attackMonomerMajor)
    end
    
    if (attackMonomerMajor) then
        g_player:followAttackAndSetAttackMethods(attackMonomerMajor, self.m_attackMethods)
    end
end

function LOperationMenu:hangUpAttack(event)
    local flag = false
    local mapEnemy = g_mainScene:getEnemyDictionary()
    if (mapEnemy) then
        for key, enemy in pairs(mapEnemy) do
            local ptPlayer = MapPoint.new(cc.p(g_player:getPosition()))
            local ptEnemy = MapPoint.new(cc.p(enemy:getPosition()))
            if (ptPlayer:getDistance(ptEnemy) <= g_player:getVisualRange()) then
                flag = true
                break
            end
        end
    end
    
    if (not flag) then
        return 
    end
    
    if (self.m_isHangUpAttack) then
        self.m_isHangUpAttack = false
        self.m_btnHangUp:setButtonLabelString("normal", "自动攻击")
    else
        self.m_isHangUpAttack = true
        self:attack()
        self.m_btnHangUp:setButtonLabelString("normal", "停止自动")
    end
end

function LOperationMenu:intelligentSearch()
    if (self.m_isHangUpAttack) then
        local array = CCArray:create()
        array:addObject(cc.DelayTime:create(0.1))
        array:addObject(cc.CallFunc:create(handler(self, self.attack)))
        local sequence = cc.Sequence:create(array)
        self:runAction(sequence)
        
        if (g_player:getBloodCap()/4 >= g_player:getBlood()) then
            g_player:bloodReturn(g_player:getBloodCap())
        end
    end
end

function LOperationMenu:cancelHangUP()
    if (self.m_isHangUpAttack) then
        self:hangUpAttack(nil)
    end
end

function LOperationMenu:moveMethods(event)
    local btn = event.target
    
    if (self.m_moveMethods == 0) then
        self.m_moveMethods = 1
        btn:setButtonLabelString("normal", "取消步行")
    elseif (self.m_moveMethods == 1) then
        self.m_moveMethods = 2
        btn:setButtonLabelString("normal", "取消寻路")
    elseif (self.m_moveMethods == 2) then
        self.m_moveMethods = 0
        btn:setButtonLabelString("normal", "取消跑步")
    end
end

function LOperationMenu:hideOperationMenu()
--    if (self.m_direction) then
--        self.m_direction:setTouchEnabled(false)
--        self.m_direction:stopAllActions()
--        
--        local moveTo = cc.MoveTo:create(0.3, cc.p(-120, 120))
--        local scaleTo = cc.ScaleTo:create(0.3, 0.8)
--        local easeBack = cc.EaseSineOut:create(cc.Spawn:create(moveTo, scaleTo, nil))
--        self.m_direction:runAction(easeBack)
--    end
    
    if (self.m_operation) then
        self.m_operation:stopAllActions()
        
        local moveTo2 = cc.MoveTo:create(0.3, cc.p(display.width+300, 0))
        local scaleTo2 = cc.ScaleTo:create(0.3, 1.0)
        local array = CCArray:create()
        array:addObject(moveTo2)
        array:addObject(scaleTo2)
        local easeBack2 = cc.EaseSineOut:create(cc.Spawn:create(array))
        self.m_operation:runAction(easeBack2)
    end
end

function LOperationMenu:showOperationMenu()
--    if (self.m_direction) then
--        self.m_direction:setTouchEnabled(true)
--        self.m_direction:stopAllActions()
--        
--        local moveTo = cc.MoveTo:create(0.3, cc.p(120, 120))
--        local scaleTo = cc.ScaleTo:create(0.3, 0.8)
--        local easeBack = cc.EaseSineOut:create(cc.Spawn:create(moveTo, scaleTo, nil))
--        self.m_direction:runAction(easeBack)
--    end
    
    if (self.m_operation) then
        self.m_operation:stopAllActions()
        
        local moveTo2 = cc.MoveTo:create(0.3, cc.p(display.width, 0))
        local scaleTo2 = cc.ScaleTo:create(0.3, 1.0)
        local array = CCArray:create()
        array:addObject(moveTo2)
        array:addObject(scaleTo2)
        local easeBack2 = cc.EaseSineOut:create(cc.Spawn:create(array))
        self.m_operation:runAction(easeBack2)
    end
end

function LOperationMenu:joinEditState()
    if (self.m_operation) then
        self.m_operation:setPositionY(100)
        local moveTo2 = cc.MoveTo:create(0.3, cc.p(display.width, 100))
        local scaleTo2 = cc.ScaleTo:create(0.3, 1.0)
        local array = CCArray:create()
        array:addObject(moveTo2)
        array:addObject(scaleTo2)
        local easeBack2 = cc.EaseSineOut:create(cc.Spawn:create(array))
        self.m_operation:runAction(easeBack2)
    end
end

function LOperationMenu:getDrugsBtn()
    return self.m_btnDrugs
end

function LOperationMenu:getDeliveryBtn()
    return self.m_btnDelivery
end

function LOperationMenu:getCurrProgress()
    return self.m_currProgress
end

function LOperationMenu:getMoveMethods()
    return self.m_moveMethods
end

return LOperationMenu