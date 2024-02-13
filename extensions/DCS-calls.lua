--[=[------
    --FlightAssistant
    --DCS calls

    Provides the following functions to interact with DCS:

    --
    executeLuaIn(env, lua) : executes lua code in a specific DCS environment or state
        env     : DCS environment to execute the lua code in, one of 'server', 'mission', 'export', 'config'
        lua     : the lua code to execute as a single string

        returns : result, errorMsg
            a valid result or true if execution succeeded
            an error message if execution failed, result will be nil in that case

    --
    executeLuaInServerOrMissionEnv(lua) : executes lua code in environment/state 'server' and tries to execute it again
                                          in environment/state 'mission' only if the first attempt failed.environment
        lua     : the lua code to execute as a single string

        returns : result, errorMsg
            a valid result or true if execution succeeded
            an error message if execution failed, result will be nil in that case

    --
    getMissionPlayerUnitID() : tries to fetch the player's unit id in context 'mission' or 'server'
        This is different from the player's unit id in this context, where FlightAssistant is running.
        returns : result, errorMsg

    --
    setUserFlag(flag [, value]) : assigns a value to a DCS mission flag
        flag    : flag name or number
        value   : the value to set, default 1

    --
    getUserFlag(flag) : returns a string representation of the value held by a DCS mission flag
        flag    : flag name or number

        returns : flag value as a string

    --
    startListenCommand(device, command, flag [, minValue [, maxValue [, numberOfHits]]]) : instructs DCS to set the given
                        flag to value 1 when the specified device command has hit a value in the given range a number
                        of times
       device   : device number
       command  : command number to listen for
       flag     : flag name or number identifying the flag to set
       minValue : lower boundary of the range for the command value to hit, inclusive; default 1
       maxValue : upper boundary of the range for the command value to hit, inclusive; default 1000000
       numberOfHits : number of hits to record before setting the flag value to 1; default 1

    --
    performClickableCommand(device, command [, value]) : execute a clickable command
                        For example, to execute pressing and releasing the UFC A/P button in the F/A-18, you would
                        call:
                        performClickableCommand(25, 3001, 1) --depress the A/P button
                        and then, a few tens of seconds later
                        performClickableCommand(25, 3001, 0) -- release the A/P button
       device   : device number
       command  : command number to execute
       value    : value to set; default 1

    --
    outTextForUnit(unitId, text, displayTime [, clearView]) : shows a text message to a specific unit
        unitId  : unit identification number in context 'mission'
        text    : text to display
        displayTime : duration in seconds the text should stay visible
        clearView : true to clear the screen of any previous messages before showing this message; default false

    --
    outText(text, displayTime [, clearview]) : shows a text message to all units
        text    : text to display
        displayTime : duration in seconds the text should stay visible
        clearView : true to clear the screen of any previous messages before showing this message; default false

    --
    getDeviceArgumentValue(device, arg) : shorthand for Export.GetDevice(device):get_argument_value(arg)


    ----
     With extension 'builder' loaded this also adds the following building options:
    ----

    <onSomeEvent>.setUserFlag(flag [, value])
    <onSomeEvent>.performClickableCommand(device, command [, value])
    <onSomeEvent>.outTextForUnit(unitId, text, displayTime [, clearView])
    <onSomeEvent>.outText(text, displayTime [, clearView])

    onDeviceArgument(device, arg).valueChanged().<someAction>
                        executes an action every time the value for a device argument changes
    onDeviceArgument(device, arg).value(value).<someAction>
                        executes an action every time a device argument changes to the specified value
    onDeviceArgument(device, arg).valueBetween(minValue, maxValue).<someAction>
                        executes an action every time a device argument value enters the given range

--------]=]
local pairs = pairs
local error = error
local flightAssistant = getfenv(1)
local fmtWarning = flightAssistant.fmtWarning
local fmtInfo = fmtWarning and flightAssistant.fmtInfo
local isDebugEnabled = flightAssistant.isDebugEnabled
local isDebugUnitEnabled = flightAssistant.isDebugUnitEnabled
local dostring_in = net.dostring_in
local getOptionalExtension = flightAssistant.getOptionalExtension
local XGetDevice = Export.GetDevice
local fire = flightAssistant.fire
local checkArgType = flightAssistant.checkArgType
local checkStringOrNumberArg = flightAssistant.checkStringOrNumberArg
local checkPositiveNumberArg = flightAssistant.checkPositiveNumberArg
local copyAll = flightAssistant.copyAll

local function executeLuaIn(env, lua)
    local ret, success = dostring_in(env, lua)
    if success then
        return ret or success, nil
    else
        return nil, ret
    end
end

