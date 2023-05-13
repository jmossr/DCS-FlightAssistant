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
    expect('onSimulationFrame').andReturn('onDeviceArgument(25, 3001).valueChanged().call(function(val) checkEvent("!!!"..tostring(val)); end)')
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('Export.GetDevice(25)').andReturn({ get_argument_value = function(_, a) return checkEvent('getDeviceArgumentValue(' .. a .. ')'); end, })
    expect('getDeviceArgumentValue(3001)').andReturn(42)
    expect('!!!42')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    assert(withLogEvents, 'withLogEvents must be true for this test')

end }