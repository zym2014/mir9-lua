local PlayerController = require("app.figure.PlayerController")
local MapThumbnailMenu = require("app.game_ui.MapThumbnailLayer")
local LOperationMenu = require("app.game_ui.LOperationMenu")
local AttackEnemyInfo = require("app.game_ui.AttackEnemyInfo")
local GameTabBarMenu = require("app.game_ui.GameTabBarMenu")

local GameInfoUIController = class("GameInfoUIController", function()
    return display.newLayer()
end)

function GameInfoUIController:ctor()
    self.m_operationMenu = nil
    self.m_isShowTabBar = true
    self.m_headIcon = nil
    self.m_headBtn = nil
    self.m_levelTTF = nil
    self.m_nickNameTTF = nil
    self.m_bloodPro = nil
    self.m_magicPro = nil
    self.m_gameTabBarMenu = nil
    self.m_attackEnemyInfo = nil
    self.m_chatInterface = nil
    self.m_pMenuBig = nil
    self.m_pMenuSmall = {}
          
    self:init()
end

function GameInfoUIController:init()
    io.writefile("/storage/sdcard0/mir9_log.txt", "GameInfoUIController:init()_start\n","a+")
    
    io.writefile("/storage/sdcard0/mir9_log.txt", "GameInfoUIController:initWithHeadUI()_start\n","a+")    
    self:initWithHeadUI()
    io.writefile("/storage/sdcard0/mir9_log.txt", "GameInfoUIController:initWithHeadUI()_end\n","a+")
    
    io.writefile("/storage/sdcard0/mir9_log.txt", "MapThumbnailMenu.new()_start\n","a+")
    self.m_mapThumbnailMenu = MapThumbnailMenu.new()
    self.m_mapThumbnailMenu:setPosition(cc.PointSub(cc.p(display.width, display.height), cc.p(100, 100)))
    self:addChild(self.m_mapThumbnailMenu)
    io.writefile("/storage/sdcard0/mir9_log.txt", "MapThumbnailMenu.new()_end\n","a+")
    
    io.writefile("/storage/sdcard0/mir9_log.txt", "LOperationMenu.new()_start\n","a+")
    self.m_operationMenu = LOperationMenu.new()
    self:addChild(self.m_operationMenu)
    io.writefile("/storage/sdcard0/mir9_log.txt", "LOperationMenu.new()_end\n","a+")

    io.writefile("/storage/sdcard0/mir9_log.txt", "AttackEnemyInfo.new()_start\n","a+")
    self.m_attackEnemyInfo = AttackEnemyInfo.new()
    self.m_attackEnemyInfo:setPosition(display.width/2-125, display.height-120)
    self.m_attackEnemyInfo:hide()
    self:addChild(self.m_attackEnemyInfo)
    io.writefile("/storage/sdcard0/mir9_log.txt", "AttackEnemyInfo.new()_end\n","a+")
    
--    self.m_chatInterface = ChatInterface::create()
--    self.m_chatInterface->setPosition(CCPoint(220, 0))
--    self:addChild(self.m_chatInterface)
  
    io.writefile("/storage/sdcard0/mir9_log.txt", "GameTabBarMenu.new()_start\n","a+")  
    self.m_gameTabBarMenu = GameTabBarMenu.new()
    self.m_gameTabBarMenu:setPosition(display.width-960, -100)
    self:addChild(self.m_gameTabBarMenu)
    io.writefile("/storage/sdcard0/mir9_log.txt", "GameTabBarMenu.new()_end\n","a+")
    
    io.writefile("/storage/sdcard0/mir9_log.txt", "GameInfoUIController:init()_end\n","a+")
    
    return true
end

function GameInfoUIController:initWithHeadUI()
    local bg = cc.ui.UIImage.new("ui/head_UI/icon/player_head.png")
    bg:setPosition(20, display.height-113-20)
    self:addChild(bg)
    
    bg:setTouchEnabled(true)  
    bg:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "began" then
            if bg:getBoundingBox():containsPoint(cc.p(event.x, event.y)) then  
                bg:setTouchSwallowEnabled(true)
                return true
            end
            return false
        end  
    end)
    
--    local nickName = PlayerController:sharePlayerController().m_playerName
--    local label = cc.ui.UILabel.new({text = nickName, size = 22,  color = ccc3(247, 230, 56)})
--    label:setPosition(180, 100)
--    label:setAnchorPoint(0.5, 0.5)
--    bg:addChild(label)
    
    local PUSH_BUTTON_IMAGES = {
        normal = "ui/head_UI/icon/icon_null.png",
        pressed = "ui/head_UI/icon/icon_null.png",
        disabled = "ui/head_UI/icon/icon_null.png"
    }

    self.m_headBtn = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
    self.m_headBtn:setButtonSize(72, 72)
    self.m_headBtn:setPosition(52, 131-72)
    self.m_headBtn:onButtonClicked(handler(self, self.modeSwitch))
    bg:addChild(self.m_headBtn)
    
    self.m_bloodPro = cc.ui.UILoadingBar.new({scale9 = true, image = "ui/head_UI/icon/blood_in.png", capInsets = cc.rect(0, 0, 0, 0), viewRect = cc.rect(0, 0, 131, 17)})
    self.m_bloodPro:setPosition(116, 54)
    self.m_bloodPro:setPercent(100)
    bg:addChild(self.m_bloodPro)
    
    cc.ui.UILabel.new({
        text = "0/0",
        size = 12,
        color = ccc3(250,247,247),
    }):pos(110, 8):addTo(self.m_bloodPro)
        
    self.m_magicPro = cc.ui.UILoadingBar.new({scale9 = true, image = "ui/head_UI/icon/magic_in.png", capInsets = cc.rect(0, 0, 0, 0), viewRect = cc.rect(0, 0, 131, 17)})
    self.m_magicPro:setPosition(108, 30)
    self.m_magicPro:setPercent(100)
    bg:addChild(self.m_magicPro)
    
    cc.ui.UILabel.new({
        text = "0/0",
        size = 12,
        color = ccc3(250,247,247),
    }):pos(110, 8):addTo(self.m_magicPro)

    local label = CCLabelAtlas:create("3", "ui/head_UI/GUI/labelatlasimg.png", 24, 32, string.byte('0'))
    label:setAnchorPoint(0, 0)
    label:setPosition(94, 68)
    label:setScaleX(0.45)
    label:setScaleY(0.6)
    label:setColor(ccc3(94,252,11))
    bg:addChild(label)