local pexecuteLuaIn
if isDebugUnitEnabled then
    pexecuteLuaIn = function(env, lua)
        checkArgType('executeLuaIn(env, lua)', 'env', env, 'string', true, 2)
        checkArgType('executeLuaIn(env, lua)', 'lua', lua, 'string', true, 2)
        return executeLuaIn(env, lua)
    end
end

local function executeLuaInServerOrMissionEnv(lua)
    local res, serr, merr
    res, serr = executeLuaIn('server', lua)
    if not res then
        res, merr = executeLuaIn('mission', lua)
        if not res then
            fmtWarning("Executing net.dostring_in('%s', '%s') FAILED: %s", 'server', lua, serr or '?')
            fmtWarning("Executing net.dostring_in('%s', '%s') FAILED: %s", 'mission', lua, merr or '?')
        end
    end
    return res
end

local pexecuteLuaInServerOrMissionEnv
if isDebugUnitEnabled then
    pexecuteLuaInServerOrMissionEnv = function(lua)
        checkArgType('executeLuaInServerOrMissionEnv(lua)', 'lua', lua, 'string', true, 2)
        return executeLuaInServerOrMissionEnv(lua)
    end
end

--[[
    Returns the player's unit id in context 'mission'. This id is required
    to send text messages to the player (unit).

    Only works when a player unit is active
    Only works in single player
--]]
local function getMissionPlayerUnitID()
    return executeLuaInServerOrMissionEnv('do local unit = world.getPlayer(); return unit and unit:getID() or nil; end')
end

local function listCockpitParams()
    return executeLuaIn('export', 'return list_cockpit_params()')
end

local function listIndication(d)
    return executeLuaIn('export', 'return list_indication(' .. d .. ')')
end

local plistIndication
if isDebugUnitEnabled then
    plistIndication = function(d)
        checkPositiveNumberArg('listIndication(d)', 'd', d, true, 2)
        return listIndication(d)
    end
end

local function setUserFlag(flag, value)
    return executeLuaInServerOrMissionEnv('trigger.action.setUserFlag("' .. flag .. '", ' .. (value or 1) .. ')')
end

local psetUserFlag
if isDebugUnitEnabled then
    psetUserFlag = function(flag, value)
        checkStringOrNumberArg('setUserFlag(flag, value)', 'flag', flag, true, 2)
        checkStringOrNumberArg('setUserFlag(flag, value)', 'value', value, false, 2)
        return setUserFlag(flag, value or 1)
    end
end

local function getUserFlag(flag)
    return executeLuaInServerOrMissionEnv('return tostring(trigger.misc.getUserFlag("' .. flag .. '"))')
end

local pgetUserFlag
if isDebugUnitEnabled then
    pgetUserFlag = function(flag)
        checkStringOrNumberArg('getUserFlag(flag)', 'flag', flag, true, 2)
        return getUserFlag(flag)
    end
end

local function startListenCommand(deviceId, commandId, flag, minValue, maxValue, numberOfHits)
    -- a_start_listen_command(command, flagName, numberOfHits, minValue, maxValue, deviceId)
    return executeLuaInServerOrMissionEnv('a_start_listen_command(' .. commandId .. ', "' .. flag .. '", ' .. (numberOfHits or 1) .. ', ' .. (minValue or 1) .. ', ' .. (maxValue or 1000000) .. ', ' .. deviceId .. ')')
end

local pstartListenCommand
if isDebugUnitEnabled then
    pstartListenCommand = function(deviceId, commandId, flag, minValue, maxValue, numberOfHits)
        checkArgType('startListenCommand(device, command, flag, minValue, maxValue, numberOfHits)', 'device', deviceId, 'number', true, 2)
        checkArgType('startListenCommand(device, command, flag, minValue, maxValue, numberOfHits)', 'command', commandId, 'number', true, 2)
        checkStringOrNumberArg('startListenCommand(device, command, flag, minValue, maxValue, numberOfHits)', 'flag', flag, true, 2)
        checkArgType('startListenCommand(device, command, flag, minValue, maxValue, numberOfHits)', 'minValue', minValue, 'number', false, 2)
        checkArgType('startListenCommand(device, command, flag, minValue, maxValue, numberOfHits)', 'maxValue', maxValue, 'number', false, 2)
        checkArgType('startListenCommand(device, command, flag, minValue, maxValue, numberOfHits)', 'numberOfHits', numberOfHits, 'number', false, 2)
        local res = startListenCommand(deviceId, commandId, flag, minValue, maxValue, numberOfHits)
        if res then
            fmtInfo("Listening to device %s, command %s, setting flag '%s' when command value between %s and %s after %s hits", deviceId, commandId, flag, minValue or 1, maxValue or 10000, numberOfHits or 1)
        end
        return res
    end
