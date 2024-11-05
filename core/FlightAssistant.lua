--[[--------
	Flight Assistant
------------]]
local ENV_DCS_CONTROL_API = 'DCS Control API'
local ENV_LUA_EXPORT = 'LuaExport'
local type = type
local tostring = tostring
local pairs = pairs
local smatch = string.match
local sfind = string.find
local sformat = string.format
local sgsub = string.gsub
local tinsert = table.insert
local loadfile = loadfile
local pcall = pcall
local error = error
local flightAssistantConfig = ...
local config = (flightAssistantConfig and type(flightAssistantConfig) == 'table') and flightAssistantConfig or nil
local isReloadUserScriptsOnMissionLoad = not config or config.reloadUserScriptsOnMissionLoad
local logSubsystemName = config and config.logSubsystemName and tostring(config.logSubsystemName) or 'FLIGHTASSISTANT'
local enableDCSEnvs = config and config.enableDCSEnvs or ENV_DCS_CONTROL_API
local lwrite = log.write
local lINFO = log.INFO
local lWARNING = log.WARNING
local LoGetSelfData = LoGetSelfData or Export and Export.LoGetSelfData or nil
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
local dcsEnv
local faCallbacks = {}
local simulationActive = false
local simulationPaused = true
local currentPUnitData
do
    local executeCallbacks = function(cb)
        for _, cbs in pairs(faCallbacks) do
            cbs[cb]()
        end
    end
    local callbacks = {
        onMissionLoadBegin = function()
            simulationPaused = true
            simulationActive = false
            if isReloadUserScriptsOnMissionLoad then
                FlightAssistant = nil
                clearTable(faCallbacks)
                if DCS then
                    lwrite(logSubsystemName, lINFO, 'Reloading user scripts...')
                    DCS.reloadUserScripts()
                end
            end
            executeCallbacks('onMissionLoadBegin');
        end,
        onSimulationStart = function()
            simulationPaused = true
            simulationActive = true
            currentPUnitData = LoGetSelfData()
            executeCallbacks('onSimulationStart');
        end,
        onSimulationStop = function()
            simulationActive = false
            currentPUnitData = nil
            executeCallbacks('onSimulationStop');
        end,
        onSimulationFrame = function()
            if simulationActive then
                currentPUnitData = LoGetSelfData()
            end
            executeCallbacks('onSimulationFrame');
        end,
        onSimulationPause = function()
            simulationPaused = true
            executeCallbacks('onSimulationPause');
        end,
        onSimulationResume = function()
            simulationPaused = false
            if simulationActive then
                currentPUnitData = LoGetSelfData()
            end
            executeCallbacks('onSimulationResume');
        end
    }
    if DCS then
        dcsEnv = ENV_DCS_CONTROL_API
        lwrite(logSubsystemName, lINFO, 'Installing DCS Control API User callbacks')
        DCS.setUserCallbacks(callbacks)
    else
        dcsEnv = ENV_LUA_EXPORT
        isReloadUserScriptsOnMissionLoad = false
        logSubsystemName = logSubsystemName .. '(E)'
        lwrite(logSubsystemName, lWARNING, 'Cannot install DCS Control API callbacks: function DCS.setUserCallbacks not found')
        if LoGetModelTime then
            lwrite(logSubsystemName, lINFO, 'Installing LuaExport callbacks')
            if LuaExportStart then
                local nextLuaExportStart = LuaExportStart
                LuaExportStart = function()
                    callbacks.onMissionLoadBegin()
                    callbacks.onSimulationStart()
                    nextLuaExportStart()
                end
            else
                LuaExportStart = function()
                    callbacks.onMissionLoadBegin()
                    callbacks.onSimulationStart()
                end
            end
            if LuaExportStop then
                local nextLuaExportStop = LuaExportStop
                LuaExportStop = function()
                    callbacks.onSimulationStop()
                    nextLuaExportStop()
                end
            else
                LuaExportStop = callbacks.onSimulationStop
            end
            if LuaExportAfterNextFrame then
                local nextLuaExportAfterNextFrame = LuaExportAfterNextFrame
                LuaExportAfterNextFrame = function()
                    callbacks.onSimulationFrame()
                    nextLuaExportAfterNextFrame()
                end
            else
                LuaExportAfterNextFrame = callbacks.onSimulationFrame
            end
        end
    end
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

if isDebugEnabled then
    lwrite(logSubsystemName, lINFO, sformat('flightAssistantScriptFile = %s', flightAssistantConfig.flightAssistantScriptFile))
    lwrite(logSubsystemName, lINFO, sformat('flightAssistantScriptDir = %s', flightAssistantScriptDir))
    lwrite(logSubsystemName, lINFO, sformat('extensionsDir = %s', extensionsDir))
    lwrite(logSubsystemName, lINFO, sformat('enableDCSEnvs = %s', enableDCSEnvs))
end

--[[------
    -- loadLua
------]]--
local function loadLua(path, env, ...)
    if isDebugEnabled then
        lwrite(logSubsystemName, lINFO, sformat('Loading file %s', path))
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

