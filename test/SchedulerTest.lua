require('schedulerTestTools')

local config = {
    extensions = { 'scheduler' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    setupFlightAssistant(config, selfData, false)
    checkEvents('Init')

    runSchedulerTest('A',selfData, 0.5, nil, nil, 0.7)
    assert(not scheduled.isScheduled())
    checkScheduledActionCount(selfData, 0)

    runSchedulerTest('B', selfData, 0, nil, nil, 0.3)
    assert(not scheduled.isScheduled())
    checkScheduledActionCount(selfData, 0)

    runSchedulerTest('C', selfData, 0.3, 0.7, 3, 3)
    assert(not scheduled.isScheduled())
    checkScheduledActionCount(selfData, 0)

    runSchedulerTest('D', selfData, 0.3, 0.6, nil, 3)
    assert(scheduled.isScheduled())
    checkScheduledActionCount(selfData, 1)

    scheduled.cancel()
    checkSchedulerTest('E', selfData, 1, 1, 0, os.clock(), 2)

    log.setEventsEnabled(true)
    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('_G.scheduled = schedule(0.5).call(function() checkEvent("Scheduled!"); end)')
    if config.debug then
        expect('\'f\' must be a function')
    else
        expect('attempt to perform arithmetic on local \'delay\'')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

    FlightAssistant = nil
    config.debug = not config.debug
    setupFlightAssistant(config, selfData, true)
    checkEvents('G')

    runSchedulerTest('H', selfData, 0.5, nil, nil, 0.7)
    assert(not scheduled.isScheduled())
    checkScheduledActionCount(selfData, 0)

    runSchedulerTest('I', selfData, 0.3, 0.6, nil, 3)
    assert(scheduled.isScheduled())
    checkScheduledActionCount(selfData, 1)

    scheduled.cancel()
    checkSchedulerTest('J', selfData, 1, 1, 0, os.clock(), 2)

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('_G.scheduled = schedule(0.5).call(function() checkEvent("Scheduled!"); end)')
    if config.debug then
        expect('\'f\' must be a function')
    else
        expect('attempt to perform arithmetic on local \'delay\'')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('K')

end }