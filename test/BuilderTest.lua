local config = {
    extensions = { 'builder' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    setupFlightAssistant(config, selfData, false)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onSimulationPause().call(function() checkEvent(\'Inserted event on pause\'); end)')
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onSimulationResume().call(function() checkEvent(\'Inserted event on resume\'); end)')
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onUnitActivated().call(function() checkEvent(\'Inserted event on activated\'); end)')
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onUnitDeactivating().call(function() checkEvent(\'Inserted event on deactivating\'); end)')
    fireUserCallback('onSimulationFrame')
    checkEvents('E')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onSimulationFrame().call(function() checkEvent(\'Inserted event on frame\'); end)')
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

    expect('onSimulationPause')
    expect('Inserted event on pause')
    fireUserCallback('onSimulationPause')
    checkEvents('G')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame')
    expect('Inserted event on frame')
    fireUserCallback('onSimulationFrame')
    checkEvents('H')

    expect('onSimulationResume')
    expect('Inserted event on resume')
    fireUserCallback('onSimulationResume')
    checkEvents('I')

    expect('Export.LoGetSelfData').andReturn(nil)
    expect('onUnitDeactivating')
    expect('Inserted event on deactivating')
    fireUserCallback('onSimulationFrame')
    checkEvents('J')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onUnitActivated')
    expect('activation 2')
    expect('Inserted event on activated')
    expect('onSimulationFrame')
    expect('Inserted event on frame')
    fireUserCallback('onSimulationFrame')
    checkEvents('K')

end }