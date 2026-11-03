--[[--------
	Flight Assistant
------------]]
local ENV_DCS_CONTROL_API = 'DCS Control API'
local type = type
local tostring = tostring
local pairs = pairs
local smatch = string.match
local sfind = string.find
local sformat = string.format
local sgsub = string.gsub
local pcall = pcall
local error = error
local setmetatable = setmetatable
local flightAssistantConfig, dcsPlug = ...
local config = (flightAssistantConfig and type(flightAssistantConfig) == 'table') and flightAssistantConfig or nil
local clearTable = (dcsPlug and type(dcsPlug) == 'table') and dcsPlug.clearTable or nil
local loadLua = (dcsPlug and type(dcsPlug) == 'table') and dcsPlug.loadLua or nil
local simulation = (dcsPlug and type(dcsPlug) == 'table') and dcsPlug.simulation or nil
local logSubsystemName = config and config.logSubsystemName and tostring(config.logSubsystemName) or 'FLIGHTASSISTANT'
local enableDCSEnvs = config and config.enableDCSEnvs or ENV_DCS_CONTROL_API
local lwrite = log.write
local lINFO = log.INFO
local LoIsOwnshipExportAllowed = LoIsOwnshipExportAllowed or Export and Export.LoIsOwnshipExportAllowed or nil
local LoGetNetIsRunning = LoGetNetIsRunning or Export and Export.LoGetNetIsRunning or nil
local LoGetPlayerSeat = LoGetPlayerSeat or Export and Export.LoGetPlayerSeat or nil
local setfenv = setfenv
local unpack = unpack

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
if not clearTable then
    error('FlightAssistant received no or an invalid DCSPlug: function clearTable not found')
elseif not loadLua then
    error('FlightAssistant received no or an invalid DCSPlug: function loadLua not found')
elseif not simulation then
    error('FlightAssistant received no or an invalid DCSPlug: table simulation not found')
end

local flightAssistantScriptDir = smatch(flightAssistantConfig.flightAssistantScriptFile, '(.*[\\/])[^\\/]+$')
local extensionsDir = flightAssistantConfig.extensionsDir or (flightAssistantScriptDir .. 'extensions')
local isDebugEnabled = flightAssistantConfig.debug and true or false
local isDebugUnitEnabled = flightAssistantConfig.debugUnit and true or isDebugEnabled

if isDebugEnabled then
    lwrite(logSubsystemName, lINFO, sformat('flightAssistantScriptFile = %s', flightAssistantConfig.flightAssistantScriptFile))
    lwrite(logSubsystemName, lINFO, sformat('flightAssistantScriptDir = %s', flightAssistantScriptDir))
    lwrite(logSubsystemName, lINFO, sformat('extensionsDir = %s', extensionsDir))
    lwrite(logSubsystemName, lINFO, sformat('enableDCSEnvs = %s', tostring(enableDCSEnvs)))
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
        return simulation.simulationPaused
    end
}
flightAssistantCore.logger = loadLua(flightAssistantScriptDir .. 'logger.lua').createLogger(logSubsystemName)
flightAssistantCore.tools = loadLua(flightAssistantScriptDir .. 'tools.lua')
flightAssistantCore.tools.clearTable = clearTable
flightAssistantCore.debugtools = loadLua(flightAssistantScriptDir .. 'debugtools.lua')
flightAssistantCore.actions = loadLua(flightAssistantScriptDir .. 'actions.lua', nil, flightAssistantCore)

local extensionsLib = loadLua(flightAssistantScriptDir .. 'extensions.lua', nil, flightAssistantCore)
local beforePUnitActivation = extensionsLib.beforePUnitActivation
local afterPUnitActivation = extensionsLib.afterPUnitActivation
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
        id = flightAssistantCore.tools.getTrimmedTableId(dcsPlug) .. ':' .. assistantCounter(),
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
        local currentPUnitName = simulation.currentPUnitData and simulation.currentPUnitData['Name']
        if currentPUnitName ~= activePUnitName then
            deactivateActivePUnit()
            activePUnitName = currentPUnitName
            if activePUnitName then
                activePUnit = findPUnitTable(activePUnitName)
                if activePUnit then
                    activePUnit.proxy.selfData = simulation.currentPUnitData
                    beforePUnitActivation(activePUnit)
                    activatePUnit(activePUnit)
                    afterPUnitActivation(activePUnit)
                    lwrite(logSubsystemName, lINFO, sformat('[%s] PUnit %s activated', assistantName, activePUnit.name))
                    if isDebugEnabled then
                        local okNet, netRunning = pcall(LoGetNetIsRunning)
                        local okSeat, seat = pcall(LoGetPlayerSeat)
                        lwrite(logSubsystemName, lINFO, sformat('[%s] multiplayer=%s seat=%s ownshipExport=%s', assistantName,
                            tostring(okNet and netRunning), tostring(okSeat and seat), tostring(LoIsOwnshipExportAllowed())))
                    end
                end
            end
        elseif activePUnit then
            activePUnit.proxy.selfData = simulation.currentPUnitData
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
        if simulation.simulationActive then
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
    simulation.registerCallbacks(assistantName, {
        beforeReloadUserScripts = function() globalns.FlightAssistant = nil  end,
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

if type(flightAssistantConfig.flightAssistants) == 'table' and sfind(enableDCSEnvs, dcsPlug.dcsEnv) then
    for name, cfg in pairs(flightAssistantConfig.flightAssistants) do
        if type(cfg) == 'table' then
            if dcsPlug.checkDCSEnv(cfg.dcsEnvs or ENV_DCS_CONTROL_API) then
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