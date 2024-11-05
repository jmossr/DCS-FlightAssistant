local tostring = tostring
local pairs = pairs

local function copyAll(src, dest)
    for k, v in pairs(src) do
        dest[k] = v
    end
end
local function getTrimmedTableId(t)
    return tostring(t):match(":%s*0*([%dABCDEFabcdef]+)")
end
local function NOOP()
end
local function indexOf(list, element)
    local n = #list
    for i = 1, n do
        if list[i] == element then
            return i
        end
    end
    return 0
end
local function listAddOnce(list, element)
    local n = #list
    for i = 1, n do
        if list[i] == element then
            return i
        end
    end
    list[n + 1] = element
end

return {
    copyAll = copyAll,
    getTrimmedTableId = getTrimmedTableId,
    NOOP = NOOP,
    indexOf = indexOf,
    listAddOnce = listAddOnce,
}