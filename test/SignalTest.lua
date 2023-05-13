local config = {
    extensions = { 'signals' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    local withLogEvents = true

    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onSignal("A").call(function() checkEvent("signal A!"); end)')
    if withLogEvents and config.debug then
        expect(' registered')
        expect('unregistered')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('fireSignal("A")')
    expect('signal A!')
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onSignal("B", function() checkEvent("signal B!"); end)')
    if withLogEvents and config.debug then
        expect(' registered')
        expect('unregistered')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('fireSignal("B")')
    expect('signal B!')
    fireUserCallback('onSimulationFrame')
    checkEvents('E')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onSignal({"C"}).call(function() checkEvent("signal C!"); end)')
    if withLogEvents then
        if config.debug then
            expect('\'signal\' must be a string')
        else
            expect('attempt to concatenate local \'signal\'')
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

    config.debug = not config.debug
    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onSignal({"C"}).call(function() checkEvent("signal C!"); end)')
    if withLogEvents then
        if config.debug then
            expect('\'signal\' must be a string')
        else
            expect('attempt to concatenate local \'signal\'')
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('G')

    assert(withLogEvents, 'withLogEvents must be true for this test')
end }