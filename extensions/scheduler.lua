--[=[------
    --FlightAssistant
    --Scheduler

    Allows to schedule other actions at a later time.
    Actions can be scheduled to execute only once or periodically.

    Usage:
    schedule(f, delay [, period [, maxCalls]])
        f        : function to execute
        delay    : time in seconds to wait before executing the action for the first time
        period   : time in seconds to wait before repeating the action again, 0 (zero) to execute the action only once. Default 0 (zero)
        maxCalls : max number of times to repeat the action, nil to specify <unlimited>. Default <unlimited>

        returns  : a handle with two functions
                   handle.cancel() to cancel all following executions
                   handle.isScheduled() indicates whether the action is still scheduled for one or more executions

     With extension 'builder' loaded this also adds the following building options:

     schedule(delay [, period [, maxCalls]]).call(f)
     schedule(delay [, period [, maxCalls]]).<someOtherAction>

     <onSomeEvent>.schedule(f, delay [, period [, maxCalls]])
     <onSomeEvent>.schedule(delay [, period [, maxCalls]]).call(f)
     <onSomeEvent>.schedule(delay [, period [, maxCalls]]).<someOtherAction>

--------]=]
local tostring = tostring
local tinsert = table.insert
local type = type
local getTime = Export.LoGetModelTime
local flightAssistant = ...
local isDebugUnitEnabled = flightAssistant.isDebugUnitEnabled
local getOptionalExtension = flightAssistant.getOptionalExtension
local getOrCreateCallbackAction = flightAssistant.getOrCreateCallbackAction
local checkArgType = flightAssistant.checkArgType
local checkPositiveNumberArg = flightAssistant.checkPositiveNumberArg

local function runScheduledAction(scheduledAction, time)
    local action = scheduledAction.action
    if not action.disabled then
        if scheduledAction.time <= time then
            action:fire()
            if scheduledAction.maxCalls then
                scheduledAction.maxCalls = scheduledAction.maxCalls - 1
                if scheduledAction.maxCalls <= 0 then
                    scheduledAction.disabled = true
                end
            end
            if not action.disabled and scheduledAction.period > 0 then
                scheduledAction.time = scheduledAction.time + scheduledAction.period
            else
                scheduledAction.disabled = true
            end
        end
    else
        scheduledAction.disabled = true
    end
end

local function checkScheduledActions(pUnit)
    local list = pUnit.scheduledActions
    local n = #list
    if n > 0 then
        local time = getTime()
        local insertIndex = 1
        local scheduledAction
        for i = 1, n do
            scheduledAction = list[i]
            if not scheduledAction.disabled then
                if i ~= insertIndex then
                    list[insertIndex] = scheduledAction
                    list[i] = nil
                end
                insertIndex = insertIndex + 1
                runScheduledAction(scheduledAction, time)
            else
                list[i] = nil
            end
        end
    end
end

local function normalizePeriodAndMaxCalls(period, maxCalls)
    local p = tonumber(period) or 0
    if p == 0 or tonumber(maxCalls) == 1 then
        return 0, 1
    else
        return p, maxCalls
    end
end

local function createScheduledAction(pUnit, action, delay, period, maxCalls)
    local now = getTime()
    local pd, mx = normalizePeriodAndMaxCalls(period, maxCalls)
    local scheduledAction = { pUnit = pUnit, name = action.name, action = action,
                              time = delay + now,
                              period = pd,
                              maxCalls = mx }
    tinsert(pUnit.scheduledActions, scheduledAction)
    if delay < 0.05 then
        runScheduledAction(scheduledAction, now)
    end
    return {
        cancel = function()
            scheduledAction.disabled = true
        end,
        isScheduled = function()
            return not scheduledAction.disabled
        end
    }
end

local function scheduleCallback(pUnit, f, delay, period, maxCalls)
    local pd, mx = normalizePeriodAndMaxCalls(period, maxCalls)
    return createScheduledAction(pUnit, getOrCreateCallbackAction(pUnit, 'callback ' .. tostring(f), f), delay, pd, mx)
end

local pscheduleCallback
local checkScheduleArgs
if isDebugUnitEnabled then
    checkScheduleArgs = function(fsignature, delay, period, maxCalls, errorLevel)
        local lvl = errorLevel + 1
        checkPositiveNumberArg(fsignature, 'delay', delay, true, lvl)
        checkPositiveNumberArg(fsignature, 'period', period, false, lvl)
        checkPositiveNumberArg(fsignature, 'maxCalls', maxCalls, false, lvl)
    end
    pscheduleCallback = function(pUnit, f, delay, period, maxCalls)
        checkArgType('schedule(f, delay, period, maxCalls)', 'f', f, 'function', true, 2)
        checkScheduleArgs('schedule(f, delay, period, maxCalls)', delay, period, maxCalls, 2)
        return scheduleCallback(pUnit, f, delay, period, maxCalls)
    end
end

local schedule = pscheduleCallback or scheduleCallback
local createScheduleBuilder

