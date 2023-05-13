local config = {
    extensions = { 'scheduler' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }
local runCount = 0
local function runTests(withLogEvents)
    runCount = runCount + 1
    FlightAssistant = nil

    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A' .. runCount)

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('schedule("0.5", 1)')
    if withLogEvents and config.debug then
        expect('\'f\' must be a function')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B' .. runCount)

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('C' .. runCount)

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('schedule(os.clock, "1")')
    if withLogEvents then
        if config.debug then
            expect('\'delay\' must be a')
        else
            expect('compare string with number')
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('D' .. runCount)

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('E' .. runCount)

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('schedule(os.clock, -1)')
    if withLogEvents and config.debug then
        expect('\'delay\' must be a positive number')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('F' .. runCount)

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('G' .. runCount)

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('schedule(os.clock, 1, {})')
    if withLogEvents and config.debug then
        expect('\'period\' must be a')
        --if not debug => error will not be reported at this time but later at first execution
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('H' .. runCount)

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('I' .. runCount)

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('schedule(os.clock, 1, 2, {})')
    if withLogEvents and config.debug then
        expect('\'maxCalls\' must be a')
        --if not debug => error will not be reported at this time but later at first execution
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('J' .. runCount)

    assert(withLogEvents, 'withLogEvents must be true for this test')

end
return { test = function()
    initFlightAssistantTestConfig(config)

    runTests(true)

    config.debug = true

    runTests(true)
end }