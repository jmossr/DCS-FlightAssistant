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
    expect('onSimulationFrame').andReturn('setUserFlag(1)')
    expect('dostring_in(server, trigger.action.setUserFlag("1", 1))').andReturn('evil', nil)
    expect('dostring_in(mission, trigger.action.setUserFlag("1", 1))').andReturn(nil, nil)
    if withLogEvents then
        expect('evil')
        expect('FAILED: ?')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('setUserFlag("1", 2)')
    expect('dostring_in(server, trigger.action.setUserFlag("1", 2))').andReturn('evil', nil)
    expect('dostring_in(mission, trigger.action.setUserFlag("1", 2))').andReturn('evil', nil)
    if withLogEvents then
        expect('FAILED')
        expect('FAILED')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('setUserFlag({1}, 1)')
    if withLogEvents then
        if config.debug then
            expect('\'flag\' must be a string')
        else
            expect('attempt to concatenate local \'flag\'')
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('D')
    log.setEventsEnabled(false)

    config.debug = not config.debug

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A2')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('setUserFlag({1}, 1)')
    if withLogEvents then
        if config.debug then
            expect('\'flag\' must be a string')
        else
            expect('attempt to concatenate local \'flag\'')
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B2')

    assert(withLogEvents, 'withLogEvents must be true for this test')

end }