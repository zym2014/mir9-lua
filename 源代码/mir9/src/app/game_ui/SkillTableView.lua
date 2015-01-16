local SkillTableView = class("SkillTableView", function()
    return display.newNode()
end)

function SkillTableView:ctor()
    self.m_className = "SkillTableView"
    self.m_pEditingSkill = nil
    self.m_pEditingBtn = nil
    self.m_arrSkill = {}
    self:init()
end

function SkillTableView:init()
    self:setAnchorPoint(0.5, 0.5)
    
    local szBg = cc.size(450, 500)
    local ptBg = cc.p(szBg.width/-2, szBg.height/-2)
    local bg = cc.LayerColor:create(cc.c4b(255, 255, 255, 127), szBg.width, szBg.height)
    bg:setPosition(ptBg)
    self:addChild(bg, -1)
    
    local title = cc.LabelTTF:create("技能列表", "fonts/Marker Felt.ttf", 40)
    title:setPosition(szBg.width/2, szBg.height-30)
    bg:addChild(title)
    
    local szBtn = cc.size(57, 58)
    
    local PUSH_BUTTON_IMAGES = {
        normal = "ui/closed_normal.png",
        pressed = "ui/closed_selected.png",
        disabled = "ui/closed_normal.png",
    }

    local btn = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
    btn:setButtonSize(szBtn.width, szBtn.height)
    local ptBtn = cc.pAdd(ptBg, cc.p(szBg.width, szBg.height))
    ptBtn = cc.pSub(ptBtn, cc.p(szBtn.width/2, szBtn.height/2))
    btn:setPosition(ptBtn)
    btn:setAnchorPoint(0.5, 0.5)
    btn:onButtonClicked(handler(g_mainScene:getGameInfoUIController(), g_mainScene:getGameInfoUIController().removeSmallMenuAndButton))
    self:addChild(btn)
    
    self.m_lvSkill = cc.ui.UIListView.new({
        -- bgColor = cc.c4b(200, 200, 200, 120),
        -- bg = "sunset.png",
        viewRect = cc.rect(0, 0, 420, 420),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        -- scrollbarImgV = "bar.png"
    })
    self.m_lvSkill:setPosition(15, 15)
    self.m_lvSkill:setAlignment(cc.ui.UIListView.ALIGNMENT_LEFT)
    bg:addChild(self.m_lvSkill)

    -- add items
    for i = 1, 9 do
        local item = self.m_lvSkill:newItem()
        
        local fileName = string.format("ui/skill/skill_%d.png", 2000 + i)
        item:setBg("ui/cell.png")
        local content = cc.ui.UIImage.new(fileName)
        content:setAnchorPoint(0.5, 0.5)
        content:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
            local point = cc.p(event.x, event.y)
            if event.name == "began" then
                self.m_pEditingSkill = cc.Sprite:createWithTexture(content:getTexture())
                self.m_pEditingSkill:setPosition(point)
                g_mainScene:getGameInfoUIController():addChild(self.m_pEditingSkill)
                self.m_pEditingSkill:setTag(content:getParent():getTag())
                self.m_pEditingSkill:setScale(1.5)
                self.m_pEditingSkill:setOpacity(127)
                content:setTouchSwallowEnabled(true)
                return true
            elseif event.name == "moved" then
                if (not self.m_pEditingSkill) then
                    return
                end

                self.m_pEditingSkill:setPosition(point)

                if (self.m_pEditingBtn) then
                    local rect = cc.rect(0,0,0,0)
                    local pt = self.m_pEditingBtn:convertToWorldSpace(cc.p(0,0))
                    local size = self.m_pEditingBtn:getContentSize()
                    rect.x, rect.y = pt.x, pt.y
                    rect.width, rect.height = size.width, size.height
                    if (not cc.rectContainsPoint(rect, point)) then
                        self.m_pEditingSkill:setOpacity(127)
                        self.m_pEditingBtn:stopAllActions()
                        local scaleTo = cc.ScaleTo:create(0.1, 1.0)
                        self.m_pEditingBtn:runAction(scaleTo)
                        self.m_pEditingBtn = nil
                    end
                end

                if (not self.m_pEditingBtn) then
                    for i = 1, 3 do
                        local btn = g_mainScene:getGameInfoUIController():getOperationMenu():getSkillAttackBtn(i)
                        local rect = cc.rect(0,0,0,0)
                        local pt = btn:convertToWorldSpace(cc.p(0,0))
                        local size = cc.size(75,75)   -- btn:getButtonSize()
                        rect.x, rect.y = pt.x, pt.y
                        rect.width, rect.height = size.width, size.height
                        
                        rect.x = rect.x - rect.width/2    -- 因为按钮锚点是(0.5,0.5)，所以这里修正一下
                        rect.y = rect.y - rect.height/2

                        if (cc.rectContainsPoint(rect, point)) then
                            self.m_pEditingSkill:setOpacity(255)
                            self.m_pEditingBtn = btn
                            self.m_pEditingBtn:stopAllActions()
                            local scaleTo = cc.ScaleTo:create(0.1, 1.1)
                            self.m_pEditingBtn:runAction(scaleTo)
                            break
                        end
                    end
                end
            elseif event.name == "ended" then
                if (self.m_pEditingSkill) then
                    if (self.m_pEditingBtn) then
                        g_mainScene:getGameInfoUIController():getOperationMenu():addSkillIcon_(self.m_pEditingBtn, self.m_pEditingSkill:getTag())
                        local scaleTo = cc.ScaleTo:create(0.1, 1.0)
                        self.m_pEditingBtn:runAction(scaleTo)
                        self.m_pEditingBtn = nil
                    end
                    self.m_pEditingSkill:removeFromParent()
                    self.m_pEditingSkill = nil
                end
            end
        end)
        content:setTouchEnabled(true)
        item:addContent(content)
        item:setItemSize(420, 80)
        item:setMargin({left = 30, bottom = 26, right = 0, top = 0})
        item:setTag(2000 + i)

        self.m_lvSkill:addItem(item)
        table.insert(self.m_arrSkill, content)
    end
    self.m_lvSkill:reload()
    
    return true
