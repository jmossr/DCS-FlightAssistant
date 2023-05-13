require('schedulerTestTools')

local config = {
    extensions = { 'builder', 'scheduler' },
    debug = true,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    setupFlightAssistant(config, selfData, false)
    checkEvents('Init')

    runScheduleBuilderTest('A', selfData, 0.5, nil, nil, 0.7)
    assert(not scheduled.isScheduled())
    checkScheduledActionCount(selfData, 0)

    runScheduleBuilderTest('B', selfData, 0, nil, nil, 0.3)
    assert(not scheduled.isScheduled())
    checkScheduledActionCount(selfData, 0)

    runScheduleBuilderTest('C', selfData, 0.3, 0.7, 3, 3)
    assert(not scheduled.isScheduled())
    checkScheduledActionCount(selfData, 0)

    runScheduleBuilderTest('D', selfData, 0.3, 0.6, nil, 3)
    assert(scheduled.isScheduled())
    checkScheduledActionCount(selfData, 1)

    scheduled.cancel()
    checkSchedulerTest('E', selfData, 1, 1, 0, os.clock(), 2)

    log.setEventsEnabled(true)
    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('_G.scheduled = schedule(function() checkEvent("Scheduled!"); end, 0.5)')
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

    FlightAssistant = nil
    config.debug = not config.debug
    setupFlightAssistant(config, selfData, true)
    checkEvents('G')

    runScheduleBuilderTest('H', selfData, 0.5, nil, nil, 0.7)
    assert(not scheduled.isScheduled())
    checkScheduledActionCount(selfData, 0)

    runScheduleBuilderTest('I', selfData, 0.3, 0.6, nil, 3)
    assert(scheduled.isScheduled())
    checkScheduledActionCount(selfData, 1)

    scheduled.cancel()
    checkSchedulerTest('J', selfData, 1, 1, 0, os.clock(), 2)

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('_G.scheduled = schedule(function() checkEvent("Scheduled!"); end, 0.5)')
    fireUserCallback('onSimulationFrame')
    checkEvents('K')

end }