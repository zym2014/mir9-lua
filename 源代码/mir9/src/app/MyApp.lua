
require("config")
require("cocos.init")
require("framework.init")

local MyApp = class("MyApp", cc.mvc.AppBase)

function MyApp:ctor()
    MyApp.super.ctor(self)
end

function MyApp:run()
    math.randomseed(os.clock()*1000)
    cc.FileUtils:getInstance():addSearchPath("res/")
    self:enterScene("LoginScene")
end

return MyApp
