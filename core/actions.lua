local flightAssistantCore = ...
local unpack = unpack
local tinsert = table.insert
local tostring = tostring
local tonumber = tonumber

local absoluteMinimumEventValue = flightAssistantCore and flightAssistantCore.config and flightAssistantCore.config.absoluteMinimumEventValue or -1000000
local absoluteMaximumEventValue = flightAssistantCore and flightAssistantCore.config and flightAssistantCore.config.absoluteMaximumEventValue or 1000000

local function fireConditional(self, ...)
    if self.state then
        self.state = self.condition(unpack(arg))
    elseif self.condition(unpack(arg)) then
        self.state = true
        self.action:fire(unpack(arg))
    end
end
--- Adds an action to the specified actionList
-- @param actionList a table to which the action will be inserted using table.insert
-- @param action an action table. An action table must at least contain a function 'fire' to activate the action.
-- @param condition an optional condition. If a condition is specified, the action will only be activated if the
--        specified condition is met. A condition is a function and when tested it will receive all arguments passed
--        to the action's fire call.
local function addAction(actionList, action, condition)
    if condition then
        tinsert(actionList, { action = action, condition = condition, fire = fireConditional })
    else
        tinsert(actionList, action)
    end
end
local function addOnValueChangedAction(eventSourceAccessor, action, debug)
    local eventSource = eventSourceAccessor(absoluteMinimumEventValue, absoluteMaximumEventValue)
    if debug then
        eventSource.debug = true
    end
    addAction(eventSource.observers, action)
end
local function addOnValueAction(eventSourceAccessor, action, value, debug)
    local expected = tostring(value)
    local eventSource = eventSourceAccessor(value, value)
    if debug then
        eventSource.debug = true
    end
    addAction(eventSource.observers, action, function(newValue)
        return expected == tostring(newValue);
    end)
end
local function addOnValueBetweenAction(eventSourceAccessor, action, minValue, maxValue, debug)
    local min = tonumber(minValue) or absoluteMinimumEventValue
    local max = tonumber(maxValue) or absoluteMaximumEventValue
    local eventSource = eventSourceAccessor(minValue, maxValue)
    if debug then
        eventSource.debug = true
    end
    addAction(eventSource.observers, action, function(newValue)
        local numVal = tonumber(newValue)
        return numVal and min <= numVal and numVal <= max;
    end)
end
local function fire(actionList, ...)
    local n = #actionList
    local action
    for i = 1, n do
        action = actionList[i]
        action:fire(unpack(arg))
    end
end
return {
    addAction = addAction,
    addOnValueChangedAction = addOnValueChangedAction,
    addOnValueAction = addOnValueAction,
    addOnValueBetweenAction = addOnValueBetweenAction,
    fire = fire,
}
