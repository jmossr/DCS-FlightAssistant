local config = {
    extensions = { 'DCS-calls' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    local withLogEvents = true

    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onDeviceArgument(25, 3001).valueChanged().call(function() checkEvent("!!!"); end)')
    expect('attempt to call global \'onDeviceArgument\' (a nil value)') -- not available without 'builder' extension
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    assert(withLogEvents, 'withLogEvents must be true for this test')

end }