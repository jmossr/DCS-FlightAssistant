local sformat = string.format
local type = type
local error = error

local function checkArgType(fsignature, argName, arg, expectedType, requireNonNil, errorLevel)
    if requireNonNil or arg then
        local argType = type(arg)
        if argType ~= expectedType then
            error(sformat('%s \'%s\' must be a %s, not a %s', fsignature, argName, expectedType, argType), errorLevel + 1)
        end
    end
end
local function checkStringOrNumberArg(fsignature, argName, arg, requireNonNil, errorLevel)
    if requireNonNil or arg then
        local argType = type(arg)
        if argType ~= 'string' and argType ~= 'number' then
            error(sformat('%s \'%s\' must be a string or a number, not a %s', fsignature, argName, argType), errorLevel + 1)
        end
    end
end
local function checkPositiveNumberArg(fsignature, argName, arg, requireNonNil, errorLevel)
    checkArgType(fsignature, argName, arg, 'number', requireNonNil, errorLevel + 1)
    if arg and arg < 0 then
        error(sformat('%s \'%s\' must be a positive number, not %s', fsignature, argName, arg), errorLevel + 1)
    end
end

return {
    checkArgType = checkArgType,
    checkStringOrNumberArg = checkStringOrNumberArg,
    checkPositiveNumberArg = checkPositiveNumberArg,
}