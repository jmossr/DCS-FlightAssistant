local config = {
    extensions = { 'builder', 'DCS-calls' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config, false, { setupTextToOwnShipActionBuilderTest = true })

    local withLogEvents = false

    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationResume')
    expect('dostring_in(server, do local unit = world.getPlayer(); return unit and unit:getID() or nil; end)').andReturn(nil, '7')
    expect('dostring_in(server, trigger.action.outTextForUnit(7, "Simulation resumed", 2.3, false))').andReturn(nil, true)
    fireUserCallback('onSimulationResume')
    checkEvents('C')

    expect('onSimulationPause')
    fireUserCallback('onSimulationPause')
    checkEvents('D')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationResume')
    expect('dostring_in(server, trigger.action.outTextForUnit(7, "Simulation resumed", 2.3, false))').andReturn(nil, true)
    fireUserCallback('onSimulationResume')
    checkEvents('E')

    expect('Export.LoGetSelfData').andReturn(nil)
    expect('onUnitDeactivating')
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onUnitActivated')
    expect('activation 2')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('G')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationResume')
    expect('dostring_in(server, do local unit = world.getPlayer(); return unit and unit:getID() or nil; end)').andReturn(nil, '8')
    expect('dostring_in(server, trigger.action.outTextForUnit(8, "Simulation resumed", 2.3, false))').andReturn(nil, true)
    fireUserCallback('onSimulationResume')
    checkEvents('H')

end }