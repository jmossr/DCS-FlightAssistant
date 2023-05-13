local activationCount = 0
onUnitActivated(function()
    activationCount = activationCount + 1
    checkEvent("onUnitActivated")
    if activationCount > 1 then
        checkEvent('activation ' .. activationCount)
    end
end)
onUnitDeactivating(function()
    checkEvent("onUnitDeactivating")
end)
onSimulationPause(function()
    checkEvent("onSimulationPause")
end)
onSimulationResume(function()
    checkEvent("onSimulationResume")
end)
onSimulationFrame(function()
    local cmd = checkEvent("onSimulationFrame")
    if cmd then
        local f, err = loadstring(cmd)
        if f then
            setfenv(f, getfenv())
            f()
        else
            checkEvent('Loading error: ' .. tostring(err))
        end
    end
end)

