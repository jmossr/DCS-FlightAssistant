local config = {
    extensions = { 'signals' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    local withLogEvents = false

    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('defineSignalGroup("alfa").forSignals("A", "B", "C", "D").plus("E", "F", "G", "H")')
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('defineSignalSequence("abba").forSignals("A", "B", "B", "A").within(0.5)')
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onSignalSequence("abba").call(function() checkEvent("Here we go again!"); end)')
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('do fireSignal("A"); fireSignal("B"); end')
    local startTime = os.clock()
    fireUserCallback('onSimulationFrame')
    checkEvents('E')
    local elapsed = os.clock() - startTime
    local nextCheckTime = 0.05
    while elapsed < 0.55 do
        if elapsed >= nextCheckTime then
            nextCheckTime = nextCheckTime + 0.05
            expect('Export.LoGetSelfData').andReturn(selfData)
            expect('onSimulationFrame')
            fireUserCallback('onSimulationFrame')
            checkEvents('X')
        end
        elapsed = os.clock() - startTime
    end

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('do fireSignal("B"); fireSignal("A"); end')
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('do fireSignal("B"); fireSignal("B");  fireSignal("A"); end')
    expect("Here we go again!")
    fireUserCallback('onSimulationFrame')
    checkEvents('G')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('do fireSignal("B"); fireSignal("B");  fireSignal("A"); end')
    fireUserCallback('onSimulationFrame')
    checkEvents('H')

end }