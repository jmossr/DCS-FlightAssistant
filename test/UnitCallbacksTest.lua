local config = {
    debug = false,
    DCSGetPauseEnabled = true
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

    expect('DCS.getPause').andReturn(true)
    expect('Export.LoGetSelfData').andReturn(nil)
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    expect('DCS.getPause').andReturn(true)
    expect('Export.LoGetSelfData').andReturn(nil)
    fireUserCallback('onSimulationFrame')
    checkEvents('E')

    expect('DCS.getPause').andReturn(true)
    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onUnitActivated')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

    expect('DCS.getPause').andReturn(true)
    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('G')

    expect('DCS.getPause').andReturn(true)
    expect('Export.LoGetSelfData').andReturn(nil)
    expect('onUnitDeactivating')
    fireUserCallback('onSimulationFrame')
    checkEvents('H')

    expect('DCS.getPause').andReturn(true)
    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onUnitActivated')
    expect('activation 2')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('I')

    expect('onUnitDeactivating')
    fireUserCallback('onSimulationStop')
    checkEvents('J')

    expect('DCS.getPause').andReturn(true)
    fireUserCallback('onSimulationFrame')
    checkEvents('K')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onUnitActivated')
    expect('activation 3')
    fireUserCallback('onSimulationStart')
    checkEvents('L')

    expect('DCS.getPause').andReturn(true)
    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andRaiseError('evil')
    fireUserCallback('onSimulationFrame')
    checkEvents('M')

    expect('DCS.getPause').andReturn(true)
    expect('Export.LoGetSelfData').andReturn(selfData)
    fireUserCallback('onSimulationFrame')
    checkEvents('N')

    expect('DCS.getPause').andReturn(true)
    expect('Export.LoGetSelfData').andReturn(selfData)
    fireUserCallback('onSimulationFrame')
    checkEvents('O')

end }