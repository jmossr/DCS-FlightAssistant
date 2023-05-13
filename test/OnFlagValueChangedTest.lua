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
    expect('onSimulationFrame').andReturn('onFlagValueChanged("A", function(newval, oldval, flg) checkEvent(flg .. ": " .. oldval .. " -> " .. newval); end)')
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '0')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '0')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '3')
    expect('A: 0 -> 3')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('E')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '-0.2')
    expect('A: 3 -> -0.2')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '-0.2')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('G')

end }