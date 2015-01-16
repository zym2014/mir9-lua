
-- 纹理控制器类
local PlayerController = class("PlayerController")

function PlayerController:ctor()
    self.m_playerNumber = 11001
    self.m_hairNumber = 1100
    self.m_weaponsNumber = 0
    self.m_playerName = ""
    self.m_playerLevel = 1
    self.m_playerShowID = 0
    self.m_playerUID = ""
    self.m_carryingWeaponsID = 0
    
    self:init()
end

function PlayerController.sharePlayerController()
    if (not g_playerController) then
        g_playerController = PlayerController.new()
    end
    return g_playerController
end

function PlayerController:init()
    return true
end

return PlayerController