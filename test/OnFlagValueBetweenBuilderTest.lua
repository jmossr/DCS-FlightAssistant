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
    expect('onSimulationFrame').andReturn('onFlag("A").valueBetween(2, 4).call(function() checkEvent("2 <= A <= 4 !"); end)')
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '1')
    expect('onSimulationFrame').andReturn('onFlag("B").valueBetween(-1, 1).call(function(newval, oldval, flg) checkEvent(tostring(flg) .. ": " .. tostring(oldval) .. " -> " .. tostring(newval)); end)')
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '2')
    expect('2 <= A <= 4 !')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("B")))').andReturn(nil, '0.1')
    expect('B: 0 -> 0.1')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '3')
    expect('2 <= A <= 4 !')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("B")))').andReturn(nil, '0.1')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('E')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("A")))').andReturn(nil, '3')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("B")))').andReturn(nil, '-0.4')
    expect('B: 0.1 -> -0.4')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

end }