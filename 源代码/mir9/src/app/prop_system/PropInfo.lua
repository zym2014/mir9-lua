-- 属性信息类
local PropInfo = class("PropInfo")

function PropInfo:ctor(json_value)    
    self.m_nNum = json_value["ID"]
    self.m_nIconNum = json_value["Icon"]
    self.m_nAvatarNum = json_value["AvatarID"]
    self.m_strName = json_value["Name"]
    self.m_nType = json_value["Type"]
    self.m_strDepict = json_value["Depict"]
    self.m_levelRequirements = json_value["Nlevel"]
    self.m_attackRequirements = json_value["Nattack"]
    self.m_magicRequirements = json_value["Nmaige"]
    self.m_taoismRequirements = json_value["Ntaoism"]
    self.m_gender = json_value["Gender"]
    self.m_lasting = json_value["Lasting"]
    self.m_weight = json_value["Weight"]
    self.m_specialRequirements = json_value["Nspecial"]
    self.m_coin = json_value["Coin"]
    self.m_accurate = json_value["Accurate"]
    self.m_dodge = json_value["Dodge"]
    self.m_magicDodge = json_value["Mdodge"]
    self.m_defenseMax = json_value["MaxDefense"]
    self.m_defenseMin = json_value["MinDefense"]
    self.m_magicDefenseMax = json_value["MaxMDefense"]
    self.m_magicDefenseMin = json_value["MinMDefense"]
    self.m_attackMax = json_value["MaxAttack"]
    self.m_attackMin = json_value["MinAttack"]
    self.m_magicMax = json_value["MaxMaige"]
    self.m_magicMin = json_value["MinMaige"]
    self.m_taoismMax = json_value["MaxTaoism"]
    self.m_taoismMin = json_value["MinTaoism"]
    self.m_lucky = json_value["Lucky"]
    self.m_SE = json_value["SE"]
    self.m_JS = json_value["JS"]
end

return PropInfo