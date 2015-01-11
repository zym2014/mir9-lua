-- 攻击技能信息类
local AttackSkillInfo = class("AttackSkillInfo")

function AttackSkillInfo:ctor(json_value)    
    self.m_nNum = json_value["skillNumber"]
    self.m_strName = json_value["skillName"]
    self.m_nType = json_value["skillType"]
    self.m_nAttackType = json_value["attackType"]
    self.m_skillLevel = json_value["skillLevel"]
    self.m_upgradeTrainingPoint = json_value["upgradeTrainingPoint"]
    self.m_openLevel = json_value["openLevel"]
    self.m_magicConsumption = json_value["magicConsumption"]
    self.m_coolingTime = json_value["coolingTime"]
    self.m_attackDistance = json_value["attackDistance"]
    self.m_isAttackBody = json_value["isAttackBody"]
    self.m_flightSpeed = json_value["flightSpeed"]
    self.m_isTailing = json_value["isTailing"]
    self.m_explosionRadius = json_value["explosionRadius"]
    self.m_explosionFanAngle = json_value["explosionFanAngle"]
    self.m_bIsThirdParty = json_value["isThirdParty"]
    self.m_effectiveTime = json_value["effectiveTime"]
    self.m_effectOfCamp = json_value["effectOfCamp"]
    self.m_casterSpecificID = json_value["casterSpecificID"]
    self.m_locusSpecificID = json_value["locusSpecificID"]
    self.m_explosionSpecificID = json_value["explosionSpecificID"]
end

return AttackSkillInfo