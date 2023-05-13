local config = {
    extensions = { 'DCS-calls' },
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    local withLogEvents = true

    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('textToOwnShip(\'Private message\', 2)')
    expect('dostring_in(server, do local unit = world.getPlayer(); return unit and unit:getID() or nil; end)').andReturn(nil, '7')
    expect('dostring_in(server, trigger.action.outTextForUnit(7, "Private message", 2, false))').andReturn(nil, true)
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('textToOwnShip(\'Important message\', 3)')
    expect('dostring_in(server, trigger.action.outTextForUnit(7, "Important message", 3, false))').andReturn(nil, true)
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

end }