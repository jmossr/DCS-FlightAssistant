local config = {
    debug = false,
    reloadUserScriptsOnMissionLoad = false,
    logSubsystemName = 'TEST'
}

local callbacks = {
    beforeReloadUserScripts = function() checkEvent('->beforeReloadUserScripts') end,
    onMissionLoadBegin = function() checkEvent('->onMissionLoadBegin') end,
    onSimulationStart = function() checkEvent('->onSimulationStart') end,
    onSimulationStop = function()
        checkEvent('->onSimulationStop')
        error('evil testcase')
    end,
    onSimulationFrame = function() checkEvent('->onSimulationFrame') end,
    onSimulationPause = function() checkEvent('->onSimulationPause') end,
    onSimulationResume = function() checkEvent('->onSimulationResume') end
}
return { test = function()
    log.setEventsEnabled(true)

    expect('INFO     TEST (main): Installing DCS Control API User callbacks')
    expect('DCS.setUserCallbacks')
    local plug = initDCSPlug(config)
    checkEvents('A')

    plug.simulation.registerCallbacks('testcase1', callbacks)

    expect('->onMissionLoadBegin')
    fireUserCallback('onMissionLoadBegin')
    checkEvents('B')

    expect('Export.LoGetSelfData')
    expect('->onSimulationStart')
    fireUserCallback('onSimulationStart')
    checkEvents('C')

    expect('Export.LoGetSelfData')
    expect('->onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    expect('->onSimulationPause')
    fireUserCallback('onSimulationPause')
    checkEvents('E')

    expect('Export.LoGetSelfData')
    expect('->onSimulationResume')
    fireUserCallback('onSimulationResume')
    checkEvents('F')

    expect('->onSimulationStop')
    expect('WARNING  TEST (main): Callback testcase1.onSimulationStop generated an error and will be disabled. ERROR:')
    fireUserCallback('onSimulationStop')
    checkEvents('G')

    fireUserCallback('onSimulationStop')
    checkEvents('H')

    expect('Export.LoGetSelfData')
    expect('->onSimulationStart')
    fireUserCallback('onSimulationStart')
    checkEvents('I')

    config.reloadUserScriptsOnMissionLoad = true

    expect('INFO     TEST (main): Installing DCS Control API User callbacks')
    expect('DCS.setUserCallbacks')
    plug = initDCSPlug(config)
    checkEvents('J')

    plug.simulation.registerCallbacks('testcase1', callbacks)

    expect('->beforeReloadUserScripts')
    expect('INFO     TEST (main): Reloading user scripts...')
    expect('DCS.reloadUserScripts')
    fireUserCallback('onMissionLoadBegin')
    checkEvents('K')

end }