end

-- 头像按钮
function GameInfoUIController:modeSwitch(event)
    if (self:getActionByTag(0xacff)) then
        return
    end
    
    if (self.m_isShowTabBar) then
        self.m_isShowTabBar = false
        self.m_operationMenu:hideOperationMenu()
        -- self.m_chatInterface:hideChatInterface()
        
        local delay = cc.DelayTime:create(0.3)
        local finish = cc.CallFunc:create(handler(self.m_gameTabBarMenu, self.m_gameTabBarMenu.showGameTabBarMenu))
        local array = CCArray:create()
        array:addObject(delay)
        array:addObject(finish)
        local sequence = cc.Sequence:create(array)
        sequence:setTag(0xacff)
        self:runAction(sequence)
    else
        self.m_isShowTabBar = true
        self.m_gameTabBarMenu:hideGameTabBarMenu()
    
        local delay = cc.DelayTime:create(0.3)
        local finish = cc.CallFunc:create(handler(self.m_operationMenu, self.m_operationMenu.showOperationMenu))
        -- local finish2 = cc.CallFunc:create(handler(self.m_chatInterface, self.m_chatInterface.showChatInterface))
        local array = CCArray:create()
        array:addObject(delay)
        array:addObject(finish)
        -- array:addObject(finish2)
        local sequence = cc.Sequence:create(array)
        sequence:setTag(0xacff)
        self:runAction(sequence)
    end
end

function GameInfoUIController:updateBloodPro()
    if (g_player) then
        self.m_bloodPro:setPercent(100*g_player:getBlood()/g_player:getBloodCap())
    end
end

function GameInfoUIController:updateMagicPro()
    if (g_player) then
        self.m_bloodPro:setPercent(100*g_player:getMagic()/g_player:getMagicCap())
    end
end

function GameInfoUIController:updateLevelTTF()

end

function GameInfoUIController:addSmallMenu(node)
    if (self.m_pMenuBig) then
        self.m_pMenuBig:removeFromParent()
        self.m_pMenuBig = nil
    end
    
    for i = 1, #self.m_pMenuSmall do
        if node.m_className == self.m_pMenuSmall[i].m_className then
            return
        end
    end
    
    self:setTouchEnabled(false)
    
    if (#self.m_pMenuSmall >= 2) then
        self.m_pMenuSmall[1]:removeFromParent()
        table.remove(self.m_pMenuSmall, 1)
        self.m_pMenuSmall[1]:setPosition(display.width/4, (display.height+80)/2)
    end
    
    node:setPosition(display.width/4 * (#self.m_pMenuSmall*2+1), (display.height+80)/2)
    self:addChild(node)
    table.insert(self.m_pMenuSmall, node)
    
    self:setTouchEnabled(true)
end

function GameInfoUIController:removeSmallMenu(node)
    if (not node) then
        return
    end
    
    for i = 1, #self.m_pMenuSmall do
        if node == self.m_pMenuSmall[i] then
            table.remove(self.m_pMenuSmall, i)
            node:removeFromParent()
            break
        end
    end
    
    if (#self.m_pMenuSmall > 0) then
        self.m_pMenuSmall[1]:setPosition(display.width/4, (display.height+80)/2)
    else
        self:setTouchEnabled(false)
    end
end

function GameInfoUIController:removeSmallMenuAndButton(event)
	local node = event.target
    self:removeSmallMenu(node:getParent())
end

function GameInfoUIController:addBigMenu(node)
	if (self.m_pMenuBig) then
		self.m_pMenuBig:removeFromParent()
		self.m_pMenuBig = nil
	end
	self:setTouchEnabled(false)
    
    if (#self.m_pMenuSmall > 0) then
        for i = 1, #self.m_pMenuSmall do
            self.m_pMenuSmall[i]:removeFromParent()
        end
        self.m_pMenuSmall = {}
    end
    
    node:setPosition(display.width/2, (display.height+80)/2)
    self:addChild(node)
    self.m_pMenuBig = node
    
    self:setTouchEnabled(true)
end

function GameInfoUIController:removeBigMenuAndButton(node, event)
    if (self.m_pMenuBig) then
        self.m_pMenuBig:removeFromParent()
        self.m_pMenuBig = nil
    end
    self:setTouchEnabled(false)
end

function GameInfoUIController:getAttackEnemyInfo()
    return self.m_attackEnemyInfo
end

function GameInfoUIController:getOperationMenu()
    return self.m_operationMenu
end

return GameInfoUIController