local GameSocket = require("app.GameSocket")
local GameLoading = require("app.scenes.GameLoading")
local Figure = require("app.figure.Figure")

local RoleSelScene = class("RoleSelScene", function()
    return display.newScene("RoleSelScene")
end)

function RoleSelScene:ctor()
    self.m_btnBegin = nil
    self.m_edtNickName = nil
    self.m_nickName = ""
    self.m_selected = nil
    self.m_arrRole = {}
    
    self:init()
end

function RoleSelScene:init()
    local layerColor = cc.LayerColor:create(cc.c4f(140, 150, 180, 255), display.width, display.height)
    self:addChild(layerColor, -1)
    
    local label = cc.ui.UILabel.new({
        text = "傲来国",
        size = 35,
        color = cc.c3b(255,255,255),
        fontName = "黑体"
    }):pos(480, 576):addTo(self)
    label:setAnchorPoint(0.5, 0.5)
    
    label = cc.ui.UILabel.new({
        text = "血腥、暴力、耐打",
        size = 25,
        color = cc.c3b(255,255,255),
        fontName = "宋体"
    }):pos(192, 179):addTo(self)
    label:setAnchorPoint(0.5, 0.5)
    
    label = cc.ui.UILabel.new({
        text = "召唤、辅助、周旋",
        size = 25,
        color = cc.c3b(255,255,255),
        fontName = "宋体"
    }):pos(480, 179):addTo(self)
    label:setAnchorPoint(0.5, 0.5)
    
    label = cc.ui.UILabel.new({
        text = "强力、强力、还是强力",
        size = 25,
        color = cc.c3b(255,255,255),
        fontName = "宋体"
    }):pos(768, 179):addTo(self)
    label:setAnchorPoint(0.5, 0.5)
    
    local editBox = cc.ui.UIInput.new({
        image = "EditBoxBg.png",
        size = cc.size(200, 50),
        x = 480,
        y = 96,
        listener = function(event, editbox)
            if event == "began" then
                self:onEditBoxBegan(editbox)
            elseif event == "ended" then
                self:onEditBoxEnded(editbox)
            elseif event == "return" then
                self:onEditBoxReturn(editbox)
            elseif event == "changed" then
                self:onEditBoxChanged(editbox)
            else
                printf("EditBox event %s", tostring(event))
            end
        end
    })
    editBox:setFontSize(25)
    editBox:setFontName("宋体")
    editBox:setPlaceHolder("从这里输入昵称")
    editBox:setPlaceholderFontColor(cc.c3b(0, 0, 0))
    editBox:setMaxLength(14)
    editBox:setInputMode(cc.EDITBOX_INPUT_MODE_ANY)
    editBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    self:addChild(editBox)
    self.m_edtNickName = editBox
    
    local PUSH_BUTTON_IMAGES = {
        normal = "ui/role_create/GUI/button.png",
        pressed = nil,
        disabled = nil,
    }

    local btn = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
    btn:setAnchorPoint(0.5, 0.5)
    btn:setButtonSize(40, 40)
    btn:setPosition(604, 96)
    btn:onButtonClicked(handler(self, self.randomNickName))
    self:addChild(btn)
    
    btn = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
    btn:setAnchorPoint(1, 0.5)
    btn:setButtonSize(150, 80)
    btn:setPosition(910, 80)
    btn:setColor(cc.c3b(127, 127, 127))
    btn:setTouchEnabled(false)
    btn:setButtonLabel("normal", cc.ui.UILabel.new({
        text = "进入游戏",
        fontName = "宋体",
        size = 25
    }))
    btn:onButtonClicked(handler(self, self.sendMessage))
    self:addChild(btn)
    self.m_btnBegin = btn
    
    PUSH_BUTTON_IMAGES = {
        normal = nil,
        pressed = nil,
        disabled = nil,
    }
    
    local szBtn = cc.size(120, 200)
    local figureId = {11001, 11002, 12001, 12002, 13001, 13002, 14001, 14002, 15001, 15002, 16001, 16002}
    local hairId = {1000, 1000, 1100, 1100, 1200, 1200}
    local pt = {
        cc.p(115, 320),
        cc.p(268, 320),
        cc.p(403, 320),
        cc.p(556, 320),
        cc.p(691, 320),
        cc.p(844, 320)
    }
    
    for i = 1, 6 do
        local btn = cc.ui.UIPushButton.new(PUSH_BUTTON_IMAGES, {scale9 = true})
        btn:setAnchorPoint(0.5, 0.5)
        btn:setButtonSize(szBtn.width, szBtn.height)
        btn:setPosition(cc.pAdd(cc.p(0, 0), pt[i]))
        btn:setTag(figureId[i])
        btn:onButtonClicked(handler(self, self.setSelector))
        self:addChild(btn)
        
        local monomer = Figure.new(TexturePathType.Figure, figureId[i])
        monomer:setHair(hairId[i])
        monomer:setWeapon(1000)
        --monomer:setPosition(btn:getContentSize().width/2, btn:getContentSize().height/2)
        monomer:setColor(cc.c3b(127, 127, 127))
        btn:addChild(monomer)
        table.insert(self.m_arrRole, monomer)
    end

    return true
