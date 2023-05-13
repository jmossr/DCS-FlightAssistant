--[[--------
	FlightAssistant loader

	Place this file in 'Saved Games\DCS[.variant_suffix]\Scripts\Hooks' to enable Flight Assistant.

	Requires at least the following files:
	- Saved Games\DCS[.variant_suffix]\Scripts\FlightAssistant\FlightAssistant.lua
	- Saved Games\DCS[.variant_suffix]\Scripts\FlightAssistant\pUnit.lua

------------]]
do
    local DEBUG = @FA_DEBUG@
    local scriptsDir = lfs.writedir() .. 'Scripts\\'
    local flightAssistantDir = scriptsDir .. 'FlightAssistant\\'
    local scriptFile = flightAssistantDir .. 'FlightAssistant.lua'
    local extensionsDir = flightAssistantDir .. 'extensions\\'

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

        logSubsystemName = 'FLIGHTASSISTANT',

        extensionsDir = extensionsDir,
        extensions = { @FA_EXTENSIONS@ },

        flightAssistants = {
            --[[----
            -- FlightAssistant
            --     The name (key) must match an existing directory name in Saved Games\DCS[.variant_suffix]\Scripts\FlightAssistant
            --     From that directory unit specific lua code will be loaded if available.
            --
            --     You can configure the following attributes:
            --
            --    - pUnitFallbackTable       : Default value: {} (i.e. an empty table)
            --                                 Specifies which alternative can be used for a unit. For example, specifying
            --                                 table { ['P-51D-30-NA'] = 'P-51D-25-NA',
            --                                         ['P-51D-25-NA'] = 'P-51D' }
            --                                 instructs FlightAssistant to try and load file
            --                                 'Saved Games\DCS[.variant_suffix]\Scripts\FlightAssistant\<flightassistant_name>]\P-51D-25-NA.lua'
            --                                 when P-51D-30-NA.lua is not available in that directory.
            --                                 Similarly, FlightAssistant will try to load file
            --                                 'Saved Games\DCS[.variant_suffix]\Scripts\FlightAssistant\<flightassistant_name>]\P-51D.lua'
            --                                 if P-51D-25-NA.lua is not available.
            --
            --    - reloadOnMissionLoad      : Reloads all unit specific code when a new mission is loaded.
            ----]]--

            @FA_NAME@ = {
                pUnitFallbackTable = { ['P-51D-30-NA'] = 'P-51D-25-NA',
                                       ['P-51D-25-NA'] = 'P-51D',
                                       ['P-51D'] = 'TF-51D' },
                reloadOnMissionLoad = @FA_RELOAD_UNIT@,
            },
        }

    }

    --[[------
        Load
    --------]]
    local logSubsystemName = 'FLIGHTASSISTANT_LOADER'
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
