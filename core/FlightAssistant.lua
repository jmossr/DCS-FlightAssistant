--[[--------
	Flight Assistant
------------]]
local type = type
local tostring = tostring
local pairs = pairs
local smatch = string.match
local sformat = string.format
local sgsub = string.gsub
local tinsert = table.insert
local loadfile = loadfile
local pcall = pcall
local error = error
local tonumber = tonumber
local setmetatable = setmetatable
local flightAssistantConfig = ...
local config = (flightAssistantConfig and type(flightAssistantConfig) == 'table') and flightAssistantConfig or nil
local isReloadUserScriptsOnMissionLoad = not config or config.reloadUserScriptsOnMissionLoad
local logSubsystemName = config and config.logSubsystemName and tostring(config.logSubsystemName) or 'FLIGHTASSISTANT'
local lwrite = log.write
local lINFO = log.INFO
local lWARNING = log.WARNING
local lERROR = log.ERROR
local LoGetSelfData = Export.LoGetSelfData
local LoIsOwnshipExportAllowed = Export.LoIsOwnshipExportAllowed
local setfenv = setfenv
local unpack = unpack

local function clearTable(table)
    if type(table) == 'table' then
        for k, _ in pairs(table) do
            table[k] = nil
        end
    end
end

--[[------
    --Install DCS callbacks
--------]]
local faCallbacks = {}
local simulationActive = false
local simulationPaused = true
local currentPUnitData
do
    local executeCallbacks = function(cb)
        for _, cbs in pairs(faCallbacks) do
            cbs[cb](cbs)
        end
    end
    lwrite(logSubsystemName, lINFO, 'Installing DCS Control API User callbacks')
    DCS.setUserCallbacks({
        onMissionLoadBegin = function(_)
            simulationPaused = true
            simulationActive = false
            if isReloadUserScriptsOnMissionLoad then
                FlightAssistant = nil
                clearTable(faCallbacks)
                lwrite(logSubsystemName, lINFO, 'Reloading user scripts...')
                DCS.reloadUserScripts()
            end
            executeCallbacks('onMissionLoadBegin');
        end,
        onSimulationStart = function(_)
            simulationPaused = true
            simulationActive = true
            currentPUnitData = LoGetSelfData()
            executeCallbacks('onSimulationStart');
        end,
        onSimulationStop = function(_)
            simulationActive = false
            currentPUnitData = nil
            executeCallbacks('onSimulationStop');
        end,
        onSimulationFrame = function(_)
            if simulationActive then
                currentPUnitData = LoGetSelfData()
            end
            executeCallbacks('onSimulationFrame');
        end,
        onSimulationPause = function(_)
            simulationPaused = true
            executeCallbacks('onSimulationPause');
        end,
        onSimulationResume = function(_)
            simulationPaused = false
            if simulationActive then
                currentPUnitData = LoGetSelfData()
            end
            executeCallbacks('onSimulationResume');
        end
    })
end
--[[------
    Check minimum requirements
------]]--
if not LoIsOwnshipExportAllowed() then
    error('Access to ownship data is denied on this server. (Export.LoIsOwnshipExportAllowed() == false)')
end
--[[------
    --Config
--------]]
if not flightAssistantConfig then
    error('FlightAssistant received no configuration', 2)
elseif type(flightAssistantConfig) ~= 'table' then
    error('FlightAssistant configuration must be a table, not a ' .. type(flightAssistantConfig), 2)
elseif type(flightAssistantConfig.flightAssistantScriptFile) ~= 'string' then
    error("FlightAssistant configuration should contain 'flightAssistantScriptFile' specifying the full path to file FlightAssistant.lua .", 2)
end

local flightAssistantScriptDir = smatch(flightAssistantConfig.flightAssistantScriptFile, '(.*[\\/])[^\\/]+$')
local extensionsDir = flightAssistantConfig.extensionsDir or (flightAssistantScriptDir .. 'extensions')
local isDebugEnabled = flightAssistantConfig.debug and true or false
local isDebugUnitEnabled = flightAssistantConfig.debugUnit and true or isDebugEnabled
local pUnitLibName = flightAssistantConfig.pUnitLib or 'pUnit'

