local lwrite = log.write
local lINFO = log.INFO
local lWARNING = log.WARNING
local lERROR = log.ERROR
local unpack = unpack
local sformat = string.format
local type = type
local tostring = tostring
local pairs = pairs

return {
    createLogger = function(logSubsystemName)
        local function printTable(name, t, depth, indent)
            if t then
                if (type(t) ~= 'table') then
                    lwrite(logSubsystemName, lINFO, sformat('%s is not a table but a %s', name, type(t)))
                else
                    local prefix = indent or ''
                    local d = depth or 1
                    lwrite(logSubsystemName, lINFO, sformat('%sTable %s', prefix, name))
                    for n, v in pairs(t) do
                        if d > 1 and type(v) == 'table' then
                            lwrite(logSubsystemName, lINFO, sformat("%s  - %s = (%s)", prefix, n, tostring(v), type(v)))
                            printTable(n, v, d - 1, prefix .. "    ")
                        else
                            lwrite(logSubsystemName, lINFO, sformat("%s  - %s = %s (%s)", prefix, n, tostring(v), type(v)))
                        end
                    end
                end
            else
                lwrite(logSubsystemName, lINFO, sformat('Table not found: %s = nil', name))
            end
        end

        return {

            fmtInfo = function(fmt, ...)
                lwrite(logSubsystemName, lINFO, sformat(fmt, unpack(arg)))
            end,
            fmtWarning = function(fmt, ...)
                lwrite(logSubsystemName, lWARNING, sformat(fmt, unpack(arg)))
            end,
            fmtError = function(fmt, ...)
                lwrite(logSubsystemName, lERROR, sformat(fmt, unpack(arg)))
            end,
            printTable = printTable
        }
    end
}