end

local function performClickableCommand(deviceId, commandId, value)
    return executeLuaInServerOrMissionEnv('a_cockpit_perform_clickable_action(' .. deviceId .. ', ' .. commandId .. ', ' .. (value or 1) .. ')')
end

local pperformClickableCommand
local checkPerformClickableCommandArgs
if isDebugUnitEnabled then
    checkPerformClickableCommandArgs = function(deviceId, commandId, value, errorLevel)
        local lvl = errorLevel + 1
        checkArgType('performClickableCommand(device, command, value)', 'device', deviceId, 'number', true, lvl)
        checkArgType('performClickableCommand(device, command, value)', 'command', commandId, 'number', true, lvl)
        checkArgType('performClickableCommand(device, command, value)', 'value', value, 'number', false, lvl)
    end
    pperformClickableCommand = function(deviceId, command, value)
        checkPerformClickableCommandArgs(deviceId, command, value, 2)
        return performClickableCommand(deviceId, command, value)
    end
end

--[[------
    --trigger.action.outTextForUnit(unitId, text, displayDuration, clearView)
------]]--
local function outTextForUnit(unitId, text, displayTime, clearView)
    return executeLuaInServerOrMissionEnv('trigger.action.outTextForUnit(' .. unitId .. ', "' .. text .. '", ' .. (displayTime or 3) .. ', ' .. (clearView and 'true' or 'false') .. ')')
end

local poutTextForUnit
if isDebugUnitEnabled then
    poutTextForUnit = function(unitId, text, displayTime, clearView)
        checkArgType('outTextForUnit(unitId, text, displayTime, clearView)', 'unitId', unitId, 'number', true, 2)
        checkArgType('outTextForUnit(unitId, text, displayTime, clearView)', 'text', text, 'string', true, 2)
        checkPositiveNumberArg('outTextForUnit(unitId, text, displayTime, clearView)', 'displayTime', displayTime, false, 2)
        return outTextForUnit(unitId, text, displayTime, clearView)
    end
end

--[[------
    --trigger.action.outText(text, displayDuration, clearView)
------]]--
local function outText(text, displayTime, clearview)
    return executeLuaInServerOrMissionEnv('trigger.action.outText("' .. text .. '", ' .. (displayTime or 3) .. ', ' .. (clearview and 'true' or 'false') .. ')')
end

local poutText
if isDebugUnitEnabled then
    poutText = function(text, displayTime, clearView)
        checkArgType('outText(text, displayTime, clearView)', 'text', text, 'string', true, 2)
        checkPositiveNumberArg('outText(text, displayTime, clearView)', 'displayTime', displayTime, false, 2)
        return outText(text, displayTime, clearView)
    end
end

--[[------
    --Export.GetDevice(device):get_argument_value(arg)
------]]--
local function getDeviceArgumentValue(deviceId, argId)
    return XGetDevice(deviceId):get_argument_value(argId)
end
local pgetDeviceArgumentValue
if isDebugUnitEnabled then
    pgetDeviceArgumentValue = function(deviceId, argId)
        checkArgType('getDeviceArgumentValue(device, arg)', 'device', deviceId, 'number', true, 2)
        checkArgType('getDeviceArgumentValue(device, arg)', 'arg', argId, 'number', true, 2)
        local device = XGetDevice(deviceId)
        if not device then
            error('getDeviceArgumentValue(' .. deviceId .. ', ' .. argId .. ') no such device', 2)
        elseif device.get_argument_value then
            return device:get_argument_value(argId)
        else
            error('getDeviceArgumentValue(' .. deviceId .. ', ' .. argId .. ') device does not support inspecting argument values', 2)
        end
    end
end

local function getOrCreateDeviceInspector(pUnit, deviceId)
    local inspectorsPerDeviceId = pUnit.deviceInspectors
    local inspector = inspectorsPerDeviceId[deviceId]
    if not inspector then
        inspector = {}
        inspectorsPerDeviceId[deviceId] = inspector
    end
    return inspector
end

local function getOrCreateDeviceArgumentInspector(pUnit, deviceId, argId)
    local deviceInspector = getOrCreateDeviceInspector(pUnit, deviceId)
    local argInspector = deviceInspector[argId]
    if not argInspector then
        argInspector = { lastValue = 0, observers = {} }
        deviceInspector[argId] = argInspector
    end
    return argInspector
end

