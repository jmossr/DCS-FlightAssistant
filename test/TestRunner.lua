local baseDir = '..\\'
local flightAssistantScriptDir = baseDir .. 'core\\'
local flightAssistantScriptFile = flightAssistantScriptDir .. 'FlightAssistant.lua'
local extensionsDir = baseDir .. 'extensions\\'
local playerUnitScriptsDir = baseDir .. 'test\\pUnit\\'

function initFlightAssistantTestConfig(config, reload, unitConfig)
    config.flightAssistantScriptFile = flightAssistantScriptFile
    config.extensionsDir = extensionsDir
    config.playerUnitScriptsDir = playerUnitScriptsDir
    config.flightAssistants = {
        Test = {
            reloadOnMissionLoad = reload or false,
            unitConfig = unitConfig,
        },
    }
end

local expectations = {}
local expectationIndex = 1;
local errors = 0
local debugUserCallbacks = false
local function createExpectation(eventName)
    local expectation = {
        eventName = eventName,
        andReturn = nil
    }
    expectation.andReturn = function(...)
        expectation.doReturn = function()
            return unpack(arg)
        end
        return expectation
    end
    expectation.andRaiseError = function(msg)
        expectation.doReturn = function()
            error(msg, 3)
        end
    end
    return expectation
end

function expect(eventName)
    local expectation = createExpectation(eventName)
    table.insert(expectations, expectation)
    return expectation
end
function expectError(msg, f, ...)
    local ok, r = pcall(f, unpack(arg))
    if ok then
        errors = errors + 1
        print('! error expected - ' .. msg)
    else
        print('expected error received: ' .. r)
    end
end
local function resetExpectations()
    expectations = {}
    expectationIndex = 1
end

function checkEvent(eventName, partialMatch)
    local expectation = expectations[expectationIndex]
    if expectation then
        expectationIndex = expectationIndex + 1
        if partialMatch and string.find(eventName, expectation.eventName, 1, true) or eventName == expectation.eventName then
            if expectation.doReturn then
                return expectation.doReturn()
            end
        else
            errors = errors + 1
            error('expected "' .. expectation.eventName .. '", got: ' .. eventName, 2)
        end
    else
        errors = errors + 1
        error(eventName .. ' not expected', 2)
    end
end

function checkEvents(msg)
    local expectation = expectations[expectationIndex]
    if expectation then
        while expectation do
            errors = errors + 1
            print('! expecting ' .. expectation.eventName)
            expectationIndex = expectationIndex + 1
            expectation = expectations[expectationIndex]
        end
    end
    resetExpectations()
    print(msg or '...')
end

log = { ERROR = 'ERROR   ', INFO = 'INFO    ', WARNING = 'WARNING ', write = 1, setEventsEnabled = 2 }
local log2Events = false
log.setEventsEnabled = function(enabled)
	log2Events = enabled
end
log.write = function(logSubsystemName, level, msg)
	local txt = tostring(level) .. ' ' .. logSubsystemName .. ' (main): ' .. msg
	print(txt)
	if log2Events then
		checkEvent(txt, true)
	end
end

local userCallbacks
DCS = { setUserCallbacks = 1, reloadUserScripts = 2 }
DCS.setUserCallbacks = function(callbacks)
    checkEvent("DCS.setUserCallbacks")
    userCallbacks = callbacks
end
DCS.reloadUserScripts = function()
    checkEvent("DCS.reloadUserScripts")
end

Export = { LoGetSelfData = 1, GetDevice = 2 }
Export.LoGetSelfData = function()
    return checkEvent("Export.LoGetSelfData")
end
Export.GetDevice = function(deviceId)
    return checkEvent('Export.GetDevice(' .. deviceId .. ')')
end
Export.LoGetModelTime = function()
    return os.clock()
end
Export.LoIsOwnshipExportAllowed = function()
    return true
end
net = { dostring_in = function(env, lua)
    return checkEvent("dostring_in(" .. env .. ', ' .. lua .. ')')
end }
function fireUserCallback(name)
    local cb = userCallbacks and userCallbacks[name]
    if cb then
        if debugUserCallbacks then
            print("    Calling " .. name)
        end
        cb()
    elseif debugUserCallbacks then
        print("    Warning: No User callback " .. name)
    end
