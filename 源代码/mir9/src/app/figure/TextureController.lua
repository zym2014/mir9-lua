local scheduler = require("framework.scheduler")

TexturePathType = {
    Figure = 1,
    Monster = 2,
    Hair = 3,
    Weapon = 4,
    SkillCaster = 5,
    SkillLocus = 6,
    SkillExplosion = 7
}

local FIGURE_PATH = "char_"
local MONSTER_PATH = "monster_"
local HAIR_PATH = "hair_"
local WEAPON_PATH = "weapon_"
local SKILL_CASTER_PATH = "caster_"
local SKILL_LOCUS_PATH = "locus_"
local SKILL_EXPLOSION_PATH = "explosion_"

local FIGURE_ROUTE = "texture_figure/"
local MONSTER_ROUTE = "texture_monster/"
local HAIR_ROUTE = "texture_figure/"
local WEAPON_ROUTE = "texture_weapon/"
local SKILL_ROUTE = "texture_skill/"
local OTHER_ROUTE = "texture_set/"

local textureSuffix = ".plist"
local texturePngSuffix = ".png"

local textureMap = {}

local TextureAsync = class("TextureAsync")

function TextureAsync:ctor(path, callback)
    self.m_texturePath = path
    self.m_callback = callback
end

function TextureAsync:addSpriteFrames(texture)
    local completePath = self.m_texturePath .. textureSuffix
    CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(completePath, texture)
    self:isFinish()
end
    
function TextureAsync:addImageAsync()
    local completePath = self.m_texturePath .. texturePngSuffix
    display.addImageAsync(completePath, function()
        local texture = CCTextureCache:sharedTextureCache():textureForKey(completePath)
        self:addSpriteFrames(texture)
    end)
end
    
function TextureAsync:waitForFinish()
    if (self.handle) then
        scheduler.unscheduleGlobal(self.handle)
        self.handle = nil
    end
    
    if (textureMap[self.m_texturePath] > 0) then
        self:isFinish()
    else
        self.handle = scheduler.scheduleGlobal(handler(self, self.waitForFinish), 0.1)
    end
end
    
function TextureAsync:isFinish()
    local n = textureMap[self.m_texturePath]
    n = n + 1
    textureMap[self.m_texturePath] = n
    
    if (self.m_callback) then
        self.m_callback()
    end
end
    
function TextureAsync.addSpriteFramesAsync(path, callback)
    if (not path or path == "") then
        return
    end
    
    local itr = textureMap[path]        
    if (not itr) then
        local async = TextureAsync.new(path, callback)
        async:addImageAsync()
        textureMap[path] = 0
    else
        local async = TextureAsync.new(path, callback)
        async:waitForFinish()
    end
end
    
function TextureAsync.subSpriteFramesAsync(path)
    if (not path or path == "") then
        return
    end

    local itr = textureMap[path]
    if (itr) then
        itr = itr - 1
        textureMap[path] = itr
        if (itr <= 0) then
            local completePath = path .. textureSuffix
            CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFramesFromFile(completePath)
                
            local pngPath = path .. texturePngSuffix
            CCTextureCache:sharedTextureCache():removeTextureForKey(pngPath)
                
            textureMap[path] = nil
        end
    end
end
    
function TextureAsync.removeAllSpriteFrames()
    for k, v in pairs(textureMap) do
        local completePath = k .. textureSuffix
        CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFramesFromFile(completePath)
    end
    textureMap = {}
        
    CCTextureCache:sharedTextureCache():removeAllTextures()
end


-- 纹理控制器类
local TextureController = class("TextureController")

function TextureController:ctor()
    
end

function TextureController.getTextureRoute(nType, nNum)
    local path
    
    if (nType == TexturePathType.Figure) then
        path = FIGURE_ROUTE .. FIGURE_PATH
    elseif (nType == TexturePathType.Monster) then
        path = MONSTER_ROUTE .. MONSTER_PATH
    elseif (nType == TexturePathType.Hair) then
        path = HAIR_ROUTE .. HAIR_PATH;
    elseif (nType == TexturePathType.Weapon) then
        path = WEAPON_ROUTE .. WEAPON_PATH
    elseif (nType == TexturePathType.SkillCaster) then
        path = SKILL_ROUTE .. SKILL_CASTER_PATH
    elseif (nType == TexturePathType.SkillLocus) then
        path = SKILL_ROUTE .. SKILL_LOCUS_PATH
    elseif (nType == TexturePathType.SkillExplosion) then    
        path = SKILL_ROUTE .. SKILL_EXPLOSION_PATH
    else
        path = ""
    end
    
    if (path ~= "") then
        path = path .. nNum
    end
    
    return path
end

function TextureController.getTexturePath(nType, nNum)
    local path
    
    if (nType == TexturePathType.Figure) then
        path = FIGURE_PATH
    elseif (nType == TexturePathType.Monster) then
        path = MONSTER_PATH
    elseif (nType == TexturePathType.Hair) then
        path = HAIR_PATH;
    elseif (nType == TexturePathType.Weapon) then
        path = WEAPON_PATH
    elseif (nType == TexturePathType.SkillCaster) then
        path = SKILL_CASTER_PATH
    elseif (nType == TexturePathType.SkillLocus) then
        path = SKILL_LOCUS_PATH
    elseif (nType == TexturePathType.SkillExplosion) then    
        path = SKILL_EXPLOSION_PATH
    else
        path = ""
    end
    
    if (path ~= "") then
        path = path .. nNum
    end
    
    return path
end

function TextureController.addSpriteFrames(nType, nNum, callFunc)
    if (nNum == 0) then
        return
    end
    
    local path = TextureController.getTextureRoute(nType, nNum)
    if (path == "") then
        return
    end
    
    local pngFileName = path .. texturePngSuffix
    local plistFileName = path .. textureSuffix
    display.addSpriteFrames(plistFileName, pngFileName)
    if (callFunc) then
        callFunc()
    end
    
    --TextureAsync.addSpriteFramesAsync(path, callFunc)
end

function TextureController.subSpriteFrames(nType, nNum)
    if (nNum == 0) then
        return
    end
    
    local path = TextureController.getTextureRoute(nType, nNum)
    if (path == "") then
        return
    end
    
    --TextureAsync.subSpriteFramesAsync(path)
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
end

function TextureController.removeAllSpriteFrames()
    TextureAsync.removeAllSpriteFrames()
    CCTextureCache:sharedTextureCache():removeUnusedTextures()
end

return TextureController