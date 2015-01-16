-- 属性图标显示类
local PropIconShow = class("PropIconShow", function(propInfo)
    local path = string.format("prop_icon/propIcon_%u.png", propInfo.m_nIconNum)
    return display.newSprite(path)
end)

function PropIconShow:ctor(propInfo)
    self.m_propInfo = propInfo
    self.m_path = string.format("prop_icon/propIcon_%u.png", self.m_propInfo.m_nIconNum)
--    local texture = cc.Director:getInstance():getTextureCache():addImage(self.m_path)
--    self:setTexture(texture)
end

return PropIconShow