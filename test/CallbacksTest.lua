local config = {
    debug = true, --has to be true to make this test work
    DCSGetPauseEnabled = true
}

return { test = function()
    initFlightAssistantTestConfig(config)

    config.reloadUserScriptsOnMissionLoad = false
    expect('DCS.setUserCallbacks')
    startFlightAssistant(config)
    checkEvents('A')

    assert(FlightAssistant.Test, "FlightAssistant Test not registered")

    fireUserCallback('onMissionLoadBegin')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(nil)
    fireUserCallback('onSimulationStart')
    checkEvents('C')

    expect('DCS.getPause').andReturn(true)
    expect('Export.LoGetSelfData').andReturn(nil)
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    fireUserCallback('onSimulationPause')
    checkEvents('E')

    expect('DCS.getPause').andReturn(true)
    expect('Export.LoGetSelfData').andReturn(nil)
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

    expect('Export.LoGetSelfData').andReturn(nil)
    fireUserCallback('onSimulationResume')
    checkEvents('G')

    expect('DCS.getPause').andReturn(false)
    expect('Export.LoGetSelfData').andReturn(nil)
    fireUserCallback('onSimulationFrame')
    checkEvents('H')

    fireUserCallback('onSimulationStop')
    checkEvents('I')

    log.setEventsEnabled(true)
    fireUserCallback('onMissionLoadBegin')
    checkEvents('J')
    log.setEventsEnabled(false)

end }