local config = {
    debug = false,
}

return { test = function()
    initFlightAssistantTestConfig(config)

    expect('DCS.setUserCallbacks')
    startFlightAssistant(config)
    checkEvents('A')

    FlightAssistant = nil
    expect('DCS.setUserCallbacks')
    expectError('no configuration', startFlightAssistant, nil)
    checkEvents('B')

    FlightAssistant = nil
    config.scriptsDir = nil
    expect('DCS.setUserCallbacks')
    startFlightAssistant(config)
    checkEvents('C')

    FlightAssistant = nil
    config.flightAssistantScriptFile = nil
    expect('DCS.setUserCallbacks')
    expectError('no flightAssistantScriptFile', startFlightAssistant, config)
    checkEvents('D')

    FlightAssistant = nil
    expect('DCS.setUserCallbacks')
    expectError('not a table', startFlightAssistant, 1)

end}