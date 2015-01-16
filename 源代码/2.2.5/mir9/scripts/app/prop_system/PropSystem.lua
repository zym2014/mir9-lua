local cjson = require("cjson")
local PropInfo = require("app.prop_system.PropInfo")

-- 属性系统类
local PropSystem = class("PropSystem")

-- 构造函数
function PropSystem:ctor()
    self.m_mapProp = {}
    
    local json_str = CCString:createWithContentsOfFile("game_data/prop_info.json")
    local json_value = cjson.decode(json_str:getCString())

    for i = 1, #json_value do
        self:addPropInfo(json_value[i])
    end
end

function PropSystem:addPropInfo(json_value)
    local propInfo = PropInfo.new(json_value)
    self.m_mapProp[propInfo.m_nNum] = propInfo
end

function PropSystem:getPropInfo(nPropID)
    return self.m_mapProp[nPropID]
end

return PropSystem