local config = {
    extensions = { 'builder', 'flags' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    setupFlightAssistant(config, selfData, false)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onCommand(25, 3001, 2, 3).call(function() checkEvent("Command 25-3001 !"); end)')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, '0')
    expect('dostring_in(server, a_start_listen_command(3001, "OCF1429-1", 1, 2, 3, 25))').andReturn(nil, true)
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, '0')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, '2')
    expect('dostring_in(server, trigger.action.setUserFlag("OCF1429-1", 0))').andReturn(nil, true)
    expect('dostring_in(server, a_start_listen_command(3001, "OCF1429-1", 1, 2, 3, 25))').andReturn(nil, true)
    expect('Command 25-3001 !')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, '0')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('E')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, '0')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('F')

    FlightAssistant = nil
    config.debug = not config.debug
    setupFlightAssistant(config, selfData, true)
    checkEvents('A2')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('onCommand(25, 3001).call(function() checkEvent("Command 25-3001 !"); end)')
    if config.debug then
        expect('builder registered: onCommand(25, 3001')
    end
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, '0')
    expect('dostring_in(server, a_start_listen_command(3001, "OCF1429-1", 1, 1, 10000, 25))').andReturn(nil, true)
    if config.debug then
        expect('Listening to device 25, command 3001')
        expect('builder unregistered: onCommand(25, 3001)')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B2')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, '1')
    expect('dostring_in(server, trigger.action.setUserFlag("OCF1429-1", 0))').andReturn(nil, true)
    expect('dostring_in(server, a_start_listen_command(3001, "OCF1429-1", 1, 1, 10000, 25))').andReturn(nil, true)
    if config.debug then
        expect('Listening to device 25, command 3001')
    end
    expect('Command 25-3001 !')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('C2')

end }