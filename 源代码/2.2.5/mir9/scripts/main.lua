function __G__TRACKBACK__(errorMessage)
    print("----------------------------------------")
    print("LUA ERROR: " .. tostring(errorMessage) .. "\n")
    print(debug.traceback("", 2))
    print("----------------------------------------")
end

collectgarbage("setpause", 100)  
collectgarbage("setstepmul", 5000)

require("app.MyApp").new():run()