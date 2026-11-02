local config = {
    extensions = { 'builder', 'DCS-calls' },
    debug = false,
    NetRecvChatEnabled = true,
    multiplayer = true
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config, false, { setupTextToOwnShipActionBuilderTest = true })

    local withLogEvents = false

    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationResume')
    expect('net.recv_chat(Simulation resumed, 0)').andReturn(nil, true)
    fireUserCallback('onSimulationResume')
    checkEvents('C')

    expect('onSimulationPause')
    fireUserCallback('onSimulationPause')
    checkEvents('D')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationResume')
    expect('net.recv_chat(Simulation resumed, 0)').andReturn(nil, true)
    fireUserCallback('onSimulationResume')
    checkEvents('E')

    expect('Export.LoGetSelfData').andReturn(nil)
    expect('onUnitDeactivating')
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onUnitActivated')
    expect('activation 2')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('G')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationResume')
    expect('net.recv_chat(Simulation resumed, 0)').andReturn(nil, true)
    fireUserCallback('onSimulationResume')
    checkEvents('H')

end }