local function checkDeviceArgumentInspectors(pUnit)
    local device
    local argValue
    local oldValue
    for deviceId, argInspectors in pairs(pUnit.deviceInspectors) do
        device = XGetDevice(deviceId)
        for argId, inspector in pairs(argInspectors) do
            argValue = device:get_argument_value(argId)
            oldValue = inspector.lastValue
            if oldValue ~= argValue then
                if isDebugEnabled and inspector.debug then
                    fmtInfo("device %s, argument %s value changed to %s", deviceId, argId, argValue)
                end
                inspector.lastValue = argValue
                fire(inspector.observers, argValue, oldValue, deviceId, argId)
            elseif isDebugEnabled and inspector.debug then
                fmtInfo("device %s, argument %s value = %s", deviceId, argId, argValue)
            end
        end
    end
end

--[[------
    -- Builder extensions
------]]--
local builderLib = getOptionalExtension('builder')
local deviceArgumentInspectorAccessor
if builderLib then
    --[[------
        -- setUserFlag action builder extension
    ------]]--
    local buildWithSUFAction
    do
        local function fireSUFAction(action)
            setUserFlag(action.flag, action.value)
        end
        buildWithSUFAction = function(builder, flag, value)
            local val = value or 1
            local actionId = 'setUserFlag(' .. flag .. ', ' .. val .. ')'
            local pUnit = builder.pUnit
            builder.actionId = actionId
            builder.buildActionCb = function()
                return { pUnit = pUnit, name = actionId, flag = flag, value = val, fire = fireSUFAction }
            end
            return builder:build()
        end
    end

    --[[------
        -- performClickableCommand action builder extension
    ------]]--
    local buildWithCmdAction = function(builder, deviceId, command, value)
        local val = value or 1
        local actionId = 'command(' .. deviceId .. ', ' .. command .. ', ' .. val .. ')'
        local pUnit = builder.pUnit
        builder.actionId = actionId
        builder.buildActionCb = function()
            return { pUnit = pUnit, name = actionId, fire = function()
                performClickableCommand(deviceId, command, value);
            end }
        end
        return builder:build()
    end

    --[[------
        -- outTextForUnit action builder extension
    ------]]--
    local buildWithTxtForUnitAction = function(builder, unitId, text, displayTime, clearView)
        local actionId = 'outTextForUnit(' .. unitId .. ', ' .. text .. ')'
        local pUnit = builder.pUnit
        builder.actionId = actionId
        builder.buildActionCb = function()
            return { pUnit = pUnit, name = actionId, fire = function()
                outTextForUnit(unitId, text, displayTime, clearView);
            end }
        end
        return builder:build()
    end

    --[[------
         -- outText action builder extension
     ------]]--
    local buildWithTxtAction = function(builder, text, displayTime, clearView)
        local actionId = 'outText(' .. text .. ')'
        local pUnit = builder.pUnit
        builder.actionId = actionId
        builder.buildActionCb = function()
            return { pUnit = pUnit, name = actionId, fire = function()
                outText(text, displayTime, clearView);
            end }
        end
        return builder:build()
    end

    --[[------
         -- textToOwnShip action builder extension
     ------]]--
    local buildWithTxtToOwnShipAction = function(builder, text, displayTime, clearView)
        local actionId = 'textToOwnShip(' .. text .. ')'
        local pUnit = builder.pUnit
        local pUnitProxy = pUnit.proxy
        builder.actionId = actionId
        builder.buildActionCb = function()
            return { pUnit = pUnit, name = actionId, fire = function()
                pUnitProxy.textToOwnShip(text, displayTime, clearView);
            end }
        end
        return builder:build()
    end

    --[[------
        -- install action builder extensions
    ------]]--
    local prepareProxy
    if isDebugUnitEnabled then
        prepareProxy = function(builder, proxy)
            proxy.setUserFlag = function(flag, value)
                checkStringOrNumberArg('setUserFlag(flag, value)', 'flag', flag, true, 2)
                checkStringOrNumberArg('setUserFlag(flag, value)', 'value', value, false, 2)
                return buildWithSUFAction(builder, flag, value)
            end
            proxy.performClickableCommand = function(deviceId, command, value)
                checkPerformClickableCommandArgs(deviceId, command, value, 2)
                return buildWithCmdAction(builder, deviceId, command, value)
            end
            proxy.outTextForUnit = function(unitId, text, displayTime, clearView)
                checkArgType('outTextForUnit(unitId, text, displayTime, clearView)', 'unitId', unitId, 'number', true, 2)
                checkArgType('outTextForUnit(unitId, text, displayTime, clearView)', 'text', text, 'string', true, 2)
                checkPositiveNumberArg('outTextForUnit(unitId, text, displayTime, clearView)', 'displayTime', displayTime, false, 2)
                buildWithTxtForUnitAction(builder, unitId, text, displayTime, clearView)
            end
            proxy.outText = function(text, displayTime, clearView)
                checkArgType('outText(text, displayTime, clearView)', 'text', text, 'string', true, 2)
                checkPositiveNumberArg('outText(text, displayTime, clearView)', 'displayTime', displayTime, false, 2)
                buildWithTxtAction(builder, text, displayTime, clearView)
            end
            proxy.textToOwnShip = function(text, displayTime, clearView)
                checkArgType('textToOwnShip(text, displayTime, clearView)', 'text', text, 'string', true, 2)
                checkPositiveNumberArg('textToOwnShip(text, displayTime, clearView)', 'displayTime', displayTime, false, 2)
                buildWithTxtToOwnShipAction(builder, text, displayTime, clearView)
            end
        end
    else
        prepareProxy = function(builder, proxy)
            proxy.setUserFlag = function(flag, value)
                return buildWithSUFAction(builder, flag, value)
            end
            proxy.performClickableCommand = function(deviceId, command, value)
                return buildWithCmdAction(builder, deviceId, command, value)
            end
            proxy.outTextForUnit = function(unitId, text, displayTime, clearView)
                buildWithTxtForUnitAction(builder, unitId, text, displayTime, clearView)
            end
            proxy.outText = function(text, displayTime, clearView)
                buildWithTxtAction(builder, text, displayTime, clearView)
            end
            proxy.textToOwnShip = function(text, displayTime, clearView)
                buildWithTxtToOwnShipAction(builder, text, displayTime, clearView)
            end
        end
    end

    builderLib.addBuilderExtension(prepareProxy)

    deviceArgumentInspectorAccessor = function(pUnit, deviceId, argId)
        return function()
            return getOrCreateDeviceArgumentInspector(pUnit, deviceId, argId);
        end
    end
