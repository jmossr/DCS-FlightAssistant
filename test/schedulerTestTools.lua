function checkSchedulerTest(id, selfData, delay, period, maxCalls, startTime, duration)
    local elapsed = os.clock() - startTime
    local nextFrame = 0.05
    local nextCheck = delay
    local prd = period or 0
    local checkCount = prd == 0 and 1 or maxCalls or -1
    if nextCheck < 0.05 then
        checkCount = checkCount - 1
        nextCheck = nextCheck + prd
    end
    while elapsed < duration do
        if elapsed >= nextFrame then
            nextFrame = elapsed + 0.05
            expect('Export.LoGetSelfData').andReturn(selfData)
            if checkCount ~= 0 and elapsed >= nextCheck then
                print('--> '.. elapsed)
                checkCount = checkCount - 1
                nextCheck = nextCheck + prd
                assert(scheduled.isScheduled(), "Not scheduled?")
                expect('Scheduled!')
            end
            expect('onSimulationFrame')
            fireUserCallback('onSimulationFrame')
        end
        elapsed = os.clock() - startTime
    end
    checkEvents(id .. '2')

    assert(checkCount <= 0, "More calls expected")
end

function runSchedulerTest(id, selfData, delay, period, maxCalls, duration)
    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('_G.scheduled = schedule(function() checkEvent("Scheduled!"); end, ' .. delay .. ', ' .. (period or 'nil') .. ', ' .. (maxCalls or 'nil') .. ')')
    if delay < 0.05 then
        expect('Scheduled!')
    end
    local startTime = os.clock()
    fireUserCallback('onSimulationFrame')
    checkEvents(id .. '1')

    checkSchedulerTest(id, selfData, delay, period, maxCalls, startTime, duration)
end

function runScheduleBuilderTest(id, selfData, delay, period, maxCalls, duration)
    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('_G.scheduled = schedule(' .. delay .. ', ' .. (period or 'nil') .. ', ' .. (maxCalls or 'nil') .. ').call(function() checkEvent("Scheduled!"); end)')
    if delay < 0.05 then
        expect('Scheduled!')
    end
    local startTime = os.clock()
    fireUserCallback('onSimulationFrame')
    checkEvents(id .. '1')

    checkSchedulerTest(id, selfData, delay, period, maxCalls, startTime, duration)
end

function checkScheduledActionCount(selfData, expectedCount)
    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('checkEvent(\'scheduledActionCount = \' .. tostring(getScheduledActionCount()))')
    expect('scheduledActionCount = ' .. expectedCount)
    fireUserCallback('onSimulationFrame')
    checkEvents('#')
end

