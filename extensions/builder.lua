--[=[------
    --FlightAssistant
    --Builder

    Allows extensions to combine event sources and actions without knowing about the other extensions.
    Example using extensions 'builder', 'DCS-calls' and 'scheduler'
    -- [F/A-18 device 0, arg 47] = 'A/A indicator light': when ON, schedule to set user flag "AAIsOn" after 0.5 seconds
    onDeviceArgument(0, 47).value(1).schedule(0.5).setUserFlag("AAIsOn")

--------]=]

local tostring = tostring
local tinsert = table.insert
local tremove = table.remove
local type = type
local flightAssistant = ...
local fmtInfo = flightAssistant.fmtInfo
local isDebugEnabled = flightAssistant.isDebugEnabled
local isDebugUnitEnabled = flightAssistant.isDebugUnitEnabled
local clearTable = flightAssistant.clearTable
local addSimCallbackAction = flightAssistant.addSimCallbackAction
local getOrCreateCallbackAction = flightAssistant.getOrCreateCallbackAction
local indexOf = flightAssistant.indexOf
local addOnValueAction = flightAssistant.addOnValueAction
local addOnValueChangedAction = flightAssistant.addOnValueChangedAction
local addOnValueBetweenAction = flightAssistant.addOnValueBetweenAction
local checkArgType = flightAssistant.checkArgType
local checkStringOrNumberArg = flightAssistant.checkStringOrNumberArg

--[[------
-- Builder extensions are functions with args (builder, proxy)
-- These are called when initializing a new builder's action proxy
------]]--
local builderExtensions = {}
local function addBuilderExtension(f)
    tinsert(builderExtensions, f)
end
local function createBuilderActionProxy(builder)
    local proxy = builder.proxy
    if not proxy then
        proxy = {}
        builder.proxy = proxy
    else
        clearTable(proxy)
    end
    local n = #builderExtensions
    for i = 1, n do
        builderExtensions[i](builder, proxy)
    end
    return proxy
end

--[[------
  -- Internal builder management
------]]--
local function registerBuilder(pUnit, builder)
    builder.isRegistered = true
    tinsert(pUnit.openBuilders, builder)
    if isDebugEnabled then
        fmtInfo('builder registered: %s (%s)', builder.name, tostring(builder))
    end
end
local function unregisterBuilder(builder)
    builder.isRegistered = false
    local list = builder.pUnit.openBuilders
    local index = indexOf(list, builder)
    if index > 0 then
        tremove(list, index)
        if isDebugEnabled then
            fmtInfo('builder unregistered: %s (%s)', builder.name, tostring(builder))
        end
    end
end
local function closeBuilder(builder)
    if builder.isRegistered then
        unregisterBuilder(builder)
    elseif isDebugEnabled then
        fmtInfo('closing builder %s (%s)', builder.name, tostring(builder))
    end
    if builder.proxy then
        clearTable(builder.proxy)
        builder.proxy = nil
    end
    builder.close = nil
    builder.build = nil
    builder.onBuildCb = nil
    builder.createAction = nil
    builder.addBuilderAction = nil
    builder.buildActionWrapperCb = nil
    builder.buildActionCb = nil
    local onCloseCb = builder.onCloseCb
    if onCloseCb then
        builder.onCloseCb = nil
        onCloseCb(builder)
    end
end
local function build(builder)
    local cb = builder.onBuildCb
    local result = cb and cb(builder) or nil
    closeBuilder(builder)
    return result
end
local function createBuilderAction(builder)
    local baId = builder.actionId
    local action = builder.buildActionCb(builder)
    if action then
        action.baId = baId
    end
    local buildActionWrapperCb = builder.buildActionWrapperCb
    if buildActionWrapperCb then
        builder.action = action
        local wrappedAction = buildActionWrapperCb(builder)
        wrappedAction.baId = builder.actionId
        return wrappedAction
    else
        return action
    end
end
local function getObserverIndex(observers, baId)
    local n = #observers
    for i = 1, n do
        if observers[i].baId == baId then
            return i
        end
    end
    return 0
end
local function addBuilderAction(builder, observers)
    local observerIndex = getObserverIndex(observers, builder.actionId)
    local action
    if observerIndex == 0 then
        action = createBuilderAction(builder)
        tinsert(observers, action)
    else
        action = observers[observerIndex]
    end
    return action.handle
end
local installValueInspectionProxy = function(builder, eventSourceAccessor)
    local proxy = {}
    builder.proxy = proxy
    proxy.valueChanged = function()
        createBuilderActionProxy(builder)
        builder.onBuildCb = function(_)
            return addOnValueChangedAction(eventSourceAccessor, builder:createAction())
        end
        return proxy
    end
    proxy.value = function(value)
        if isDebugUnitEnabled then
            checkStringOrNumberArg('.value(value)', 'value', value, true, 2)
        end
        createBuilderActionProxy(builder)
        builder.onBuildCb = function(_)
            return addOnValueAction(eventSourceAccessor, builder:createAction(), value or 1)
        end
        return proxy
    end
    proxy.valueBetween = function(minValue, maxValue)
        if isDebugUnitEnabled then
            checkArgType('.valueBetween(minValue, maxValue)', 'minValue', minValue, 'number', true, 2)
            checkArgType('.valueBetween(minValue, maxValue)', 'maxValue', maxValue, 'number', true, 2)
        end
        createBuilderActionProxy(builder)
        builder.onBuildCb = function(_)
            return addOnValueBetweenAction(eventSourceAccessor, builder:createAction(), minValue, maxValue)
        end
        return proxy
    end