end

function printTable(name, t)
    if t then
        if (type(t) ~= 'table') then
            print(string.format('%s is not a table but a %s', name, type(t)))
        else
            print(string.format('Table %s', name))
            for n, v in pairs(t) do
                print(string.format("  - %s = %s (%s)", n, tostring(v), type(v)))
            end
        end
    else
        print(string.format("Table not found: %s = nil", name))
    end
end

local lua, err = loadfile(flightAssistantScriptFile)
if not lua then
    error('Loading ' .. flightAssistantScriptFile .. ' FAILED: ' .. err)
end

function startFlightAssistant(config)
    local ok, r = pcall(lua, config)
    if not ok then
        error('Starting FlightAssistant FAILED: ' .. r)
    end
end

function setupFlightAssistant(config, selfData, withLogEvents)
    local withDebugEvents = config.debug and withLogEvents
    log.setEventsEnabled(withLogEvents)
    if withLogEvents then
        expect('Installing DCS Control API User callbacks')
    end
    expect('DCS.setUserCallbacks')
    if withDebugEvents then
        expect('flightAssistantScriptFile')
        expect('flightAssistantScriptDir')
        expect('extensionsDir')
    end
    if withLogEvents then
        expect('[Test] FlightAssistant created')
    end
    expect('Export.LoGetSelfData').andReturn(selfData)
    if selfData then
        if withDebugEvents then
            expect('Searching')
            expect('loaded')
        end
        expect('onUnitActivated')
        if withLogEvents then
            expect('activated')
        end
    end
    startFlightAssistant(config)
    fireUserCallback('onSimulationStart')
    return withDebugEvents
end

local function runTestCase(name)
    local testCase = require(name)
    local ok, r = pcall(testCase.test)
    if not ok then
        errors = errors + 1
        print('! ' .. r)
    end
end

local testCases = {
    'InitFlightAssistantTest',
    'CallbacksTest',
    'CallbacksAfterReloadTest',
    'UnitCallbacksTest',
    'UnitLoadingTest',
    'DCSCallsGetUserFlagTest',
    'DCSCallsSetUserFlagTest',
    'DCSCallsOutTextForUnitTest',
    'DCSCallsTextToOwnShipTest',
    'DCSCallsStartListenCommandTest',
    'DCSCallsPerformClickableCommandTest',
    'UnitLoggerTest',
    'BuilderTest',
    'DCSCallsBuilderTest',
    'SchedulerProtectedTest',
    'SchedulerActionBuilderTest',
    'SignalTest',
    'OnFlagValueTest',
    'OnFlagValueChangedTest',
    'OnFlagValueBetweenTest',
    'OnFlagValueBuilderTest',
    'OnFlagValueChangedBuilderTest',
    'OnFlagValueBetweenBuilderTest',
    'FlagsOnCommandTest',
    'FlagsOnCommandBuilderTest',
    'SignalSequenceTest',
    'SignalSequenceTimeoutTest',
    'DCSCallsOnDeviceArgumentTest',
    'DCSCallsOnDeviceArgumentBuilderTest',
    'SchedulerTest',
    'SchedulerBuilderTest',
    'FlagsOnCommandSurvivesMissionLoadTest',
}
local skip = {
    --SchedulerTest = true,
    --SchedulerBuilderTest = true,
}

local testResults = {}

for _,t in pairs(testCases) do
    print(t)
    print('-------------------------------------------------------------------------')
    if skip[t] then
        print('Skipping test')
        testResults[t] = "SKPD"
    else
        errors = 0
        runTestCase(t)
        if expectations[1] then
            checkEvents()
        end
        testResults[t] = errors == 0 and 'OK' or 'DEGD'
        print('--- ' .. testResults[t] .. ' ---')
        print('=========================================================================')
        FlightAssistant = nil
        log2Events = false
    end
end

for t, r in pairs(testResults) do
    local title = t .. ': '
    while #title < 42 do
        title = title .. (#title % 3 == 0 and '.' or ' ')
    end
    print(title .. r)
end