--[[------
    --Logging
--------]]
local function fmtInfo(fmt, ...)
    lwrite(logSubsystemName, lINFO, sformat(fmt, unpack(arg)))
end
local function fmtWarning(fmt, ...)
    lwrite(logSubsystemName, lWARNING, sformat(fmt, unpack(arg)))
end
local function fmtError(fmt, ...)
    lwrite(logSubsystemName, lERROR, sformat(fmt, unpack(arg)))
end

if isDebugEnabled then
    fmtInfo('flightAssistantScriptFile = %s', flightAssistantConfig.flightAssistantScriptFile)
    fmtInfo('flightAssistantScriptDir = %s', flightAssistantScriptDir)
    fmtInfo('extensionsDir = %s', extensionsDir)
end

--[[------
    --Utilities
------]]--
local function printTable(name, t)
    if t then
        if (type(t) ~= 'table') then
            fmtInfo('%s is not a table but a %s', name, type(t))
        else
            fmtInfo('Table %s', name)
            for n, v in pairs(t) do
                fmtInfo("  - %s = %s (%s)", n, tostring(v), type(v))
            end
        end
    else
        fmtInfo("Table not found: %s = nil", name)
    end
end
local function copyAll(src, dest)
    for k, v in pairs(src) do
        dest[k] = v
    end
end
local function getTrimmedTableId(t)
    return tostring(t):match(":%s*0*([%dABCDEFabcdef]+)")
end
local function NOOP()
end
local function indexOf(list, element)
    local n = #list
    for i = 1, n do
        if list[i] == element then
            return i
        end
    end
    return 0
end
local function listAddOnce(list, element)
    local n = #list
    for i = 1, n do
        if list[i] == element then
            return i
        end
    end
    list[n + 1] = element
end
local function checkArgType(fsignature, argName, arg, expectedType, requireNonNil, errorLevel)
    if requireNonNil or arg then
        local argType = type(arg)
        if argType ~= expectedType then
            error(sformat('%s \'%s\' must be a %s, not a %s', fsignature, argName, expectedType, argType), errorLevel + 1)
        end
    end
end
local function checkStringOrNumberArg(fsignature, argName, arg, requireNonNil, errorLevel)
    if requireNonNil or arg then
        local argType = type(arg)
        if argType ~= 'string' and argType ~= 'number' then
            error(sformat('%s \'%s\' must be a string or a number, not a %s', fsignature, argName, argType), errorLevel + 1)
        end
    end
end
local function checkPositiveNumberArg(fsignature, argName, arg, requireNonNil, errorLevel)
    checkArgType(fsignature, argName, arg, 'number', requireNonNil, errorLevel + 1)
    if arg and arg < 0 then
        error(sformat('%s \'%s\' must be a positive number, not %s', fsignature, argName, arg), errorLevel + 1)
    end
end

--[[------
    --Actions
------]]--
local function fireConditional(self, ...)
    if self.state then
        self.state = self.condition(unpack(arg))
    elseif self.condition(unpack(arg)) then
        self.state = true
        self.action:fire(unpack(arg))
    end
end
local function addAction(actionList, action, condition)
    if condition then
        tinsert(actionList, { action = action, condition = condition, fire = fireConditional })
    else
        tinsert(actionList, action)
    end
end
local absoluteMinimumEventValue = flightAssistantConfig.absoluteMinimumEventValue or -1000000
local absoluteMaximumEventValue = flightAssistantConfig.absoluteMaximumEventValue or 1000000
local function addOnValueChangedAction(eventSourceAccessor, action, debug)
    local eventSource = eventSourceAccessor(absoluteMinimumEventValue, absoluteMaximumEventValue)
    if debug then
        eventSource.debug = true
    end
    addAction(eventSource.observers, action)
