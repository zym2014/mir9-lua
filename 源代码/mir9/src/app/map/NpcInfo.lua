-- NPC信息类
local NpcInfo = class("NpcInfo")

function NpcInfo:ctor(json_value)
    self.m_nID = json_value["ID"]
    self.m_nSID = json_value["SID"]
    self.m_nQID = json_value["QID"]
    self.m_nRID = json_value["RID"]
    self.m_sSentence = json_value["Sentence"]
    self.m_sName = json_value["Name"]
end

return NpcInfo