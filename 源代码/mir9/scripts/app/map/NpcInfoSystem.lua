local cjson = require("cjson")
local NpcInfo = require("app.map.NpcInfo")

-- NPC信息系统类
local NpcInfoSystem = class("NpcInfoSystem")

function NpcInfoSystem:ctor()
    self.m_mapNpcInfo = {}
    
    local json_str = CCString:createWithContentsOfFile("game_data/npc_info.json")
    local json_value = cjson.decode(json_str:getCString())

    for i = 1, #json_value do
        self:addNpcInfo(json_value[i])
    end
end

function NpcInfoSystem:addNpcInfo(json_value)
    local npcInfo = NpcInfo.new(json_value)
    self.m_mapNpcInfo[npcInfo.m_nID] = npcInfo
end

function NpcInfoSystem:getNpcInfo(nNpcID)
    return self.m_mapNpcInfo[nNpcID]
end

return NpcInfoSystem