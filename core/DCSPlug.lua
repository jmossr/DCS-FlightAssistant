--[[--------
	DCSPlug: hooks into DCS by installing callbacks
------------]]
local ENV_DCS_CONTROL_API = 'DCS Control API'
local ENV_LUA_EXPORT = 'LuaExport'
local type = type
local tostring = tostring
local pairs = pairs
local sformat = string.format
local sfind = string.find
local tinsert = table.insert
local loadfile = loadfile
local pcall = pcall
local error = error
local cfg = ...
local config = (cfg and type(cfg) == 'table') and cfg or nil
local isReloadUserScriptsOnMissionLoad = not config or config.reloadUserScriptsOnMissionLoad
local logSubsystemName = config and config.logSubsystemName and tostring(config.logSubsystemName) or 'DCSPLUG'
local isDebugEnabled = (not config or config.debug) and true or false
local lwrite = log.write
local lINFO = log.INFO
local lWARNING = log.WARNING
local LoGetSelfData = LoGetSelfData or Export and Export.LoGetSelfData or nil
local setfenv = setfenv
local unpack = unpack
local DCSgetPause = DCS and DCS.getPause or nil

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
local CB_BEFORE_RELOAD_USER_SCRIPTS = 'beforeReloadUserScripts'
local CB_ON_MISSION_LOAD_BEGIN = 'onMissionLoadBegin'
local CB_ON_SIMULATION_START = 'onSimulationStart'
local CB_ON_SIMULATION_STOP = 'onSimulationStop'
local CB_ON_SIMULATION_FRAME = 'onSimulationFrame'
local CB_ON_SIMULATION_PAUSE = 'onSimulationPause'
local CB_ON_SIMULATION_RESUME = 'onSimulationResume'
local callbackNames = {
    CB_BEFORE_RELOAD_USER_SCRIPTS = CB_BEFORE_RELOAD_USER_SCRIPTS,
    CB_ON_MISSION_LOAD_BEGIN = CB_ON_MISSION_LOAD_BEGIN,
    CB_ON_SIMULATION_START = CB_ON_SIMULATION_START,
    CB_ON_SIMULATION_STOP = CB_ON_SIMULATION_STOP,
    CB_ON_SIMULATION_FRAME = CB_ON_SIMULATION_FRAME,
    CB_ON_SIMULATION_PAUSE = CB_ON_SIMULATION_PAUSE,
    CB_ON_SIMULATION_RESUME = CB_ON_SIMULATION_RESUME
}
local dcsEnv
local callbackRegistry = {}
local simulation = {}
simulation.simulationActive = false
simulation.simulationPaused = true
simulation.currentPUnitData = nil
do
    local executeCallbacks = function(cb)
        if callbackRegistry[cb] then
            for key, cbf in pairs(callbackRegistry[cb]) do
                local ok, r = pcall(cbf.f);
                if not ok then
                    log.write(logSubsystemName, log.WARNING, sformat('Callback %s.%s generated an error and will be disabled. ERROR: %s', cbf.ownerName, cb, r or '?'))
                    callbackRegistry[cb][key] = nil
                end
            end
        end
    end
    local onSimulationPause = function()
        simulation.simulationPaused = true
        executeCallbacks(CB_ON_SIMULATION_PAUSE);
    end
    local onSimulationResume = function()
        simulation.simulationPaused = false
        if simulation.simulationActive then
            simulation.currentPUnitData = LoGetSelfData()
        end
        executeCallbacks(CB_ON_SIMULATION_RESUME);
    end
    local callbacks = {
        onMissionLoadBegin = function()
            simulation.simulationPaused = true
            simulation.simulationActive = false
            if isReloadUserScriptsOnMissionLoad then
                executeCallbacks(CB_BEFORE_RELOAD_USER_SCRIPTS);
                clearTable(callbackRegistry)
                if DCS then
                    lwrite(logSubsystemName, lINFO, 'Reloading user scripts...')
                    DCS.reloadUserScripts()
                end
            end
            executeCallbacks(CB_ON_MISSION_LOAD_BEGIN);
        end,
        onSimulationStart = function()
            simulation.simulationPaused = true
            simulation.simulationActive = true
            simulation.currentPUnitData = LoGetSelfData()
            executeCallbacks(CB_ON_SIMULATION_START);
        end,
        onSimulationStop = function()
            simulation.simulationActive = false
            simulation.currentPUnitData = nil
            executeCallbacks(CB_ON_SIMULATION_STOP);
        end,
        onSimulationFrame = function()
            -- A multiplayer client never receives onSimulationResume after joining, so the
            -- pause state set by onSimulationStart would stick. Read the real state instead.
            if DCSgetPause then
                local paused = DCSgetPause() and true or false
                if paused ~= simulation.simulationPaused then
                    if paused then
                        onSimulationPause()
                    else
                        onSimulationResume()
                    end
                end
            end
            if simulation.simulationActive then
                simulation.currentPUnitData = LoGetSelfData()
            end
            executeCallbacks(CB_ON_SIMULATION_FRAME);
        end,
        onSimulationPause = onSimulationPause,
        onSimulationResume = onSimulationResume
    }
    if DCS then
        dcsEnv = ENV_DCS_CONTROL_API
        lwrite(logSubsystemName, lINFO, 'Installing DCS Control API User callbacks')
        DCS.setUserCallbacks(callbacks)
    else
        dcsEnv = ENV_LUA_EXPORT
        isReloadUserScriptsOnMissionLoad = false
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
    -- registerCallbacks
------]]--
local function registerCallbacks(ownerName, cbs)
    if type(cbs) == 'table' then
        for _, n in pairs(callbackNames) do
            if cbs[n] then
                if not callbackRegistry[n] then
                    callbackRegistry[n] = {}
                end
                tinsert(callbackRegistry[n], {ownerName = ownerName, f = cbs[n]})
            end
        end
    else
        error('registerCallbacks(ownerName, callbacks) \'callbacks\' must be a table, not a ' .. type(cbs), 2)
    end
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
    -- checkDCSEnv: checks if the current dcsEnv is in the given list of supported envs.
------]]--
local function checkDCSEnv(supportedEnvs)
    return supportedEnvs and sfind(supportedEnvs, dcsEnv) or false
end

simulation.registerCallbacks = registerCallbacks
simulation.callbackNames = callbackNames

return {
    simulation = simulation,
    loadLua = loadLua,
    clearTable = clearTable,
    dcsEnv = dcsEnv,
    isDebugEnabled = isDebugEnabled,
    checkDCSEnv = checkDCSEnv
}