--[[------
    -- Builder extensions
------]]--
local builderLib = getOptionalExtension('builder')
if builderLib then
    --[[------
      -- Install schedule action builder extension
    ------]]--
    do
        local function fireScheduleAction(action)
            if not action.disabled and not action.scheduled then
                action.scheduled = createScheduledAction(action.pUnit, action.action, action.delay, action.period, action.maxCalls)
            end
        end
        local function createScheduleAction(builder)
            local name = 'schedule(' .. tostring(builder.delay) .. ', ' .. tostring(builder.period) .. ', ' .. tostring(builder.maxCalls) .. ', ' .. builder.actionId .. ')'
            builder.actionId = name
            local scheduleAction = { pUnit = builder.pUnit, name = name, handle = 0,
                                     action = builder.action,
                                     delay = builder.delay, period = builder.period, maxCalls = builder.maxCalls,
                                     fire = fireScheduleAction }
            scheduleAction.handle = {
                cancel = function()
                    if scheduleAction.scheduled then
                        scheduleAction.scheduled.cancel()
                    else
                        scheduleAction.disabled = true
                    end
                end,
                isScheduled = function()
                    return scheduleAction.scheduled and scheduleAction.scheduled.isScheduled()
                end
            }
            return scheduleAction
        end

        local function buildWithScheduleAction(builder, arg1, arg2, arg3, arg4)
            local proxy = builder.proxy
            local period, maxCalls
            builder.buildActionWrapperCb = createScheduleAction
            if type(arg1) == 'function' then
                period, maxCalls = normalizePeriodAndMaxCalls(arg3, arg4)
                builder.delay = arg2
                builder.period = period
                builder.maxCalls = maxCalls
                return proxy.call(arg1)
            else
                period, maxCalls = normalizePeriodAndMaxCalls(arg2, arg3)
                builder.delay = arg1
                builder.period = period
                builder.maxCalls = maxCalls
                proxy.schedule = nil
                return proxy
            end
        end

        local function prepareProxy(builder, proxy)
            if isDebugUnitEnabled then
                proxy.schedule = function(arg1, arg2, arg3, arg4)
                    if type(arg1) == 'function' then
                        checkScheduleArgs('schedule(f, delay, period, maxCalls)', arg2, arg3, arg4, 2)
                    else
                        checkScheduleArgs('schedule(delay, period, maxCalls)', arg1, arg2, arg3, 2)
                    end
                    return buildWithScheduleAction(builder, arg1, arg2, arg3, arg4)
                end
            else
                proxy.schedule = function(arg1, arg2, arg3, arg4)
                    return buildWithScheduleAction(builder, arg1, arg2, arg3, arg4)
                end
            end
        end

        builderLib.addBuilderExtension(prepareProxy)
    end

    --[[------
      -- Install schedule builder
    ------]]--
    do
        local createBuilder = builderLib.createBuilder

        local function buildScheduledAction(builder)
            return createScheduledAction(builder.pUnit, builder:createAction(), builder.delay, builder.period, builder.maxCalls)
        end

        if isDebugUnitEnabled then
            createScheduleBuilder = function(pUnit, arg1, arg2, arg3, arg4)
                if type(arg1) == 'function' then
                    checkScheduleArgs('schedule(f, delay, period, maxCalls)', arg2, arg3, arg4, 2)
                    return scheduleCallback(pUnit, arg1, arg2, arg3, arg4)
                else
                    checkScheduleArgs('schedule(delay, period, maxCalls)', arg1, arg2, arg3, 2)
                    local delay = arg1
                    local period, maxCalls = normalizePeriodAndMaxCalls(arg2, arg3)
                    local builder = createBuilder(pUnit,
                            "schedule(" .. delay .. ', ' .. period .. ', ' .. (maxCalls or '-') .. ')',
                            buildScheduledAction, nil, true)
                    builder.delay = delay
                    builder.period = period
                    builder.maxCalls = maxCalls
                    return builder.proxy
                end
            end
        else
            createScheduleBuilder = function(pUnit, arg1, arg2, arg3, arg4)
                if type(arg1) == 'function' then
                    return scheduleCallback(pUnit, arg1, arg2, arg3, arg4)
                else
                    local delay = arg1
                    local period, maxCalls = normalizePeriodAndMaxCalls(arg2, arg3)
                    local builder = createBuilder(pUnit,
                            "schedule(" .. delay .. ', ' .. period .. ', ' .. (maxCalls or '-') .. ')',
                            buildScheduledAction, nil, true)
                    builder.delay = delay
                    builder.period = period
                    builder.maxCalls = maxCalls
                    return builder.proxy
                end
            end
        end
    end
end

local puschedule = createScheduleBuilder or schedule

local function initPUnit(pUnit, proxy)
    if not pUnit.scheduledActions then
        local scheduledActions = {}
        pUnit.scheduledActions = scheduledActions
        proxy.schedule = function(arg1, arg2, arg3, arg4)
            return puschedule(pUnit, arg1, arg2, arg3, arg4)
        end
        proxy.getScheduledActionCount = function()
            return #scheduledActions
        end
    end
end

return {
    initPUnit = initPUnit,
    beforeSimulationFrame = checkScheduledActions,
}