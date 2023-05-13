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
    expect('onSimulationFrame').andReturn('defineSignalSequence("abba").forSignals("A", "B", "B", "A").within(3)')
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onSignalSequence("abba").call(function() checkEvent("Here we go again!"); end)')
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('do fireSignal("A"); fireSignal("B"); end')
    fireUserCallback('onSimulationFrame')
    checkEvents('E')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('do fireSignal("B"); fireSignal("A"); end')
    expect("Here we go again!")
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('do fireSignal("B"); fireSignal("B");  fireSignal("A"); end')
    fireUserCallback('onSimulationFrame')
    checkEvents('G')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('do fireSignal("B"); fireSignal("B");  fireSignal("A"); end')
    expect("Here we go again!")
    fireUserCallback('onSimulationFrame')
    checkEvents('H')

    -- signal C is part of the group and interrupts the sequence
    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('do fireSignal("A"); fireSignal("C");  fireSignal("B");  fireSignal("B");  fireSignal("A"); end')
    fireUserCallback('onSimulationFrame')
    checkEvents('G')

    -- signal Z is not part of the group and is ignored when checking the sequence
    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('do fireSignal("A"); fireSignal("Z");  fireSignal("B");  fireSignal("B");  fireSignal("A"); end')
    expect("Here we go again!")
    fireUserCallback('onSimulationFrame')
    checkEvents('G')

end }