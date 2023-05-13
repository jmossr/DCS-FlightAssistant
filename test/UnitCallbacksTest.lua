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
    expect('Export.LoGetSelfData').andReturn(nil)
    fireUserCallback('onSimulationStart')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(nil)
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    expect('Export.LoGetSelfData').andReturn(nil)
    fireUserCallback('onSimulationFrame')
    checkEvents('E')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onUnitActivated')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('G')

    expect('Export.LoGetSelfData').andReturn(nil)
    expect('onUnitDeactivating')
    fireUserCallback('onSimulationFrame')
    checkEvents('H')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onUnitActivated')
    expect('activation 2')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('I')

    expect('onUnitDeactivating')
    fireUserCallback('onSimulationStop')
    checkEvents('J')

    fireUserCallback('onSimulationFrame')
    checkEvents('K')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onUnitActivated')
    expect('activation 3')
    fireUserCallback('onSimulationStart')
    checkEvents('L')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andRaiseError('evil')
    fireUserCallback('onSimulationFrame')
    checkEvents('M')

    expect('Export.LoGetSelfData').andReturn(selfData)
    fireUserCallback('onSimulationFrame')
    checkEvents('N')

    expect('Export.LoGetSelfData').andReturn(selfData)
    fireUserCallback('onSimulationFrame')
    checkEvents('O')

end }