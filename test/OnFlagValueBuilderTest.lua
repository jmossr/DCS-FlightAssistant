local config = {
    extensions = { 'builder', 'flags' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    setupFlightAssistant(config, selfData, false)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onFlag("A").value("2").call(function() checkEvent("A = 2 !"); end)')
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '1')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '2')
    expect('A = 2 !')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

end }