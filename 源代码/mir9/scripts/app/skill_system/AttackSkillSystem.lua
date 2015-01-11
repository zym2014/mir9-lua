local cjson = require("cjson")
local AttackSkillInfo = require("app.skill_system.AttackSkillInfo")

-- 攻击技能系统类
local AttackSkillSystem = class("AttackSkillSystem")

-- 构造函数
function AttackSkillSystem:ctor()
    self.m_mapAttackSkill = {}
    
    local json_str = CCString:createWithContentsOfFile("game_data/skill_info.json")
    local json_value = cjson.decode(json_str:getCString())

    for i = 1, #json_value do
        self:addAttackSkillInfo(json_value[i])
    end
end

function AttackSkillSystem:addAttackSkillInfo(json_value)
    local attackSkillInfo = AttackSkillInfo.new(json_value)
    attackSkillInfo.m_coolingTime = 1.5
    self.m_mapAttackSkill[attackSkillInfo.m_nNum] = attackSkillInfo
end

function AttackSkillSystem:getAttackSkillInfo(nSkillID)
    return self.m_mapAttackSkill[nSkillID]
end

return AttackSkillSystem