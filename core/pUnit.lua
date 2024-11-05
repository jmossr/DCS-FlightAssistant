local flightAssistantCore = ...
local fire = flightAssistantCore.actions.fire
local getTrimmedTableId = flightAssistantCore.tools.getTrimmedTableId
local fmtError = flightAssistantCore.logger.fmtError
local fmtWarning = flightAssistantCore.logger.fmtWarning
local fmtInfo = flightAssistantCore.logger.fmtInfo
local isDebugEnabled = flightAssistantCore.config.isDebugEnabled
local NOOP = flightAssistantCore.tools.NOOP
local printTable = flightAssistantCore.logger.printTable
local tinsert = table.insert
local tostring = tostring
local pcall = pcall
local loadfile = loadfile
local type = type
local error = error
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
            fmtWarning('[%s][%s] %s generated an error and will be disabled. ERROR: %s', pUnit.assistantName, pUnit.name, tostring(action.name), err or '?')
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

local function tryLoadPUnit(assistant, name, initPUnit)
    local assistantName = assistant.name
    local path = assistant.assistantDir .. name .. '.lua'
    local f, err = loadfile(path)
    if not f then
        if isDebugEnabled then
            fmtInfo('[%s] Failed to load %s: %s', assistantName, path, err or '?')
        end
        return nil
    else
        local pUnit = {
            assistantName = assistantName,
            name = name,
            callbackActions = {},
        }
        pUnit.id = getTrimmedTableId(pUnit)

        local proxy = {
            pUnit = name,
            logger = {
                error = function(msg, ...)
                    fmtError('[%s][%s] ' .. msg, assistantName, name, unpack(arg))
                end,
                warning = function(msg, ...)
                    fmtWarning('[%s][%s] ' .. msg, assistantName, name, unpack(arg))
                end,
                info = function(msg, ...)
                    fmtInfo('[%s][%s] ' .. msg, assistantName, name, unpack(arg))
                end,
                debug = assistant.debugUnit and function(msg, ...)
                    fmtInfo('[%s][%s] ' .. msg, assistantName, name, unpack(arg))
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

            isSimulationPaused = assistant.isSimulationPaused,
            flightAssistantName = assistantName,
            unitConfig = assistant.pUnitConfig,
        }
        pUnit.proxy = proxy
        proxy.include = function(libName, ...)
            assistant.include(libName, proxy, unpack(arg))
        end
        if initPUnit then
            initPUnit(pUnit, proxy)
        end

        setmetatable(proxy, { __index = _G })
        setfenv(f, proxy)
        pUnit.init = true
        local ran, merr = pcall(f, name, assistantName)
        pUnit.init = false
        if ran then
            if isDebugEnabled then
                fmtInfo('[%s] PUnit %s loaded', assistantName, name)
            end
            return pUnit
        else
            fmtWarning('[%s] Failed to load pUnit %s: %s', assistantName, name, merr or '?')
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