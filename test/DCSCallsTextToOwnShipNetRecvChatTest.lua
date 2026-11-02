local config = {
    extensions = { 'DCS-calls' },
    debug = false,
    NetRecvChatEnabled = true
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    local withLogEvents = true

    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('textToOwnShip(\'Private message\', 2)')
    expect('net.recv_chat(Private message, 0)').andReturn(nil, true)
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('textToOwnShip(\'Important message\', 3)')
    expect('net.recv_chat(Important message, 0)').andReturn(nil, true)
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

end }