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
    expect('onSimulationFrame').andReturn('startListenCommand(25, 3001, \'f\')')
    expect('dostring_in(server, a_start_listen_command(3001, "f", 1, 1, 1000000, 25))').andReturn('evil', nil)
    expect('dostring_in(mission, a_start_listen_command(3001, "f", 1, 1, 1000000, 25))').andReturn(nil, nil)
    if withLogEvents then
        expect('evil')
        expect('FAILED: ?')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('startListenCommand(25, 3001, \'f\', -2, 10)')
    expect('dostring_in(server, a_start_listen_command(3001, "f", 1, -2, 10, 25))').andReturn('evil', nil)
    expect('dostring_in(mission, a_start_listen_command(3001, "f", 1, -2, 10, 25))').andReturn(nil, true)
    if withLogEvents and config.debug then
        expect('Listening to device 25, command 3001')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('startListenCommand(25, 3001, {f})')
    if withLogEvents then
        if config.debug then
            expect('\'flag\' must be a string')
        else
            expect('attempt to concatenate local \'flag\'')
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    config.debug = not config.debug

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A2')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('startListenCommand(25, 3001, {f})')
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