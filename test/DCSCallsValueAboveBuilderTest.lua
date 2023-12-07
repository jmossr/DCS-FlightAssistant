local config = {
    extensions = { 'builder', 'DCS-calls' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    local withLogEvents = true

    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onDeviceArgument(25, 3001).valueAbove(0.1).call(function(val) checkEvent("!!!"..tostring(val).." >= 0.1"); end)')
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('Export.GetDevice(25)').andReturn({ get_argument_value = function(_, a) return checkEvent('getDeviceArgumentValue(' .. a .. ')'); end, })
    expect('getDeviceArgumentValue(3001)').andReturn(0.05)
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('Export.GetDevice(25)').andReturn({ get_argument_value = function(_, a) return checkEvent('getDeviceArgumentValue(' .. a .. ')'); end, })
    expect('getDeviceArgumentValue(3001)').andReturn(0.101)
    expect('!!!0.101 >= 0.1')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    assert(withLogEvents, 'withLogEvents must be true for this test')

end }