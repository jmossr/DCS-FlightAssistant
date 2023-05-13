require('schedulerTestTools')
local config = {
    extensions = { 'builder', 'scheduler' },
    debug = true,
}

local selfData = { Name = 'TestUnit' }

local function initSchedulerActionTest(id, delay, period, maxCalls)
    expect('Export.LoGetSelfData').andReturn(selfData)
    local args = tostring(delay)
    if (period or maxCalls) then
        args = args .. ',' .. tostring(period)
        if maxCalls then
            args = args .. ', ' .. tostring(maxCalls)
        end
    end
    expect('onSimulationFrame').andReturn('_G.scheduled = onSimulationResume().schedule(' ..args .. ').call(function() checkEvent("Scheduled!"); end)')
    if delay < 0.05 then
        expect('Scheduled!')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents(id .. '1')
end

return { test = function()
    initFlightAssistantTestConfig(config)

    setupFlightAssistant(config, selfData, false)
    checkEvents('Init')

    initSchedulerActionTest('A', 0.5, nil, nil)
    assert(not scheduled.isScheduled())
    checkScheduledActionCount(selfData, 0)

    expect('onSimulationResume')
    local startTime = os.clock()
    fireUserCallback('onSimulationResume')
    checkEvents('B')
    assert(scheduled.isScheduled())
    checkScheduledActionCount(selfData, 1)

    checkSchedulerTest('C', selfData,0.5, nil, nil, startTime, 0.7)

    printTable("scheduled", scheduled)
    assert(not scheduled.isScheduled())
    checkScheduledActionCount(selfData, 0)

end }