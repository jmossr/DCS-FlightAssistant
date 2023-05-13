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
    expect('onSimulationFrame').andReturn('outTextForUnit(123, \'Some message\', 2)')
    expect('dostring_in(server, trigger.action.outTextForUnit(123, "Some message", 2, false))').andReturn(nil, true)
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('outTextForUnit(321, \'This!\', 3, true)')
    expect('dostring_in(server, trigger.action.outTextForUnit(321, "This!", 3, true))').andReturn(nil, true)
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('D1')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('outTextForUnit(foo, bar, bas)')
    if withLogEvents then
        if config.debug then
            expect('\'unitId\' must be a number')
        else
            expect('generated an error and will be disabled')
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('E1')

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('F1')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('outTextForUnit(461, 1, bas)')
    if withLogEvents then
        if config.debug then
            expect('\'text\' must be a string')
        else
            expect('dostring_in(server, trigger.action.outTextForUnit(461, "1", 3, false))').andReturn(nil, true)
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('G1')

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('H1')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('outTextForUnit(461, "txt", {})')
    if withLogEvents then
        if config.debug then
            expect('\'displayTime\' must be a number')
        else
            expect('generated an error and will be disabled')
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('I1')


    config.debug = not config.debug

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('D2')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('outTextForUnit(foo, bar, bas)')
    if withLogEvents then
        if config.debug then
            expect('\'unitId\' must be a number')
        else
            expect('generated an error and will be disabled')
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('E2')

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('F2')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('outTextForUnit(461, 1, bas)')
    if withLogEvents then
        if config.debug then
            expect('\'text\' must be a string')
        else
            expect('generated an error and will be disabled')
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('G2')

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('H2')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('outTextForUnit(461, "txt", {})')
    if withLogEvents then
        if config.debug then
            expect('\'displayTime\' must be a number')
        else
            expect('generated an error and will be disabled')
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('I2')


    assert(withLogEvents, 'withLogEvents must be true for this test')

end }