end
local function addOnValueAction(eventSourceAccessor, action, value, debug)
    local expected = tostring(value)
    local eventSource = eventSourceAccessor(value, value)
    if debug then
        eventSource.debug = true
    end
    addAction(eventSource.observers, action, function(newValue)
        return expected == tostring(newValue);
    end)
end
local function addOnValueBetweenAction(eventSourceAccessor, action, minValue, maxValue, debug)
    local min = tonumber(minValue) or absoluteMinimumEventValue
    local max = tonumber(maxValue) or absoluteMaximumEventValue
    local eventSource = eventSourceAccessor(minValue, maxValue)
    if debug then
        eventSource.debug = true
    end
    addAction(eventSource.observers, action, function(newValue)
        local numVal = tonumber(newValue)
        return numVal and min <= numVal and numVal <= max;
    end)
end
local function fire(actionList, ...)
    local n = #actionList
    local action
    for i = 1, n do
        action = actionList[i]
        action:fire(unpack(arg))
    end
end
local function isSimulationPaused()
    return simulationPaused
end
--[[------
    --Lib support
--------]]
local libs = {}
local libEnv = { fmtInfo = fmtInfo, fmtWarning = fmtWarning, fmtError = fmtError,
                 NOOP = NOOP, indexOf = indexOf, listAddOnce = listAddOnce, printTable = printTable, clearTable = clearTable,
                 copyAll = copyAll, getTrimmedTableId = getTrimmedTableId,
                 checkArgType = checkArgType, checkStringOrNumberArg = checkStringOrNumberArg, checkPositiveNumberArg = checkPositiveNumberArg,
                 addAction = addAction, addOnValueChangedAction = addOnValueChangedAction,
                 addOnValueAction = addOnValueAction, addOnValueBetweenAction = addOnValueBetweenAction, fire = fire,
                 isDebugEnabled = isDebugEnabled, isDebugUnitEnabled = isDebugUnitEnabled,
                 flightAssistantConfig = flightAssistantConfig, isSimulationPaused = isSimulationPaused }
setmetatable(libEnv, { __index = _G })

local function loadLua(path, env, ...)
    if isDebugEnabled then
        fmtInfo('Loading file %s', path)
    end
    local f, err = loadfile(path)
    if not f then
        error('Failed to load file ' .. path .. ': ' .. (err or '?'))
    end
    if env then
        setfenv(f, env)
    end
    local ok, r = pcall(f, unpack(arg))
    if not ok then
        error('Executing lua in ' .. path .. ' FAILED: ' .. (r or '?'))
    end
    return r or true
end
local function loadLib(path)
    return loadLua(path, libEnv)
end
--[[------
    --Extension support
--------]]
local INIT_ASSISTANT = 'initAssistant'
local INIT_PUNIT = 'initPUnit'
local BEFORE_PUNIT_ACTIVATION = 'beforePUnitActivation'
local AFTER_PUNIT_ACTIVATION = 'afterPUnitActivation'
local BEFORE_PUNIT_DEACTIVATION = 'beforePUnitDeactivation'
local AFTER_PUNIT_DEACTIVATION = 'afterPUnitDeactivation'
local BEFORE_SIMULATION_FRAME = 'beforeSimulationFrame'
local AFTER_SIMULATION_FRAME = 'afterSimulationFrame'
local extensionEvents = { INIT_ASSISTANT,
                          INIT_PUNIT, BEFORE_PUNIT_ACTIVATION, AFTER_PUNIT_ACTIVATION,
                          BEFORE_PUNIT_DEACTIVATION, AFTER_PUNIT_DEACTIVATION,
                          BEFORE_SIMULATION_FRAME, AFTER_SIMULATION_FRAME }
local extensions = {}
local function addExtensionFunction(libName, lib, functionName)
    local f = lib[functionName]
    if f and type(f) ~= 'function' then
        fmtWarning("Ignoring %s.%s: it is a %s instead of a function.", libName, functionName, type(f))
    elseif f then
        if not extensions[functionName] then
            extensions[functionName] = { f }
        else
            tinsert(extensions[functionName], f)
        end
    end
