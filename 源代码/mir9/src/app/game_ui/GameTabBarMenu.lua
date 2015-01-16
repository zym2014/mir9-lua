local PropColumnMenu = require("app.game_ui.PropColumn")
local SkillTableView = require("app.game_ui.SkillTableView")
local GameOptions = require("app.game_ui.GameOptions")

local GameTabBarMenu = class("GameTabBarMenu", function()
    return display.newLayer()
end)

function GameTabBarMenu:ctor()
    self:setTouchSwallowEnabled(false)
    
    local PUSH_BUTTON_IMAGES = {
        normal = "ui/tabbarMenu/GUI/button.png",
        pressed = nil,
        disabled = nil,
    }
    
    local posX = 75 -- {75,165,255,345,437,615,705,795,885}
    local szBtn = cc.size(80, 80)
    local text = {"角色","背包","技能","强化","交友","行会","天命","商城","宝典","设置"}
    local callFunc = {
        handler(self, self.showRoleInfo),
        handler(self, self.showBackPack),
        handler(self, self.showSkillInfo),
        handler(self, self.showStrengthen),
        handler(self, self.showMakeFriends),
        handler(self, self.showGuild),
        handler(self, self.showDestiny),
        handler(self, self.showMall),
        handler(self, self.showCanon),
        handler(self, self.showSetUp)
    }
    
    for i = 1, #text do
        local btn = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
        btn:setAnchorPoint(0.5, 0.5)
        btn:setButtonSize(szBtn.width, szBtn.height)
        btn:setPosition(posX, 50)
        btn:setButtonLabel("normal", cc.ui.UILabel.new({
            text = text[i],
            fontName = "微软雅黑",
            size = 30
        }))
        btn:onButtonClicked(callFunc[i])
        self:addChild(btn)
        
        posX = posX + 90
    end
end

-- 角色
function GameTabBarMenu:showRoleInfo(event)
	
end

-- 背包
function GameTabBarMenu:showBackPack(event)
    local layer = PropColumnMenu.new()
    g_mainScene:getGameInfoUIController():addSmallMenu(layer)
    g_mainScene:getGameInfoUIController():getOperationMenu():joinEditState()
end

-- 技能
function GameTabBarMenu:showSkillInfo(event)
    local layer = SkillTableView.new()
    g_mainScene:getGameInfoUIController():addSmallMenu(layer)
    g_mainScene:getGameInfoUIController():getOperationMenu():joinEditState()
end

-- 强化
function GameTabBarMenu:showStrengthen(event)
	
end

-- 交友
function GameTabBarMenu:showMakeFriends(event)
	
end

-- 行会
function GameTabBarMenu:showGuild(event)
    
end

-- 天命
function GameTabBarMenu:showDestiny(event)
	
end

-- 商城
function GameTabBarMenu:showMall(event)
	
end

-- 宝典
function GameTabBarMenu:showCanon(event)
	
end

-- 设置
function GameTabBarMenu:showSetUp(event)
    local layer = GameOptions.new()
    g_mainScene:getGameInfoUIController():addBigMenu(layer)
end

function GameTabBarMenu:hideGameTabBarMenu()
    self:stopAllActions()
    local moveTo = cc.MoveTo:create(0.3, cc.p(display.width-960, -100))
    local easeBack = cc.EaseSineOut:create(moveTo)
    self:runAction(easeBack)
end

function GameTabBarMenu:showGameTabBarMenu()
    self:stopAllActions()
    local moveTo = cc.MoveTo:create(0.3, cc.p(display.width-960, 0))
    local easeBack = cc.EaseSineOut:create(moveTo)
    self:runAction(easeBack)
end

return GameTabBarMenu