--[[--------
	FlightAssistant loader

	Place this file in 'Saved Games\DCS\Scripts\Hooks' to enable Flight Assistant.

	Requires at least the following files:
	- Saved Games\DCS\Scripts\FlightAssistant\FlightAssistant.lua
	- Saved Games\DCS\Scripts\FlightAssistant\pUnit.lua

------------]]
do
    local DEBUG = @FA_DEBUG@
    local scriptsDir = lfs.writedir() .. 'Scripts\\'
    local flightAssistantDir = scriptsDir .. 'FlightAssistant\\'
    local scriptFile = flightAssistantDir .. 'FlightAssistant.lua'
    local extensionsDirName = 'extensions'
    local extensionsDir = flightAssistantDir .. extensionsDirName .. '\\'

    local logSubsystemName = 'FLIGHTASSISTANT_LOADER'

    local function collectAssistants()
        local flightAssistants = {}
        local smatch = string.match
        local skip
        local assistantConfigFile
        for entry in lfs.dir(flightAssistantDir) do
            skip = smatch(entry, '^%.+$') or smatch(entry, '^' .. extensionsDirName .. '$') or smatch(entry, '.*%.[Ll][Uu][Aa]$') or smatch(entry, '.*%.[Tt][Xx][Tt]$')
            if not skip then
                assistantConfigFile = flightAssistantDir .. entry .. '\\' .. entry .. "-config.lua"
                local f, err = loadfile(assistantConfigFile)
                if f then
                    local assistantConfigTable = {}
                    setfenv(f, assistantConfigTable)
                    local ok, r = pcall(f)
                    if ok then
                        flightAssistants[entry] = assistantConfigTable
                    else
                        log.write(logSubsystemName, log.ERROR, 'Failed to load assistant config file ' .. assistantConfigFile .. ': ' .. (r or '?'))
                    end
                elseif DEBUG then
                    log.write(logSubsystemName, log.INFO, 'Failed to load file ' .. assistantConfigFile .. ': ' .. (err or '?'))
                end
            elseif DEBUG then
                log.write(logSubsystemName, log.INFO, 'Skipping ' .. entry .. ' while looking for assistants')
            end
        end
        return flightAssistants
    end

    --[[------
        Configuration
    --------]]
    local config = {
        -- General - required
        --===================--
        flightAssistantScriptFile = scriptFile,

        -- General - optional
        --===================--
        reloadUserScriptsOnMissionLoad = @FA_RELOAD_USER_SCRIPTS@,

        -- Debug FlightAssistant and player unit specific code
        debug = DEBUG,

        -- Debug player unit specific code
        debugUnit = @FA_DEBUG_UNIT@,

        -- System - optional
        --===================--
        logSubsystemName = 'FLIGHTASSISTANT',

        extensionsDir = extensionsDir,

        --[[------
        -- Lower and upper boundary for all possible values that may be returned
        -- by event sources. This includes for example device argument values or
        -- device command values. Default these boundary values are set to -1000000 and 1000000.
        -- Uncomment if another range is required.
        --------]]

        --absoluteMinimumEventValue = -1000000,
        --absoluteMaximumEventValue = 1000000,

        flightAssistants = collectAssistants(),
    }

    --[[------
        Load
    --------]]
    local lua, err = loadfile(scriptFile)
    if not lua then
        log.write(logSubsystemName, log.ERROR, 'Loading ' .. scriptFile .. ' FAILED: ' .. err)
    else
        local ok, r = pcall(lua, config)
        if not ok then
            log.write(logSubsystemName, log.ERROR, 'Executing ' .. scriptFile .. ' FAILED: ' .. r)
        end
    end
end
