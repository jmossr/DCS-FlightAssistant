local flightAssistant = ...
local fire = flightAssistant.fire
local getTrimmedTableId = flightAssistant.getTrimmedTableId
local fmtError = flightAssistant.fmtError
local fmtWarning = flightAssistant.fmtWarning
local fmtInfo = flightAssistant.fmtInfo
local isDebugEnabled = flightAssistant.isDebugEnabled
local NOOP = flightAssistant.NOOP
local printTable = flightAssistant.printTable
local tinsert = table.insert
local tostring = tostring
local pcall = pcall
local loadfile = loadfile
local type = type
local error = error
local pairs = pairs
local setmetatable = setmetatable
local unpack = unpack
local setfenv = setfenv

--[[------
 --Callback action
------]]--
local function fireCallback(action, ...)
    if not action.disabled then
        local ran, err = pcall(action.f, unpack(arg))
        if not ran then
            action.disabled = true
            local pUnit = action.pUnit
            fmtWarning('[%s][%s] %s generated an error and will be disabled. ERROR: %s', pUnit.faname, pUnit.name, tostring(action.name), err or '?')
        end
    end
end
local function getOrCreateCallbackAction(pUnit, name, f)
    local id = tostring(f)
    local callbackActions = pUnit.callbackActions
    local action = callbackActions[id]
    if not action then
        action = { pUnit = pUnit, name = name, f = f, fire = fireCallback }
        callbackActions[id] = action
    end
    return action
end
local function addSimCallbackAction(pUnit, simCallbackName, action)
    if not pUnit.simCallbacks then
        pUnit.simCallbacks = { [simCallbackName] = { action } }
    elseif not pUnit.simCallbacks[simCallbackName] then
        pUnit.simCallbacks[simCallbackName] = { action }
    else
        tinsert(pUnit.simCallbacks[simCallbackName], action)
    end
end
local function paddSimCallback(pUnit, simCallbackName, callbackf)
    if type(callbackf) ~= 'function' then
        error(simCallbackName .. " expects a callback function, not a " .. type(callbackf), 3)
    end
    addSimCallbackAction(pUnit, simCallbackName, getOrCreateCallbackAction(pUnit, simCallbackName .. ' callback ' .. tostring(callbackf), callbackf))
end
local function fireSimCallback(pUnit, simCallbackName)
    local simCallbacks = pUnit and pUnit.simCallbacks
    local callbacks = simCallbacks and simCallbacks[simCallbackName]
    if callbacks then
        fire(callbacks, simCallbackName)
    end
end

--[[------
    --PUnit management
--------]]
local function activatePUnit(pUnit)
    fireSimCallback(pUnit, 'onUnitActivated')
end
local function deactivatePUnit(pUnit)
    fireSimCallback(pUnit, 'onUnitDeactivating')
end

local function tryLoadPUnit(fa, name, initPUnitExtensions)
    local faname = fa.name
    local path = fa.flightAssistantDir .. name .. '.lua'
    local f, err = loadfile(path)
    if not f then
        if isDebugEnabled then
            fmtInfo('[%s] Failed to load %s: %s', faname, path, err or '?')
        end
        return nil
    else
        local pUnit = {
            faname = faname,
            name = name,
            callbackActions = {},
        }
        pUnit.id = getTrimmedTableId(pUnit)

        local proxy = {
            pUnit = name,
            logger = {
                error = function(msg)
                    fmtError('[%s][%s] %s', faname, name, msg)
                end,
                warning = function(msg)
                    fmtWarning('[%s][%s] %s', faname, name, msg)
                end,
                info = function(msg)
                    fmtInfo('[%s][%s] %s', faname, name, msg)
                end,
                debug = fa.debugUnit and function(msg)
                    fmtInfo('[%s][%s] %s', faname, name, msg)
                end or NOOP,
            },
            printTable = printTable,
            onUnitActivated = function(callbackf)
                paddSimCallback(pUnit, 'onUnitActivated', callbackf)
            end,
            onUnitDeactivating = function(callbackf)
                paddSimCallback(pUnit, 'onUnitDeactivating', callbackf)
            end,
            onSimulationPause = function(callbackf)
                paddSimCallback(pUnit, 'onSimulationPause', callbackf)
            end,
            onSimulationResume = function(callbackf)
                paddSimCallback(pUnit, 'onSimulationResume', callbackf)
            end,
            onSimulationFrame = function(callbackf)
                paddSimCallback(pUnit, 'onSimulationFrame', callbackf)
            end,

            isSimulationPaused = fa.isSimulationPaused,
            flightAssistantName = faname,
            unitConfig = fa.pUnitConfig,
        }
        pUnit.proxy = proxy
        proxy.include = function(libName, ...)
            fa.include(libName, proxy, unpack(arg))
        end
        if type(initPUnitExtensions) == 'table' then
            for _, initPUnit in pairs(initPUnitExtensions) do
                initPUnit(pUnit, proxy)
            end
        end

        setmetatable(proxy, { __index = _G })
        setfenv(f, proxy)
        pUnit.init = true
        local ran, merr = pcall(f, name, faname)
        pUnit.init = false
        if ran then
            if isDebugEnabled then
                fmtInfo('[%s] PUnit %s loaded', faname, name)
            end
            return pUnit
        else
            fmtWarning('[%s] Failed to load pUnit %s: %s', faname, name, merr or '?')
            return nil
        end
    end
end

return {
    activatePUnit = activatePUnit,
    deactivatePUnit = deactivatePUnit,
    tryLoadPUnit = tryLoadPUnit,
    fireSimCallback = fireSimCallback,
    getOrCreateCallbackAction = getOrCreateCallbackAction,
    addSimCallbackAction = addSimCallbackAction,
}