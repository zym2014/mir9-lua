local PlayerController = require("app.figure.PlayerController")

local GameSocket = class("GameSocket")

function GameSocket.sendRoleCreate(node, roleID, nickName)
    local _playerController = PlayerController.sharePlayerController()
    _playerController.m_playerNumber = roleID
    _playerController.m_weaponsNumber = 1000
    _playerController.m_playerName = nickName
    node:joinGame()
end

function GameSocket.attackGroup(one, two, skillNumber)
    if ((not one) or (type(two) ~= "table") or (#two <= 0)) then
        return
    end
    
    local hurt = one:getTheAttack()
    if (skillNumber == 2005) then
        hurt = hurt * 15
    end
    local r = math.random()
    
    hurt = hurt + math.floor((hurt/10) * r) - hurt/20
    
    for i = 1, #two do
        if (two[i]:getBlood() <= 0) then
        
        else
            local blood = two[i]:getBlood() - hurt
            blood = math.max(blood, 0)
            two[i]:addAgainstMe(one, blood)
        end
    end
end

function GameSocket.attack(one, two, skillNumber)
    if (not one or not two) then
        return
    end
    
    if (two:getBlood() <= 0) then
        return
    end
    
    local hurt = one:getTheAttack()
    if (skillNumber == 1020) then
        hurt = hurt * 1.5
    end
    
    hurt = hurt + (math.floor((hurt/10) * math.random()) - hurt/20)
    
    local blood = two:getBlood() - hurt
    
    blood = math.max(blood, 0)
    
    two:addAgainstMe(one, blood)
end

return GameSocket