end
local function callExtensionFunctions(functionName, p1, p2)
    local functions = extensions[functionName]
    if functions then
        for _, f in pairs(functions) do
            f(p1, p2)
        end
    end
end
--[[------
    --Imports
--------]]
local function requireLib(name, path, isExtension)
    local lib = libs[path]
    if not lib then
        lib = loadLib(path)
        libs[path] = lib
        if isExtension then
            for _, event in pairs(extensionEvents) do
                addExtensionFunction(name, lib, event)
            end
        end
    end
    return lib
end
local function requireExtension(name)
    return requireLib(name, extensionsDir .. name .. '.lua', true)
end
local function getOptionalExtension(name)
    return libs[extensionsDir .. name .. '.lua']
end
libEnv.requireExtension = requireExtension
libEnv.getOptionalExtension = getOptionalExtension

local globalns = _G

local pUnitLib = requireLib(pUnitLibName, flightAssistantScriptDir .. pUnitLibName .. '.lua')
local tryLoadPUnit = pUnitLib.tryLoadPUnit
local activatePUnit = pUnitLib.activatePUnit
local deactivatePUnit = pUnitLib.deactivatePUnit
local fireSimCallback = pUnitLib.fireSimCallback
libEnv.addSimCallbackAction = pUnitLib.addSimCallbackAction
libEnv.getOrCreateCallbackAction = pUnitLib.getOrCreateCallbackAction

if type(flightAssistantConfig.extensions) == 'table' then
    for _, ext in pairs(flightAssistantConfig.extensions) do
        requireExtension(ext)
    end
end

--[[------
    --Assistant
--------]]
local assistantCount = 0
local function assistantCounter()
    assistantCount = assistantCount + 1
    return assistantCount
