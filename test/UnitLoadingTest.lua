local config = {
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    config.reloadUserScriptsOnMissionLoad = false
    expect('DCS.setUserCallbacks')
    startFlightAssistant(config)
    checkEvents('A')
    fireUserCallback('onMissionLoadBegin')
    checkEvents('B')
    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onUnitActivated')
    fireUserCallback('onSimulationStart')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andRaiseError('evil')
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    expect('onUnitDeactivating')
    fireUserCallback('onSimulationStop')
    checkEvents('E')

    fireUserCallback('onMissionLoadBegin')
    checkEvents('F')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onUnitActivated')
    expect('activation 2')
    fireUserCallback('onSimulationStart')
    checkEvents('G')

    expect('Export.LoGetSelfData').andReturn(selfData)
    fireUserCallback('onSimulationFrame')
    checkEvents('H')

    FlightAssistant = nil
    config.flightAssistants.Test.reloadOnMissionLoad = true

    expect('DCS.setUserCallbacks')
    startFlightAssistant(config)
    checkEvents('A2')
    fireUserCallback('onMissionLoadBegin')
    checkEvents('B2')
    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onUnitActivated')
    fireUserCallback('onSimulationStart')
    checkEvents('C2')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andRaiseError('evil')
    fireUserCallback('onSimulationFrame')
    checkEvents('D2')


    expect('onUnitDeactivating')
    fireUserCallback('onSimulationStop')
    checkEvents('E2')

    fireUserCallback('onMissionLoadBegin')
    checkEvents('F2')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onUnitActivated')
    fireUserCallback('onSimulationStart')
    checkEvents('G2')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('H2')

end }