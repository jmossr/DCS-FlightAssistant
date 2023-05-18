local config = {
    extensions = { 'flags' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config, false, { setupOnCommandTest = true })

    setupFlightAssistant(config, nil, false)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, '0')
    expect('dostring_in(server, a_start_listen_command(1003, "OCF1429-1", 1, 1, 1, 52))').andReturn(nil, true)
    expect('onUnitActivated')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, "0")

    expect('onSimulationFrame').andReturn('onCommand(25, 3001, 2, 3, function() checkEvent("Command 25-3001 !"); end)')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-2")))').andReturn(nil, '0')
    expect('dostring_in(server, a_start_listen_command(3001, "OCF1429-2", 1, 2, 3, 25))').andReturn(nil, true)
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, '0')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-2")))').andReturn(nil, '0')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect("onUnitDeactivating")
    fireUserCallback('onSimulationStop')
    checkEvents('D')

    fireUserCallback('onMissionLoadBegin')
    checkEvents('E')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, '0')
    expect('dostring_in(server, a_start_listen_command(1003, "OCF1429-1", 1, 1, 1, 52))').andReturn(nil, true)
    expect("onUnitActivated")
    expect("activation 2")
    fireUserCallback('onSimulationStart')
    checkEvents('F')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, '0')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('G')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, '0')
    expect('onSimulationFrame').andReturn('onCommand(25, 3001, 2, 3, function() checkEvent("Command 25-3001 !"); end)')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-2")))').andReturn(nil, '0')
    expect('dostring_in(server, a_start_listen_command(3001, "OCF1429-2", 1, 2, 3, 25))').andReturn(nil, true)
    fireUserCallback('onSimulationFrame')
    checkEvents('H')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-1")))').andReturn(nil, '1')
    expect('dostring_in(server, trigger.action.setUserFlag("OCF1429-1", 0))').andReturn(nil, true)
    expect('dostring_in(server, a_start_listen_command(1003, "OCF1429-1", 1, 1, 1, 52))').andReturn(nil, true)
    expect('Command 52-1003 !')
    expect('dostring_in(server, return tostring(trigger.misc.getUserFlag("OCF1429-2")))').andReturn(nil, '0')
    expect('onSimulationFrame')
    fireUserCallback('onSimulationFrame')
    checkEvents('I')

end }