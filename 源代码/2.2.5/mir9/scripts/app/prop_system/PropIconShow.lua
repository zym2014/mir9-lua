-- 属性图标显示类
local PropIconShow = class("PropIconShow", function()
    return display.newSprite()
end)

function PropIconShow:ctor(propInfo)
    self.m_propInfo = propInfo
    self.m_path = string.format("prop_icon/propIcon_%u.png", self.m_propInfo.m_nIconNum)
    local pTexture = CCTextureCache:sharedTextureCache():addImage(self.m_path)
    self:setTexture(pTexture)
end

return PropIconShow