end

--[[------
    -- pUnit extensions
------]]--
local proxyExtension = {
    executeLuaInServerOrMissionEnv = pexecuteLuaInServerOrMissionEnv or executeLuaInServerOrMissionEnv,
    executeLuaIn = pexecuteLuaIn or executeLuaIn,
    setUserFlag = psetUserFlag or setUserFlag,
    getUserFlag = pgetUserFlag or getUserFlag,
    startListenCommand = pstartListenCommand or startListenCommand,
    performClickableCommand = pperformClickableCommand or performClickableCommand,
    outTextForUnit = poutTextForUnit or outTextForUnit,
    outText = poutText or outText,
    getDeviceArgumentValue = pgetDeviceArgumentValue or getDeviceArgumentValue,
    listCockpitParams = listCockpitParams,
    listIndication = plistIndication or listIndication,
}

local function initPUnit(pUnit, proxy)
    if not pUnit.deviceInspectors then
        local getMissionPUnitID = function()
            local id = pUnit.missionPlayerUnitID
            if not id then
                id = getMissionPlayerUnitID()
                pUnit.missionPlayerUnitID = id
            end
            return id
        end
        pUnit.deviceInspectors = {}
        copyAll(proxyExtension, proxy)
        proxy.getMissionPlayerUnitID = getMissionPUnitID
        proxy.textToOwnShip = function(text, displayTime, clearView)
            local id = getMissionPUnitID()
            if id then
                outTextForUnit(id, text, displayTime, clearView)
            end
        end
        if builderLib then
            local createValueInspectionBuilder = builderLib.createValueInspectionBuilder

            if isDebugUnitEnabled then
                proxy.onDeviceArgument = function(deviceId, argId)
                    checkArgType('onDeviceArgument(device, arg)', 'device', deviceId, 'number', true, 2)
                    checkArgType('onDeviceArgument(device, arg)', 'arg', argId, 'number', true, 2)
                    return createValueInspectionBuilder(pUnit, 'onDeviceArgument(' .. deviceId .. ', ' .. argId .. ')', deviceArgumentInspectorAccessor(pUnit, deviceId, argId)).proxy
                end
            else
                proxy.onDeviceArgument = function(deviceId, argId)
                    return createValueInspectionBuilder(pUnit, 'onDeviceArgument(' .. deviceId .. ', ' .. argId .. ')', deviceArgumentInspectorAccessor(pUnit, deviceId, argId)).proxy
                end
            end
        end
    end
end

local function unitDeactivated(pUnit)
    pUnit.missionPlayerUnitID = nil
end

local export = {
    initPUnit = initPUnit,
    beforeSimulationFrame = checkDeviceArgumentInspectors,
    afterPUnitDeactivation = unitDeactivated,
}
copyAll(proxyExtension, export)

return export