end
local function setupAssistant(assistantName, configTable)
    if type(assistantName) ~= 'string' then
        error("Flight assistant name must be string, not a " .. type(assistantName), 2)
    end
    if FlightAssistant and FlightAssistant[assistantName] then
        error("A flight assistant with name '" .. assistantName .. "' already exists.", 2)
    end
    if configTable.pUnitFallbackTable and type(configTable.pUnitFallbackTable) ~= 'table' then
        error("Flight assistant '" .. assistantName .. "' configuration error: pUnitFallbackTable must be a table, not a " .. type(configTable.pUnitFallbackTable), 2)
    end

    local assistantSelf = {
        name = assistantName,
        id = getTrimmedTableId(faCallbacks) .. ':' .. assistantCounter(),
        --playerUnitScriptsDir is for testing purposes
        assistantDir = flightAssistantConfig.playerUnitScriptsDir or (flightAssistantScriptDir .. sgsub(assistantName, '%s+', '_') .. '\\'),
        pUnitFallbackTable = configTable.pUnitFallbackTable or {},
        pUnits = {},
        isSimulationPaused = isSimulationPaused,
        reloadOnMissionLoad = configTable.reloadOnMissionLoad,
        debugUnit = isDebugEnabled or isDebugUnitEnabled or configTable.debugUnit and true or false,
        pUnitConfig = configTable.unitConfig or {}
    }

    callExtensionFunctions(INIT_ASSISTANT, assistantSelf, configTable)

    setfenv(1, assistantSelf)

    --[[------
        Tools
    --------]]
    function include(name, env, ...)
        if not env.includes then
            env.includes = {}
        end
        if not env.includes[name] then
            env.includes[name] = loadLua(assistantDir .. name .. ".lua", env, unpack(arg))
        end
    end

    --[[------
        PUnit management
    --------]]
    function deactivateActivePUnit()
        if activePUnit then
            callExtensionFunctions(BEFORE_PUNIT_DEACTIVATION, activePUnit)
            deactivatePUnit(activePUnit)
            callExtensionFunctions(AFTER_PUNIT_DEACTIVATION, activePUnit)
            activePUnit.proxy.selfData = nil
            fmtInfo('[%s] PUnit %s deactivated', assistantName, activePUnit.name)
            activePUnit = nil
        end
        activePUnitName = nil
    end

    function findPUnitTable(name)
        local alias = name
        local pUnitTable = pUnits[alias]
        if not pUnitTable then
            while not pUnitTable do
                if isDebugEnabled then
                    fmtInfo('[%s] Searching for %s.lua', assistantName, alias)
                end
                pUnitTable = tryLoadPUnit(assistantSelf, alias, extensions[INIT_PUNIT])
                if pUnitTable then
                    pUnits[alias] = pUnitTable
                else
                    local nextAlias = pUnitFallbackTable[alias]
                    if not nextAlias then
                        pUnits[alias] = { name = alias, dummy = true }
                        return nil
                    else
                        pUnits[alias] = { name = alias, dummy = true, ref = nextAlias }
                        pUnitTable = pUnits[nextAlias]
                        alias = nextAlias
                    end
                end
            end
        end
        while pUnitTable.ref do
            pUnitTable = pUnits[pUnitTable.ref]
        end
        return not pUnitTable.dummy and pUnitTable or nil
    end

    function tryActivatePUnit()
        local currentPUnitName = currentPUnitData and currentPUnitData['Name']
        if currentPUnitName ~= activePUnitName then
            deactivateActivePUnit()
            activePUnitName = currentPUnitName
            if activePUnitName then
                activePUnit = findPUnitTable(activePUnitName)
                if activePUnit then
                    activePUnit.proxy.selfData = currentPUnitData
                    callExtensionFunctions(BEFORE_PUNIT_ACTIVATION, activePUnit)
                    activatePUnit(activePUnit)
                    callExtensionFunctions(AFTER_PUNIT_ACTIVATION, activePUnit)
                    fmtInfo('[%s] PUnit %s activated', assistantName, activePUnit.name)
                end
            end
        elseif activePUnit then
            activePUnit.proxy.selfData = currentPUnitData
        end
    end

    --[[------
        Callbacks
    --------]]
    function onMissionLoadBegin()
        if reloadOnMissionLoad then
            fmtInfo('[%s] Reloading pUnits', assistantName)
            pUnits = {}
        end
    end

    function onSimulationStart()
        tryActivatePUnit()
    end

    function onSimulationStop()
        deactivateActivePUnit()
    end

    function onSimulationPause()
        fireSimCallback(activePUnit, 'onSimulationPause')
    end

    function onSimulationResume()
        tryActivatePUnit()
        fireSimCallback(activePUnit, 'onSimulationResume')
    end

    function onSimulationFrame()
        if simulationActive then
            tryActivatePUnit()
            if activePUnit then
                callExtensionFunctions(BEFORE_SIMULATION_FRAME, activePUnit)
                fireSimCallback(activePUnit, 'onSimulationFrame')
                callExtensionFunctions(AFTER_SIMULATION_FRAME, activePUnit)
            end
        end
    end

    --[[------
        Register Assistant
    --------]]
    tinsert(faCallbacks, {
        onMissionLoadBegin = onMissionLoadBegin,
        onSimulationStart = onSimulationStart,
        onSimulationStop = onSimulationStop,
        onSimulationPause = onSimulationPause,
        onSimulationResume = onSimulationResume,
        onSimulationFrame = onSimulationFrame,
    })

    setfenv(1, globalns)
    if not FlightAssistant then
        FlightAssistant = {}
    end
    FlightAssistant[assistantName] = { name = assistantName, id = assistantSelf.id }

    fmtInfo('[%s] FlightAssistant created', assistantName)
end

if type(flightAssistantConfig.flightAssistants) == 'table' then
    for name, cfg in pairs(flightAssistantConfig.flightAssistants) do
        if type(cfg) == 'table' then
            if type(cfg.requiredExtensions) == 'table' then
                fmtInfo('[%s] Loading required extensions', name)
                for _, ext in pairs(cfg.requiredExtensions) do
                    requireExtension(ext)
                end
            end
            setupAssistant(name, cfg)
        end
    end
end