--[[------
    --Core
--------]]
local flightAssistantCore = {}
flightAssistantConfig.isDebugEnabled = isDebugEnabled
flightAssistantConfig.isDebugUnitEnabled = isDebugUnitEnabled
flightAssistantCore.config = flightAssistantConfig
flightAssistantCore.extensionsDir = extensionsDir
flightAssistantCore.loadLua = loadLua
flightAssistantCore.simulation = {
    isPaused = function()
        return simulationPaused
    end
}
flightAssistantCore.logger = loadLua(flightAssistantScriptDir .. 'logger.lua').createLogger(logSubsystemName)
flightAssistantCore.tools = loadLua(flightAssistantScriptDir .. 'tools.lua')
flightAssistantCore.tools.clearTable = clearTable
flightAssistantCore.debugtools = loadLua(flightAssistantScriptDir .. 'debugtools.lua')
flightAssistantCore.actions = loadLua(flightAssistantScriptDir .. 'actions.lua', nil, flightAssistantCore)

local extensionsLib = loadLua(flightAssistantScriptDir .. 'extensions.lua', nil, flightAssistantCore)
local beforePUnitActivation = extensionsLib.beforePUnitActivation
local afterPUnitAactivation = extensionsLib.afterPUnitActivation
local beforePUnitDeactivation = extensionsLib.beforePUnitDeactivation
local afterPUnitDeactivation = extensionsLib.afterPUnitDeactivation
local beforeSimulationFrame = extensionsLib.beforeSimulationFrame
local afterSimulationFrame = extensionsLib.afterSimulationFrame
local requireExtension = extensionsLib.requireExtension
flightAssistantCore.extensions = {}
flightAssistantCore.extensions.getOptionalExtension = extensionsLib.getOptionalExtension
flightAssistantCore.extensions.requireExtension = requireExtension

local pUnitLib = loadLua(flightAssistantScriptDir .. 'pUnit.lua', nil, flightAssistantCore)
local tryLoadPUnit = pUnitLib.tryLoadPUnit
local activatePUnit = pUnitLib.activatePUnit
local deactivatePUnit = pUnitLib.deactivatePUnit
local fireSimCallback = pUnitLib.fireSimCallback
flightAssistantCore.pUnit = {}
flightAssistantCore.pUnit.getOrCreateCallbackAction = pUnitLib.getOrCreateCallbackAction
flightAssistantCore.pUnit.addSimCallbackAction = pUnitLib.addSimCallbackAction

setmetatable(flightAssistantCore, { __index = _G })

--[[------
    --Load extensions
--------]]
if type(flightAssistantConfig.extensions) == 'table' then
    for _, ext in pairs(flightAssistantConfig.extensions) do
        requireExtension(ext)
    end
end

local globalns = _G

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
        id = flightAssistantCore.tools.getTrimmedTableId(faCallbacks) .. ':' .. assistantCounter(),
        --playerUnitScriptsDir is for testing purposes
        assistantDir = flightAssistantConfig.playerUnitScriptsDir or (flightAssistantScriptDir .. sgsub(assistantName, '%s+', '_') .. '\\'),
        pUnitFallbackTable = configTable.pUnitFallbackTable or {},
        pUnits = {},
        isSimulationPaused = flightAssistantCore.simulation.isPaused,
        reloadOnMissionLoad = configTable.reloadOnMissionLoad,
        debugUnit = isDebugEnabled or isDebugUnitEnabled or configTable.debugUnit and true or false,
        pUnitConfig = configTable.unitConfig or {}
    }

    extensionsLib.initAssistant(assistantSelf, configTable)

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
            beforePUnitDeactivation(activePUnit)
            deactivatePUnit(activePUnit)
            afterPUnitDeactivation(activePUnit)
            activePUnit.proxy.selfData = nil
            lwrite(logSubsystemName, lINFO, sformat('[%s] PUnit %s deactivated', assistantName, activePUnit.name))
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
                    lwrite(logSubsystemName, lINFO, sformat('[%s] Searching for %s.lua', assistantName, alias))
                end
                pUnitTable = tryLoadPUnit(assistantSelf, alias, extensionsLib.initPUnit)
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
                    beforePUnitActivation(activePUnit)
                    activatePUnit(activePUnit)
                    afterPUnitAactivation(activePUnit)
                    lwrite(logSubsystemName, lINFO, sformat('[%s] PUnit %s activated', assistantName, activePUnit.name))
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
            lwrite(logSubsystemName, lINFO, sformat('[%s] Reloading pUnits', assistantName))
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
                beforeSimulationFrame(activePUnit)
                fireSimCallback(activePUnit, 'onSimulationFrame')
                afterSimulationFrame(activePUnit)
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

    lwrite(logSubsystemName, lINFO, sformat('[%s] FlightAssistant created', assistantName))
end

if type(flightAssistantConfig.flightAssistants) == 'table' and sfind(enableDCSEnvs, dcsEnv) then
    for name, cfg in pairs(flightAssistantConfig.flightAssistants) do
        if type(cfg) == 'table' then
            if sfind(cfg.dcsEnvs or ENV_DCS_CONTROL_API, dcsEnv) then
                if type(cfg.requiredExtensions) == 'table' then
                    lwrite(logSubsystemName, lINFO, sformat('[%s] Loading required extensions', name))
                    for _, ext in pairs(cfg.requiredExtensions) do
                        requireExtension(ext)
                    end
                end
                setupAssistant(name, cfg)
            end
        end
    end
end