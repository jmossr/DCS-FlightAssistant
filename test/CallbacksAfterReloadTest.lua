local config = {
    debug = false,
}

return { test = function()
    initFlightAssistantTestConfig(config)

    config.reloadUserScriptsOnMissionLoad = true
    expect('DCS.setUserCallbacks')
    startFlightAssistant(config)
    checkEvents('A')
    assert(FlightAssistant.Test, "FlightAssistant Test is not registered")

    expect('DCS.reloadUserScripts')
    fireUserCallback('onMissionLoadBegin')
    checkEvents('B')
    assert(not FlightAssistant, "FlightAssistant Test was not closed and removed")

    expect('DCS.setUserCallbacks')
    DCS.setUserCallbacks(nil) -- fake dcs reloading
    checkEvents('C')

    fireUserCallback('onSimulationStart')
    checkEvents('D')

    fireUserCallback('onSimulationFrame')
    checkEvents('E')

    fireUserCallback('onSimulationPause')
    checkEvents('F')

    fireUserCallback('onSimulationFrame')
    checkEvents('G')

    fireUserCallback('onSimulationResume')
    checkEvents('H')

    fireUserCallback('onSimulationFrame')
    checkEvents('I')

    fireUserCallback('onSimulationStop')
    checkEvents('J')

end }