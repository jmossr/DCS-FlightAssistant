local config = {
    debug = true, --has to be true to make this test work
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

    expect('Export.LoGetSelfData').andReturn(nil)
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    fireUserCallback('onSimulationPause')
    checkEvents('E')

    expect('Export.LoGetSelfData').andReturn(nil)
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    fireUserCallback('onSimulationResume')
    checkEvents('F')

    expect('Export.LoGetSelfData').andReturn(nil)
    fireUserCallback('onSimulationFrame')
    checkEvents('G')

    fireUserCallback('onSimulationStop')
    checkEvents('H')

    log.setEventsEnabled(true)
    fireUserCallback('onMissionLoadBegin')
    checkEvents('I')
    log.setEventsEnabled(false)

end }