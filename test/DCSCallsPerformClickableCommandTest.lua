local config = {
    extensions = { 'DCS-calls' },
    debug = true,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    local withLogEvents = true
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('performClickableCommand(25, 3001)')
    expect('dostring_in(server, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn('evil', nil)
    expect('dostring_in(mission, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn(nil, nil)
    if withLogEvents then
        expect('evil')
        expect('FAILED: ?')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('performClickableCommand(25, 3001)')
    expect('dostring_in(server, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn('evil', nil)
    expect('dostring_in(mission, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn(nil, true)
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('performClickableCommand(25, "3001")')
    if config.debug then
        expect('\'command\' must be a number')
    else
        expect('dostring_in(server, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn(nil, true)
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    config.debug = not config.debug

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A2')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('performClickableCommand(25, "3001")')
    if config.debug then
        expect('\'command\' must be a number')
    else
        expect('dostring_in(server, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn(nil, true)
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B2')

    assert(withLogEvents, 'withLogEvents must be true for this test')

end }