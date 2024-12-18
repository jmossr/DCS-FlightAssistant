--[=[------
    --FlightAssistant
    --Builder

    Allows extensions to combine event sources and actions from different extensions
    without knowing about other extensions.

    The following example uses extensions 'builder', 'DCS-calls' and 'scheduler'
    and is based on this DCS knowledge: F/A-18 device 0, argument 47 = 'A/A indicator light':
    onDeviceArgument(0, 47).valueAbove(0.2).schedule(0.5).setUserFlag("AAIsOn")
    --> what it does: when 'A/A indicator light' switches from OFF to ON,
                      schedule to set user flag "AAIsOn" to a value of 1 after a delay of 0.5 seconds

    To use this library in an extension, it can be imported as follows:
        local flightAssistant = ...
        local builderLib = flightAssistant.requireExtension('builder')
        local createBuilder = builderLib.createBuilder

    Background information:
        Upon activating a player unit, FlightAssistant will call function 'initPUnit(pUnit, proxy)'
        for every extension that exports that function. This way an extension can add data structures
        to the player unit and can add functions to the proxy table. All data and functions in the
        proxy table will be made available to the code loaded for that particular player module.

    Using this library, any extension can
        1. define functions to get or create a specific event source with which
           any action from any extension can be combined;
        2. register functions to attach an action to an event source created by any extension.
           An action attached to an event source will be executed whenever the event source fires an event

    Notes:
        [1.] To define an event source that can be combined with an action later on,
             an extension should provide a function that creates a 'builder' and returns a table
             containing all functions available to a player module to connect actions to that event source.
             See function 'createBuilder' available in this library.
        [2.] See function 'addBuilderExtension' in this library.

        Action: an action is a lua table with a fire-method.
                The fire-method will be called with event source specific arguments.
                action:fire(eventArg1, eventArg2,...)

    This library provides the following functions to other extensions:

    --
    createBuilder(pUnit, name, onBuildCb, onCloseCb, createActionProxy)
        :: creates a new builder to set up an event source.
        pUnit             : player unit, a table containing al data linked to the current player unit.
                            An extension can add data or interact with data in this table.
        name              : a human readable name for this builder, used for logging when debugging
        onBuildCb         : function called to build the actual event source. The builder table will be passed
                            as an argument to this function.
        onCloseCb         : function called when the builder is closed, i.e. after building or when the builder
                            is discarded without building. This may be useful to clean up stuff.
        createActionProxy : (boolean) value to indicate whether a function table should be created linked
                            to the created builder and containing functions to attach all known actions.

        returns           : the created builder, a table with at least the following keys:
                            pUnit
                            name
                            If createActionProxy resolves to 'true', the builder will also contain a
                            function table accessible by key 'proxy'.

        Special builder methods:
            builder:addBuilderAction(actionList) : creates the action attached to the builder
                                     and inserts it into the given list of actions.
                                 !!! To be able to build an action, key 'buildActionCb' and key 'actionId'
                                     (builder.buildActionCb and builder.actionId)
                                      must be set prior to calling this method.
            builder:createAction() : creates the action attached to the builder.
                                 !!! To be able to build an action, key 'buildActionCb' and key 'actionId'
                                     (builder.buildActionCb and builder.actionId)
                                      must be set prior to calling this method.
            builder:build()        : executes the onBuildCb of the builder and performs some
                                     internal housekeeping tasks.

        Example usage:
                local function initPUnit(pUnit, proxy)
                    proxy.onSignal = function(signal)
                        local buildCb = function(builder)
                            local eventSource = getOrCreateSignal(builder.pUnit, signal)
                            builder:addBuilderAction(eventSource.observers);
                        end
                        local builder = createBuilder(pUnit, 'onSignal(' .. signal .. ')', buildCb, nil, true)
                        return builder.proxy
                    end
                end

    --
    addBuilderExtension(f)
        :: adds a callback function that will be called with arguments (builder, builder.proxy)
        :: whenever a new builder is created.
        f       : callback function that will be called when initializing a builder

        Example usage, to define an action 'fireSignal(signal)' that can be attached to an event source:

            do
                local function buildWithSignalAction(builder, signal)
                    local actionId = 'fireSignal(' .. signal .. ')'
                    local pUnit = builder.pUnit
                    builder.actionId = actionId
                    builder.buildActionCb = function()
                        return getOrCreateSignal(pUnit, signal)
                    end
                    return builder:build()
               end
               local function prepareActions(builder, actionTable)
                   actionTable.fireSignal = function(signal)
                       return buildWithSignalAction(builder, signal)
                   end
               end

               builderLib.addBuilderExtension(prepareActions)
           end

--------]=]
local flightAssistantCore = ...
local tostring = tostring
local tinsert = table.insert
local tremove = table.remove
local type = type
local fmtInfo = flightAssistantCore.logger.fmtInfo
local isDebugEnabled = flightAssistantCore.config.isDebugEnabled
local isDebugUnitEnabled = flightAssistantCore.config.isDebugUnitEnabled
local clearTable = flightAssistantCore.tools.clearTable
local addSimCallbackAction = flightAssistantCore.pUnit.addSimCallbackAction
local getOrCreateCallbackAction = flightAssistantCore.pUnit.getOrCreateCallbackAction
local indexOf = flightAssistantCore.tools.indexOf
local addOnValueAction = flightAssistantCore.actions.addOnValueAction
local addOnValueChangedAction = flightAssistantCore.actions.addOnValueChangedAction
local addOnValueBetweenAction = flightAssistantCore.actions.addOnValueBetweenAction
local checkArgType = flightAssistantCore.debugtools.checkArgType
local checkStringOrNumberArg = flightAssistantCore.debugtools.checkStringOrNumberArg

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
local removeValueInspectionFunctions = function(valueInspectionProxy)
    valueInspectionProxy.valueChanged = nil
    valueInspectionProxy.value = nil
    valueInspectionProxy.valueBetween = nil
    valueInspectionProxy.valueAbove = nil
    valueInspectionProxy.valueBelow = nil
