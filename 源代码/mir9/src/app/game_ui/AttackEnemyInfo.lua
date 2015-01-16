local scheduler = require("framework.scheduler")

local AttackEnemyInfo = class("AttackEnemyInfo", function()
    return display.newNode()
end)

function AttackEnemyInfo:ctor()
    self.m_bloodPro = nil
    self.m_level = nil
    self.m_nickName = nil
    self.m_widget = nil
    self:init()
end

function AttackEnemyInfo:init()
    --self:setTouchSwallowEnabled(false)
    
    local bg = cc.ui.UIImage.new("ui/enemyInfo/icon/enemy_info.png")
    bg:setPosition(0, 0)
    self:addChild(bg)
    
    self.m_bloodPro = cc.ui.UILoadingBar.new({scale9 = false, image = "ui/enemyInfo/icon/blood_in.png", capInsets = cc.rect(0, 0, 0, 0), viewRect = cc.rect(0, 0, 142, 17)})
    self.m_bloodPro:setPosition(38, 10)
    self.m_bloodPro:setPercent(100)
    bg:addChild(self.m_bloodPro)
    
    self.m_level = cc.LabelAtlas:_create("100", "ui/enemyInfo/GUI/labelatlasimg.png", 24, 32, string.byte('0'))
    self.m_level:setAnchorPoint(0, 0)
    self.m_level:setPosition(40, 40)
    self.m_level:setScaleX(0.45)
    self.m_level:setScaleY(0.6)
    self.m_level:setColor(cc.c3b(94,252,11))
    bg:addChild(self.m_level)
    
    self.m_nickName = cc.ui.UILabel.new({
        text = "EnemyName",
        size = 17,
        color = cc.c3b(255,255,255),
    })
    self.m_nickName:setPosition(86, 50)
    self:addChild(self.m_nickName)
    
    return true
end

function AttackEnemyInfo:updateAttackInfo(fDelay)
    if (not g_mainScene:getSelected()) then
        return
    end
    
    if (self.m_bloodPro) then
        local progress = 100*g_mainScene:getSelected():getBlood()/g_mainScene:getSelected():getBloodCap()
        if (progress < 0) then
            progress = 0
        end
        self.m_bloodPro:setPercent(progress)
    end
end

function AttackEnemyInfo:showAttackInfo(monomer)
    if (not g_mainScene:getSelected()) then
        return
    end
        
    if (not self:isVisible()) then
        self:setVisible(true)
        --self.m_widget:setTouchEnabled(true)
    end
    
    self.hUpdateAttackInfo = scheduler.scheduleGlobal(handler(self, self.updateAttackInfo), 0)
end

function AttackEnemyInfo:hide()
    if (self.hUpdateAttackInfo) then
        scheduler.unscheduleGlobal(self.hUpdateAttackInfo)
        self.hUpdateAttackInfo = nil
    end
    self:setVisible(false)
    --self.m_widget:setTouchEnabled(false)
end

return AttackEnemyInfo