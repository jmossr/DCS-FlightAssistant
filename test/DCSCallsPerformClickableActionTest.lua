local config = {
    extensions = { 'DCS-calls' },
    debug = false,
    DCSCalls = { use_a_cockpit_perform_clickable_action = false}
}

local selfData = { Name = 'TestUnit' }
local function performClickableActionTest(config, testIndex, inLuaExportEnv)
    initFlightAssistantTestConfig(config, nil, nil, inLuaExportEnv)

    local useGetDevice = not config.DCSCalls.use_a_cockpit_perform_clickable_action

    local withLogEvents = true
    setupFlightAssistant(config, selfData, withLogEvents, inLuaExportEnv)
    checkEvents('A' .. testIndex)

    expectE('LoGetSelfData', inLuaExportEnv).andReturn(selfData)
    expect('onSimulationFrame').andReturn('performClickableAction(25, 3001)')
    if useGetDevice then
        expectE('GetDevice(25)', inLuaExportEnv).andReturn({
            performClickableAction = function(_, c, v)  checkEvent('performClickableAction(' .. tostring(c) .. ', ' .. tostring(v) .. ')'); end, })
        expect('performClickableAction(3001, 1)')
    else
        if inLuaExportEnv then
            expect('a_cockpit_perform_clickable_action(25, 3001, 1)')
        else
            expect('dostring_in(server, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn('evil', nil)
            expect('dostring_in(mission, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn(nil, nil) --FAILED
            if withLogEvents then
                expect('evil')
                expect('FAILED: ?')
            end
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B' .. testIndex)

    expectE('LoGetSelfData', inLuaExportEnv).andReturn(selfData)
    expect('onSimulationFrame').andReturn('performClickableAction(25, 3001)')
    if useGetDevice then
        expectE('GetDevice(25)', inLuaExportEnv).andReturn({
            performClickableAction = function(_, c, v)  checkEvent('performClickableAction(' .. tostring(c) .. ', ' .. tostring(v) .. ')'); end, })
        expect('performClickableAction(3001, 1)')
    else
        if inLuaExportEnv then
            expect('a_cockpit_perform_clickable_action(25, 3001, 1)')
        else
            expect('dostring_in(server, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn('evil', nil)
            expect('dostring_in(mission, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn(nil, true) --SUCCESS
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('C' .. testIndex)

    expectE('LoGetSelfData', inLuaExportEnv).andReturn(selfData)
    expect('onSimulationFrame').andReturn('performClickableAction(25, "3001")')
    if config.debug then
        expect('\'command\' must be a number')
    else
        if useGetDevice then
            expectE('GetDevice(25)', inLuaExportEnv).andReturn({
                performClickableAction = function(_, c, v)  checkEvent('performClickableAction(' .. tostring(c) .. ', ' .. tostring(v) .. ')'); end, })
            expect('performClickableAction(3001, 1)')
        else
            if inLuaExportEnv then
                expect('a_cockpit_perform_clickable_action(25, 3001, 1)')
            else
                expect('dostring_in(server, a_cockpit_perform_clickable_action(25, 3001, 1))').andReturn(nil, true)
            end
        end
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('D' .. testIndex)

    reset()

    assert(withLogEvents, 'withLogEvents must be true for this test')

end

return { test = function()
    config.debug = false
    config.DCSCalls.use_a_cockpit_perform_clickable_action = false
    performClickableActionTest(config, 1, false)
    config.debug = true
    performClickableActionTest(config, 2, false)

    config.debug = false
    config.DCSCalls.use_a_cockpit_perform_clickable_action = true
    performClickableActionTest(config, 3, false)
    config.debug = true
    performClickableActionTest(config, 4, false)

    config.debug = false
    config.DCSCalls.use_a_cockpit_perform_clickable_action = false
    performClickableActionTest(config, 5, true)
    config.debug = true
    performClickableActionTest(config, 6, true)

    config.debug = false
    config.DCSCalls.use_a_cockpit_perform_clickable_action = true
    performClickableActionTest(config, 7, true)
    config.debug = true
    performClickableActionTest(config, 8, true)
end }