end

function SkillTableView:onTouchBegan(event)
--    local point = cc.p(event.x, event.y)
--    
--    local rcListView = cc.rect(0,0,0,0)
--    rcListView.origin = self.m_lvSkill:getParent():convertToWorldSpace(cc.p(self.m_lvSkill:getPosition()))
--    rcListView.size = cc.size(420, 420)
--    
--    if (not rcListView:containsPoint(point)) then
--        return false
--    end
--    
--    if (#self.m_arrSkill == 0) then
--        return false
--    end
--    
--    for i = 1, #self.m_arrSkill do
--        local imgSkillIcon = self.m_arrSkill[i]
--        local szSkillIcon = imgSkillIcon:getContentSize()
--        local ptSkillIcon = cc.p(imgSkillIcon:getPosition())
--        ptSkillIcon = imgSkillIcon:getParent():convertToWorldSpace(ptSkillIcon)
--        ptSkillIcon = cc.PointSub(ptSkillIcon, cc.p(szSkillIcon.width/2, szSkillIcon.height/2))
--        local rect = cc.rect(ptSkillIcon.x, ptSkillIcon.y, szSkillIcon.width, szSkillIcon.height)
--        if (rect:containsPoint(point)) then
--            self.m_pEditingSkill = CCSprite:createWithTexture(imgSkillIcon:getTexture())
--            self.m_pEditingSkill:setPosition(point)
--            g_mainScene:getGameInfoUIController():addChild(self.m_pEditingSkill)
--            self.m_pEditingSkill:setTag(imgSkillIcon:getParent():getTag())
--            self.m_pEditingSkill:setScale(1.5)
--            self.m_pEditingSkill:setOpacity(127)
--            return true
--        end
--    end
--    
--    return false
end

function SkillTableView:onTouchMoved(event)
--    local point = cc.p(event.x, event.y)
--    
--    if (not self.m_pEditingSkill) then
--        return
--    end
--        
--    self.m_pEditingSkill:setPosition(point)
--    
--    if (self.m_pEditingBtn) then
--        local rect = cc.rect(0,0,0,0)
--        rect.origin = self.m_pEditingBtn:convertToWorldSpace(cc.p(0,0))
--        rect.size = self.m_pEditingBtn:getContentSize()
--        if (not rect:containsPoint(point)) then
--            self.m_pEditingSkill:setOpacity(127)
--            self.m_pEditingBtn:stopAllActions()
--            local scaleTo = cc.ScaleTo:create(0.1, 1.0)
--            self.m_pEditingBtn:runAction(scaleTo)
--            self.m_pEditingBtn = nil
--        end
--    end
--    
--    if (not self.m_pEditingBtn) then
--        for i = 1, 3 do
--            local btn = g_mainScene:getGameInfoUIController():getOperationMenu():getSkillAttackBtn(i)
--            local rect = cc.rect(0,0,0,0)
--            rect.origin = btn:convertToWorldSpace(cc.p(0,0))
--            rect.size = btn:getContentSize()
--            
--            if (rect:containsPoint(point)) then
--                self.m_pEditingSkill:setOpacity(255)
--                self.m_pEditingBtn = btn
--                self.m_pEditingBtn:stopAllActions()
--                local scaleTo = cc.ScaleTo:create(0.1, 1.1)
--                self.m_pEditingBtn:runAction(scaleTo)
--                break
--            end
--        end
--    end
end

function SkillTableView:onTouchEnded(event)
--    if (self.m_pEditingSkill) then
--        if (self.m_pEditingBtn) then
--            g_mainScene:getGameInfoUIController():getOperationMenu():addSkillIcon(self.m_pEditingBtn, self.m_pEditingSkill:getTag())
--            local scaleTo = cc.ScaleTo:create(0.1, 1.0)
--            self.m_pEditingBtn:runAction(scaleTo)
--            self.m_pEditingBtn = nil
--        end
--        self.m_pEditingSkill:removeFromParent()
--        self.m_pEditingSkill = nil
--    end
end

function SkillTableView:onTouchCancelled(event)
    
end

return SkillTableView