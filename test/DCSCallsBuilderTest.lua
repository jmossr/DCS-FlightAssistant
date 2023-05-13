local config = {
    extensions = { 'builder', 'DCS-calls' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    setupFlightAssistant(config, selfData, false)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onSimulationPause().setUserFlag(42, 7)')
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onSimulationResume().setUserFlag(7, 42)')
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('onSimulationPause')
    expect('dostring_in(server, trigger.action.setUserFlag("42", 7))').andReturn(nil, true)
    fireUserCallback('onSimulationPause')
    checkEvents('D')

    expect('onSimulationResume')
    expect('dostring_in(server, trigger.action.setUserFlag("7", 42))').andReturn(nil, true)
    fireUserCallback('onSimulationResume')
    checkEvents('E')

end }