end

local function buildSimCallbackAction(builder)
    local action = createBuilderAction(builder)
    addSimCallbackAction(builder.pUnit, builder.name, action)
    return action.handle
end

--[[------
    -- exported functions
------]]--
local function createBuilder(pUnit, name, onBuildCb, onCloseCb, createActionProxy)
    local builder = { pUnit = pUnit,
                      name = name,
                      onBuildCb = onBuildCb,
                      onCloseCb = onCloseCb,
                      build = build, close = closeBuilder,
                      addBuilderAction = addBuilderAction,
                      createAction = createBuilderAction }
    if createActionProxy then
        builder.proxy = createBuilderActionProxy(builder)
    end
    registerBuilder(pUnit, builder)
    return builder
end

local function createOnEventActionBuilder(pUnit, name, eventSourceAccessor)
    return createBuilder(pUnit, name,
            function(builder)
                addOnValueChangedAction(eventSourceAccessor, builder:createAction());
            end, nil, true)
end

local function createValueInspectionBuilder(pUnit, name, eventSourceAccessor)
    local builder = { pUnit = pUnit, name = name, build = build, close = closeBuilder,
                      addBuilderAction = addBuilderAction, createAction = createBuilderAction }
    registerBuilder(pUnit, builder)
    installValueInspectionProxy(builder, eventSourceAccessor)
    return builder
end

--[[------
  --Callback action builder extension
------]]--
do
    local function buildWithCallbackAction(builder, f)
        local actionId = 'callback ' .. tostring(f)
        local pUnit = builder.pUnit
        builder.actionId = actionId
        builder.buildActionCb = function()
            return getOrCreateCallbackAction(pUnit, actionId, f)
        end
        return builder:build()
    end
    local function prepareProxy(builder, proxy)
        if isDebugUnitEnabled then
            proxy.call = function(f)
                if type(f) ~= 'function' then
                    builder:close()
                    checkArgType('.call(f)', 'f', f, 'function', true, 2)
                end
                return buildWithCallbackAction(builder, f)
            end
        else
            proxy.call = function(f)
                return buildWithCallbackAction(builder, f)
            end
        end
    end
    addBuilderExtension(prepareProxy)
end

--[[------
  --Install extension
------]]--
local function initPUnit(pUnit, proxy)
    if not pUnit.openBuilders then
        pUnit.openBuilders = {}

        local onUnitActivated = proxy.onUnitActivated
        local onUnitDeactivating = proxy.onUnitDeactivating
        local onSimulationPause = proxy.onSimulationPause
        local onSimulationResume = proxy.onSimulationResume
        local onSimulationFrame = proxy.onSimulationFrame

        proxy.onUnitActivated = function(callbackf)
            if callbackf then
                onUnitActivated(callbackf)
            else
                return createBuilder(pUnit, 'onUnitActivated', buildSimCallbackAction, nil, true).proxy
            end
        end
        proxy.onUnitDeactivating = function(callbackf)
            if callbackf then
                onUnitDeactivating(callbackf)
            else
                return createBuilder(pUnit, 'onUnitDeactivating', buildSimCallbackAction, nil, true).proxy
            end
        end
        proxy.onSimulationPause = function(callbackf)
            if callbackf then
                onSimulationPause(callbackf)
            else
                return createBuilder(pUnit, 'onSimulationPause', buildSimCallbackAction, nil, true).proxy
            end
        end
        proxy.onSimulationResume = function(callbackf)
            if callbackf then
                onSimulationResume(callbackf)
            else
                return createBuilder(pUnit, 'onSimulationResume', buildSimCallbackAction, nil, true).proxy
            end
        end
        proxy.onSimulationFrame = function(callbackf)
            if callbackf then
                onSimulationFrame(callbackf)
            else
                return createBuilder(pUnit, 'onSimulationFrame', buildSimCallbackAction, nil, true).proxy
            end
        end
    end
end

local function closeAllOpenBuilders(pUnit)
    local openBuilders = pUnit.openBuilders
    local n = #openBuilders
    local builder
    for i = 1, n do
        builder = openBuilders[i]
        builder.isRegistered = false
        closeBuilder(builder)
        openBuilders[i] = nil
    end
end

--[[------
    -- export
------]]--
return {
    initPUnit = initPUnit,
    afterSimulationFrame = closeAllOpenBuilders,
    createBuilder = createBuilder,
    createOnEventActionBuilder = createOnEventActionBuilder,
    createValueInspectionBuilder = createValueInspectionBuilder,
    addBuilderExtension = addBuilderExtension,
}