end
local installValueInspectionProxy = function(builder, eventSourceAccessor)
    local proxy = {}
    builder.proxy = proxy
    proxy.valueChanged = function()
        createBuilderActionProxy(builder)
        builder.onBuildCb = function(_)
            return addOnValueChangedAction(eventSourceAccessor, builder:createAction(), builder.debug)
        end
        removeValueInspectionFunctions(proxy)
        return proxy
    end
    proxy.value = function(value)
        if isDebugUnitEnabled then
            checkStringOrNumberArg('.value(value)', 'value', value, true, 2)
        end
        createBuilderActionProxy(builder)
        builder.onBuildCb = function(_)
            return addOnValueAction(eventSourceAccessor, builder:createAction(), value or 1, builder.debug)
        end
        removeValueInspectionFunctions(proxy)
        return proxy
    end
    proxy.valueBetween = function(minValue, maxValue)
        if isDebugUnitEnabled then
            checkArgType('.valueBetween(minValue, maxValue)', 'minValue', minValue, 'number', true, 2)
            checkArgType('.valueBetween(minValue, maxValue)', 'maxValue', maxValue, 'number', true, 2)
        end
        createBuilderActionProxy(builder)
        builder.onBuildCb = function(_)
            return addOnValueBetweenAction(eventSourceAccessor, builder:createAction(), minValue, maxValue, builder.debug)
        end
        removeValueInspectionFunctions(proxy)
        return proxy
    end
    proxy.valueAbove = function(minValue)
        if isDebugUnitEnabled then
            checkArgType('.valueAbove(minValue)', 'minValue', minValue, 'number', true, 2)
        end
        createBuilderActionProxy(builder)
        builder.onBuildCb = function(_)
            return addOnValueBetweenAction(eventSourceAccessor, builder:createAction(), minValue, nil, builder.debug)
        end
        removeValueInspectionFunctions(proxy)
        return proxy
    end
    proxy.valueBelow = function(maxValue)
        if isDebugUnitEnabled then
            checkArgType('.valueBelow(maxValue)', 'maxValue', maxValue, 'number', true, 2)
        end
        createBuilderActionProxy(builder)
        builder.onBuildCb = function(_)
            return addOnValueBetweenAction(eventSourceAccessor, builder:createAction(), nil, maxValue, builder.debug)
        end
        removeValueInspectionFunctions(proxy)
        return proxy
    end
    proxy.debug = function()
        builder.debug = true
        proxy.debug = nil
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
