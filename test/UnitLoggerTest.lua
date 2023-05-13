local config = {
    debug = false,
}

local selfData = { Name = 'TestUnit' }

return { test = function()
    initFlightAssistantTestConfig(config)

    local withLogEvents = true

    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('logger.error("something failed")')
    if withLogEvents then
        expect('ERROR    FLIGHTASSISTANT (main): [Test][TestUnit] something failed')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('logger.warning("attention")')
    if withLogEvents then
        expect('WARNING  FLIGHTASSISTANT (main): [Test][TestUnit] attention')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('C')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('logger.info("some information")')
    if withLogEvents then
        expect('INFO     FLIGHTASSISTANT (main): [Test][TestUnit] some information')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('D')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('logger.debug("debug message")')
    if withLogEvents and config.debug then
        expect('INFO     FLIGHTASSISTANT (main): [Test][TestUnit] debug message')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('E')

    config.debug = not config.debug

    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A2')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('logger.debug("debug message")')
    if withLogEvents and config.debug then
        expect('INFO     FLIGHTASSISTANT (main): [Test][TestUnit] debug message')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B2')

    config.debug = false
    config.debugUnit = true
    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A3')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('logger.debug("debug message")')
    if withLogEvents then
        expect('INFO     FLIGHTASSISTANT (main): [Test][TestUnit] debug message')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B3')

    config.debug = false
    config.debugUnit = false
    config.flightAssistants.Test.debugUnit = true
    FlightAssistant = nil
    setupFlightAssistant(config, selfData, withLogEvents)
    checkEvents('A4')

    expect('Export.LoGetSelfData').andReturn(selfData)
    expect('onSimulationFrame').andReturn('logger.debug("debug message")')
    if withLogEvents then
        expect('INFO     FLIGHTASSISTANT (main): [Test][TestUnit] debug message')
    end
    fireUserCallback('onSimulationFrame')
    checkEvents('B4')

    assert(withLogEvents, 'withLogEvents must be true for this test')
end }