local config = {
    extensions = { 'DCS-calls' },
    debug = false,
    DCSCalls = { use_a_cockpit_perform_clickable_action = false}
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    local useExport = not config.DCSCalls.use_a_cockpit_perform_clickable_action

    local withLogEvents = true
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('performClickableAction(25, 3001)')
    if useExport then
        expect('Export.GetDevice(25)').andReturn({
            performClickableAction = function(_, c, v)  checkEvent('performClickableAction(' .. tostring(c) .. ', ' .. tostring(v) .. ')'); end, })
        expect('performClickableAction(3001, 1)')
    else
        expect('dostring_in(server, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn('evil', nil)
        expect('dostring_in(mission, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn(nil, nil) --FAILED
        if withLogEvents then
            expect('evil')
            expect('FAILED: ?')
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('performClickableAction(25, 3001)')
    if useExport then
        expect('Export.GetDevice(25)').andReturn({
            performClickableAction = function(_, c, v)  checkEvent('performClickableAction(' .. tostring(c) .. ', ' .. tostring(v) .. ')'); end, })
        expect('performClickableAction(3001, 1)')
    else
        expect('dostring_in(server, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn('evil', nil)
        expect('dostring_in(mission, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn(nil, true) --SUCCESS
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('performClickableAction(25, "3001")')
    if config.debug then
        expect('\'command\' must be a number')
    else
        if useExport then
            expect('Export.GetDevice(25)').andReturn({
                performClickableAction = function(_, c, v)  checkEvent('performClickableAction(' .. tostring(c) .. ', ' .. tostring(v) .. ')'); end, })
            expect('performClickableAction(3001, 1)')
        else
            expect('dostring_in(server, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn(nil, true)
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    config.DCSCalls.use_a_cockpit_perform_clickable_action = not config.DCSCalls.use_a_cockpit_perform_clickable_action
    useExport = not config.DCSCalls.use_a_cockpit_perform_clickable_action

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A2')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('performClickableAction(25, "3001")')
    if config.debug then
        expect('\'command\' must be a number')
    else
        if useExport then
            expect('Export.GetDevice(25)').andReturn({
                performClickableAction = function(_, c, v)
                    checkEvent('performClickableAction(' .. tostring(c) .. ', ' .. tostring(v) .. ')');
                end, })
            expect('performClickableAction(3001, 1)')
        else
            expect('dostring_in(server, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn(nil, true)
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B2')

    config.debug = not config.debug

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A3')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('performClickableAction(25, "3001")')
    if config.debug then
        expect('\'command\' must be a number')
    else
        if useExport then
            expect('Export.GetDevice(25)').andReturn({
                performClickableAction = function(_, c, v)  checkEvent('performClickableAction(' .. tostring(c) .. ', ' .. tostring(v) .. ')'); end, })
            expect('performClickableAction(3001, 1)')
        else
            expect('dostring_in(server, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn(nil, true)
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B3')

    config.DCSCalls.use_a_cockpit_perform_clickable_action = not config.DCSCalls.use_a_cockpit_perform_clickable_action
    useExport = not config.DCSCalls.use_a_cockpit_perform_clickable_action

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A4')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('performClickableAction(25, "3001")')
    if config.debug then
        expect('\'command\' must be a number')
    else
        if useExport then
            expect('Export.GetDevice(25)').andReturn({
                performClickableAction = function(_, c, v)
                    checkEvent('performClickableAction(' .. tostring(c) .. ', ' .. tostring(v) .. ')');
                end, })
            expect('performClickableAction(3001, 1)')
        else
            expect('dostring_in(server, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn(nil, true)
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B4')


    assert(withLogEvents, 'withLogEvents must be true for this test')

end }