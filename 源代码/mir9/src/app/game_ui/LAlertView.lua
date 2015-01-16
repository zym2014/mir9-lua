local LAlertView = class("LAlertView", function()
    return ccui.Scale9Sprite:create("ui/alert_backGround.png")
end)

function LAlertView:ctor(title, messageText)
    self.m_title = title
    self.m_messageText = messageText
    self.m_callBack = nil
    
    self.m_arrBtn = {}
    
    self:init()
end

function LAlertView:init()
    local szContent = self:getContentSize()
    
    local title = cc.LabelTTF:create(self.m_title, "Helvetica-Bold", 22)
    title:setAnchorPoint(0.5, 1)
    title:setPosition(szContent.width/2, szContent.height-52)
    self:addChild(title)
    
    local message = cc.LabelTTF:create(self.m_messageText, "Helvetica-Bold", 20)
    message:setPosition(cc.pAdd(cc.p(szContent.width/2, szContent.height/2), cc.p(0, 30)))
    self:addChild(message)
    
    return true
end

function LAlertView:addButtonWithTitle(btnTitle)
    local PUSH_BUTTON_IMAGES = {
        normal = "ui/btn_normal.png",
        pressed = "ui/btn_selected.png",
        disabled = "ui/btn_normal.png",
    }

    local btn = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
    btn:setAnchorPoint(0.5, 0.5)
    btn:setButtonSize(140, 50)
    btn:setButtonLabel("normal", cc.ui.UILabel.new({
        text = btnTitle,
        fontName = "Helvetica-Bold",
        size = 25
    }))
    btn:onButtonClicked(handler(self, self.onBtn_Clicked))
    btn:setTag(0xff+#self.m_arrBtn)
    table.insert(self.m_arrBtn, btn)
end

function LAlertView:show(callFunc)
    self.m_callBack = callFunc

    if (#self.m_arrBtn > 2) then
        self:setPreferredSize(cc.size((#self.m_arrBtn + 1) * 150, self:getContentSize().height))
    end
    
    if (#self.m_arrBtn == 0) then
        local PUSH_BUTTON_IMAGES = {
            normal = "ui/btn_normal.png",
            pressed = "ui/btn_selected.png",
            disabled = "ui/btn_normal.png",
        }

        local btn = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
        btn:setAnchorPoint(0.5, 0.5)
        btn:setButtonSize(130, 43)
        btn:setButtonLabel("normal", cc.ui.UILabel.new({
            text = "确定",
            fontName = "Helvetica-Bold",
            size = 25
        }))
        btn:onButtonClicked(handler(self, self.onBtn_Clicked))
        btn:setTag(0xff)
        btn:setPosition(self:getContentSize().width/2, 100)
        self:addChild(btn)
    else
        for i = 1, #self.m_arrBtn do
            local btn = self.m_arrBtn[i]
            local x = self:getContentSize().width / (#self.m_arrBtn+1) * (i + 1)
            btn:setPosition(x, 100)
            self:addChild(btn)
        end
    end
    self:setPosition(display.cx, display.cy)
    cc.Director:getInstance():getRunningScene():addChild(self, 0xffff)
end

function LAlertView:onBtn_Clicked(event)
    local btn = event.target
    
    if (self.m_callBack) then
        self.m_callBack(btn:getTag()-0xff)
    end
    self:removeFromParent()
end

return LAlertView