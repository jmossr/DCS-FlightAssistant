local config = {
    extensions = { 'flags' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    setupFlightAssistant(config, selfData, false)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onFlagValue("A", "2", function() checkEvent("A = 2 !"); end)')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '0')
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '1')
    expect('onSimulationFrame').andReturn('onFlagValue("B", 4, function() checkEvent("B = 4 !"); end)')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("B")))').andReturn(nil, '0')
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '2')
    expect('A = 2 !')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("B")))').andReturn(nil, '2')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '3')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("B")))').andReturn(nil, '4')
    expect('B = 4 !')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('E')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '2')
    expect('A = 2 !')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("B")))').andReturn(nil, '4')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

end }