end

function RoleSelScene:onExit()
    cc.Director:getInstance():getTextureCache():removeAllTextures()
end

function RoleSelScene:runActionsForFigure(monomer)
    monomer:setFigureState(FigureState.Attack, FigureDirection.Down)
    
    local delayTime = cc.DelayTime:create(2.0)
    local finish = cc.CallFunc:create(function()
        self:runActionsForFigure(monomer)
    end)
    local sequence = cc.Sequence:create(delayTime, finish)
    monomer:runAction(sequence)
end

function RoleSelScene:setSelector(event)
    local btn = event.target
    if (btn) then
        self.m_roleID = btn:getTag()
        if (self.m_selected) then
            local monomer = self.m_selected
            local button = monomer:getParent()
            monomer:setFigureState(FigureState.Stand, FigureDirection.Down)
            monomer:setColor(cc.c3b(127, 127, 127))
            local scaleTo = cc.ScaleTo:create(0.15, 1.0)
            local finish = cc.CallFunc:create(function()
                monomer:stopAllActions()
            end)
            local finish2 = cc.CallFunc:create(function()
                monomer:getWeaponSprite():stopAllActions()
            end)
            local sequence = cc.Sequence:create(scaleTo, finish, finish2)
            monomer:runAction(sequence)
            button:setTouchEnabled(true)
        end
        
        for i = 1, #self.m_arrRole do
            local monomer = self.m_arrRole[i]
            local button = monomer:getParent()
            if (btn == button) then
                button:setTouchEnabled(false)
                local scaleTo = cc.ScaleTo:create(0.15, 1.2)
                monomer:runAction(scaleTo)
                monomer:setColor(cc.c3b(255,255,255))
                self:runActionsForFigure(monomer)
                self.m_selected = monomer
            end
        end
    end
    
    if (self.m_btnBegin) then
        self.m_btnBegin:setColor(cc.c3b(255,255,255))
        self.m_btnBegin:setTouchEnabled(true)
    end
end

function RoleSelScene:randomNickName(event)
    if (self.m_edtNickName) then
        local num = math.random(1, 1000)
        local str = string.format("player_%03d", num)
        self.m_edtNickName:setText("")
        self.m_edtNickName:setText(str)
    end
end

function RoleSelScene:sendMessage(event)
    if (self.m_edtNickName:getText() == "") then
        --CCMessageBox("Nickname is null!", "Tip")
        return
    end
    self.m_edtNickName:setTouchEnabled(false)
    GameSocket.sendRoleCreate(self, self.m_roleID, self.m_edtNickName:getText()) -- SOCKET
end

function RoleSelScene:joinGame()
    GameLoading.runGameLoading(200, 1)
end

function RoleSelScene:onEditBoxBegan(editbox)
    printf("editBox1 event began : text = %s", editbox:getText())
end

function RoleSelScene:onEditBoxEnded(editbox)
    printf("editBox1 event ended : %s", editbox:getText())
end

function RoleSelScene:onEditBoxReturn(editbox)
    printf("editBox1 event return : %s", editbox:getText())
end

function RoleSelScene:onEditBoxChanged(editbox)
    printf("editBox1 event changed : %s", editbox:getText())
end

return RoleSelScene