local GameOptions = class("GameOptions", function()
    return display.newNode()
end)

function GameOptions:ctor()
    local bg = display.newSprite("ui/options.png")
    bg:setPosition(0, 0)
    self:addChild(bg)
    
    local ptBg = cc.p(bg:getPosition())
    local szBg = bg:getContentSize()
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
    btn:onButtonClicked(handler(g_mainScene:getGameInfoUIController(), g_mainScene:getGameInfoUIController().removeBigMenuAndButton))
    bg:addChild(btn)
end

return GameOptions