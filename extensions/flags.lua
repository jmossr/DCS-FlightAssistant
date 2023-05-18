--[[------
    --FlightAssistant
    --Flags
--------]]
local tinsert = table.insert
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local flightAssistant = ...
local isDebugUnitEnabled = flightAssistant.isDebugUnitEnabled
local getOptionalExtension = flightAssistant.getOptionalExtension
local requireExtension = flightAssistant.requireExtension
local getOrCreateCallbackAction = flightAssistant.getOrCreateCallbackAction
local fire = flightAssistant.fire
local checkArgType = flightAssistant.checkArgType
local checkStringOrNumberArg = flightAssistant.checkStringOrNumberArg
local addOnValueChangedAction = flightAssistant.addOnValueChangedAction
local addOnValueBetweenAction = flightAssistant.addOnValueBetweenAction
local addOnValueAction = flightAssistant.addOnValueAction

local dcsLib = requireExtension('DCS-calls')
local getUserFlag = dcsLib.getUserFlag
local setUserFlag = dcsLib.setUserFlag
local startListenCommand = dcsLib.startListenCommand

local function activateFlagInspector(inspector)
    if inspector.disabled then
        inspector.disabled = nil
        inspector.lastValue = getUserFlag(inspector.flag)
    end
end
local function activateInitialFlagInspectors(pUnit)
    local inspectors = pUnit.flagInspectors
    local n = #inspectors
    local inspector
    for i = 1, n do
        inspector = inspectors[i]
        if inspector.initial then
            activateFlagInspector(inspector)
        end
    end
end
local function deactivateFlagInspectors(pUnit)
    local inspectors = pUnit.flagInspectors
    local n = #inspectors
    for i = 1, n do
        inspectors[i].disabled = true
    end
end
local function checkFlags(pUnit)
    local inspectors = pUnit.flagInspectors
    local n = #inspectors
    local inspector
    local oldValue
    for i = 1, n do
        inspector = inspectors[i]
        if not inspector.disabled then
            local flag = inspector.flag
            local newValue = getUserFlag(flag)
            if newValue ~= inspector.lastValue then
                oldValue = inspector.lastValue
                inspector.lastValue = newValue
                fire(inspector.observers, newValue, oldValue, flag)
            end
        end
    end
end

local function getOrCreateFlagInspector(pUnit, flag)
    local flagName = tostring(flag)
    local inspectors = pUnit.flagInspectors
    local n = #inspectors
    local inspector
    for i = 1, n do
        inspector = inspectors[i]
        if inspector.flag == flagName then
            activateFlagInspector(inspector)
            return inspector
        end
    end
    inspector = { pUnit = pUnit, name = 'flagInspector \'' .. flag .. '\'', flag = flagName, lastValue = getUserFlag(flag), observers = {}, initial = pUnit.init }
    tinsert(inspectors, inspector)
    return inspector
end

local function flagInspectorAccessor(pUnit, flag)
    return function()
        return getOrCreateFlagInspector(pUnit, flag)
    end
end

local function activateOnCommandTrigger(pUnit, trigger)
    if trigger.disabled then
        trigger.disabled = nil
        getOrCreateFlagInspector(pUnit, trigger.flag) --activate flag inspector
        startListenCommand(trigger.deviceId, trigger.commandId, trigger.flag, trigger.minValue, trigger.maxValue)
    end
end
local function fireOnCommandAction(self, newValue)
    if not self.disabled and tonumber(newValue) ~= 0 then
        setUserFlag(self.flag, 0)
        startListenCommand(self.deviceId, self.commandId, self.flag, self.minValue, self.maxValue)
        fire(self.observers)
    end
end
local onCommandTriggerCount = 0
local function getOrCreateOnCommandTrigger(pUnit, deviceId, commandId, minValue, maxValue)
    local min = tonumber(minValue) or 1
    local max = tonumber(maxValue) or 10000
    local id = 'onCommand(' .. deviceId .. ', ' .. commandId .. ', ' .. min .. ', ' .. max .. ')'
    local commandTriggers = pUnit.commandTriggers
    local trigger = commandTriggers[id]
    if trigger then
        activateOnCommandTrigger(pUnit, trigger)
    else
        onCommandTriggerCount = onCommandTriggerCount + 1
        local flag = 'OCF1429-' .. onCommandTriggerCount
        trigger = { pUnit = pUnit, name = id, flag = flag,
                    deviceId = deviceId, commandId = commandId, minValue = min, maxValue = max,
                    fire = fireOnCommandAction, observers = {}, initial = pUnit.init }
        commandTriggers[id] = trigger
        tinsert(getOrCreateFlagInspector(pUnit, flag).observers, trigger)
        startListenCommand(deviceId, commandId, flag, min, max, 1)
    end
    return trigger
