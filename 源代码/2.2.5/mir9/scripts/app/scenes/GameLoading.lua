local scheduler = require("framework.scheduler")

local GameLoading = class("GameLoading", function()
    return display.newScene("GameLoading")
end)

function GameLoading:ctor()
--    self.m_mapID = mapID
--    self.m_born = born
    self:init()
end

function GameLoading:onEnter()
--    if (not g_mainScene) then
--        self.hInitGameScene = scheduler.performWithDelayGlobal(handler(self, self.initGameScene), 0.5)
--    end
    
    --self.hUpdateBgMap = scheduler.performWithDelayGlobal(handler(self, self.updateBgMap), 1.0)
end

function GameLoading:onExit()
    CCTextureCache:sharedTextureCache():removeAllTextures()
--    if (self.hInitGameScene) then
--        scheduler.unscheduleGlobal(self.hInitGameScene)
--        self.hInitGameScene = nil
--    end
--    
--    if (self.hUpdateBgMap) then
--        scheduler.unscheduleGlobal(self.hUpdateBgMap)
--        self.hUpdateBgMap = nil
--    end
end

function GameLoading.runGameLoading(mapID, born)
    GameLoading.m_mapID = mapID
    GameLoading.m_born = born
    app:enterScene("GameLoading")
--    if (not g_gameLoading) then
--        g_gameLoading = GameLoading.new(mapID, born)
--        CCDirector:sharedDirector():getRunningScene():addChild(g_gameLoading, 100)
--        g_gameLoading:release()
--    end
--    return g_gameLoading
end

function GameLoading:init()    
    self:setAnchorPoint(cc.p(0, 0))
    
    self.m_sprite = display.newSprite("map/loading.jpg")
    self.m_sprite:setPosition(display.cx, display.cy)
    self:addChild(self.m_sprite, -1)
    
    local ttf = CCLabelTTF:create("加载中……", "Arial", 30)
    ttf:setPosition(display.width-70, 20)
    self:addChild(ttf)
    
--    if (g_mainScene and g_mainScene:getCurrBgMap()) then
--        self:setOpacity(0)
--        local fadeIn = cc.FadeIn:create(0.5)
--        self:runAction(fadeIn)
--    end
    
    self.hInitGameScene = scheduler.performWithDelayGlobal(handler(self, self.initGameScene), 0.5)
    
    return true
end

function GameLoading:initGameScene(fDelay)
    -- CCDirector:sharedDirector():getRunningScene():addChild(MainScene.new())
    app:enterScene("MainScene", nil, "fade", 0.5)
end

--function GameLoading:updateBgMap(fDelay)
--    CCTextureCache:sharedTextureCache():removeUnusedTextures()
--    g_mainScene:replaceBgMap(self.m_mapID, self.m_born)
--    self:updateFinish()
--end
--
--function GameLoading:updateFinish()
--    local fadeOut = cc.FadeOut:create(0.3)
--    local callFunc = cc.CallFunc:create(handler(self, self.removeFromParent))
--    local array = CCArray:create()
--    array:addObject(fadeOut)
--    array:addObject(callFunc)
--    local sequence = cc.Sequence:create(array)
--    self:runAction(sequence)
--end

return GameLoading