end
local function onCommandTriggerAccessor(pUnit, deviceId, commandId, minValue, maxValue)
    return function()
        return getOrCreateOnCommandTrigger(pUnit, deviceId, commandId, minValue, maxValue)
    end
end
local function activateInitialOnCommandTriggers(pUnit)
    for _, trigger in pairs(pUnit.commandTriggers) do
        if trigger.initial then
            activateOnCommandTrigger(pUnit, trigger)
        end
    end
end
local function deactivateOnCommandTriggers(pUnit)
    for _, trigger in pairs(pUnit.commandTriggers) do
        trigger.disabled = true
    end
end
local function onFlagValue(pUnit, flag, value, f)
    return addOnValueAction(flagInspectorAccessor(pUnit, flag), getOrCreateCallbackAction(pUnit, 'callback ' .. tostring(f), f), value)
end
local ponFlagValue
if isDebugUnitEnabled then
    ponFlagValue = function(pUnit, flag, value, f)
        checkStringOrNumberArg('onFlagValue(flag, value, f)', 'flag', flag, true, 3)
        checkStringOrNumberArg('onFlagValue(flag, value, f)', 'value', value, true, 3)
        checkArgType('onFlagValue(flag, value, f)', 'f', f, 'function', true, 3)
        return onFlagValue(pUnit, flag, value, f)
    end
end

local function onFlagValueChanged(pUnit, flag, f)
    return addOnValueChangedAction(flagInspectorAccessor(pUnit, flag), getOrCreateCallbackAction(pUnit, 'callback ' .. tostring(f), f))
end
local ponFlagValueChanged
if isDebugUnitEnabled then
    ponFlagValueChanged = function(pUnit, flag, f)
        checkStringOrNumberArg('onFlagValueChanged(flag, f)', 'flag', flag, true, 3)
        checkArgType('onFlagValueChanged(flag, f)', 'f', f, 'function', true, 3)
        return onFlagValueChanged(pUnit, flag, f)
    end
end

local function onFlagValueBetween(pUnit, flag, minValue, maxValue, f)
    return addOnValueBetweenAction(flagInspectorAccessor(pUnit, flag), getOrCreateCallbackAction(pUnit, 'callback ' .. tostring(f), f), minValue, maxValue)
end
local ponFlagValueBetween
if isDebugUnitEnabled then
    ponFlagValueBetween = function(pUnit, flag, minValue, maxValue, f)
        checkStringOrNumberArg('onFlagValueBetween(flag, minValue, maxValue, f)', 'flag', flag, true, 3)
        checkArgType('onFlagValueBetween(flag, minValue, maxValue, f)', 'minValue', minValue, 'number', true, 3)
        checkArgType('onFlagValueBetween(flag, minValue, maxValue, f)', 'maxValue', maxValue, 'number', true, 3)
        checkArgType('onFlagValueBetween(flag, minValue, maxValue, f)', 'f', f, 'function', true, 3)
        onFlagValueBetween(pUnit, flag, minValue, maxValue, f)
    end
end
local builderLib = getOptionalExtension('builder')
local onCommand
local onFlag
if builderLib then
    local createValueInspectionBuilder = builderLib.createValueInspectionBuilder
    local createOnEventActionBuilder = builderLib.createOnEventActionBuilder
    do
        if isDebugUnitEnabled then
            onFlag = function(pUnit, flag)
                checkStringOrNumberArg('onFlag(flag)', 'flag', flag, true, 3)
                return createValueInspectionBuilder(pUnit, 'onFlag(' .. flag .. ')', flagInspectorAccessor(pUnit, flag)).proxy
            end
            onCommand = function(pUnit, deviceId, commandId, minValue, maxValue, f)
                checkArgType('onCommand(device, command, minValue, maxValue [, f])', 'device', deviceId, 'number', true, 3)
                checkArgType('onCommand(device, command, minValue, maxValue [, f])', 'command', commandId, 'number', true, 3)
                checkArgType('onCommand(device, command, minValue, maxValue [, f])', 'minValue', maxValue, 'number', false, 3)
                checkArgType('onCommand(device, command, minValue, maxValue [, f])', 'maxValue', maxValue, 'number', false, 3)
                checkArgType('onCommand(device, command, minValue, maxValue [, f])', 'f', f, 'function', false, 3)
                if f then
                    tinsert(getOrCreateOnCommandTrigger(pUnit, deviceId, commandId, minValue, maxValue).observers, getOrCreateCallbackAction(pUnit, 'callback ' .. tostring(f), f))
                else
                    return createOnEventActionBuilder(pUnit, 'onCommand(' .. deviceId .. ', ' .. commandId .. ')', onCommandTriggerAccessor(pUnit, deviceId, commandId, minValue, maxValue)).proxy
                end
            end
        else
            onFlag = function(pUnit, flag)
                return createValueInspectionBuilder(pUnit, 'onFlag(' .. flag .. ')', flagInspectorAccessor(pUnit, flag)).proxy
            end
            onCommand = function(pUnit, deviceId, commandId, minValue, maxValue, f)
                if f then
                    tinsert(getOrCreateOnCommandTrigger(pUnit, deviceId, commandId, minValue, maxValue).observers, getOrCreateCallbackAction(pUnit, 'callback ' .. tostring(f), f))
                else
                    return createOnEventActionBuilder(pUnit, 'onCommand(' .. deviceId .. ', ' .. commandId .. ')', onCommandTriggerAccessor(pUnit, deviceId, commandId, minValue, maxValue)).proxy
                end
            end
        end
    end
elseif isDebugUnitEnabled then
    onCommand = function(pUnit, deviceId, commandId, f, minValue, maxValue)
        checkArgType('onCommand(device, command, minValue, maxValue, f)', 'device', deviceId, 'number', true, 3)
        checkArgType('onCommand(device, command, minValue, maxValue, f)', 'command', commandId, 'number', true, 3)
        checkArgType('onCommand(device, command, minValue, maxValue, f)', 'minValue', minValue, 'number', false, 3)
        checkArgType('onCommand(device, command, minValue, maxValue, f)', 'maxValue', maxValue, 'number', false, 3)
        checkArgType('onCommand(device, command, minValue, maxValue, f)', 'f', f, 'function', true, 3)
        tinsert(getOrCreateOnCommandTrigger(pUnit, deviceId, commandId, minValue, maxValue).observers, getOrCreateCallbackAction(pUnit, 'callback ' .. tostring(f), f))
    end
else
    onCommand = function(pUnit, deviceId, commandId, minValue, maxValue, f)
        tinsert(getOrCreateOnCommandTrigger(pUnit, deviceId, commandId, minValue, maxValue).observers, getOrCreateCallbackAction(pUnit, 'callback ' .. tostring(f), f))
    end
end

local uonFlagValueChanged = ponFlagValueChanged or onFlagValueChanged
local uonFlagValue = ponFlagValue or onFlagValue
local uonFlagValueBetween = ponFlagValueBetween or onFlagValueBetween

local function initPUnit(pUnit, proxy)
    if not pUnit.flagInspectors then
        pUnit.flagInspectors = {}
        pUnit.commandTriggers = {}

        proxy.onFlagValueChanged = function(flag, f)
            return uonFlagValueChanged(pUnit, flag, f)
        end
        proxy.onFlagValue = function(flag, value, f)
            return uonFlagValue(pUnit, flag, value, f)
        end
        proxy.onFlagValueBetween = function(flag, minValue, maxValue, f)
            return uonFlagValueBetween(pUnit, flag, minValue, maxValue, f)
        end
        proxy.onFlag = onFlag and function(flag)
            return onFlag(pUnit, flag)
        end
        proxy.onCommand = function(deviceId, commandId, arg3, arg4, arg5)
            return onCommand(pUnit, deviceId, commandId, arg3, arg4, arg5)
        end
    end
end

local function beforeUnitActivation(pUnit)
    activateInitialFlagInspectors(pUnit)
    activateInitialOnCommandTriggers(pUnit)
end
local function afterUnitDeactivation(pUnit)
    deactivateFlagInspectors(pUnit)
    deactivateOnCommandTriggers(pUnit)
end
return {
    initPUnit = initPUnit,
    beforePUnitActivation = beforeUnitActivation,
    afterPUnitDeactivation = afterUnitDeactivation,
    beforeSimulationFrame = checkFlags,
}
