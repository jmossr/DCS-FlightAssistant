local baseDir = '..\\'
local testDir = baseDir .. 'test\\'
local exportLua = testDir .. 'Export.lua'
local exportLuaBackup1 = testDir .. 'Export.lua_backup_1'
local exportLuaBackup2 = testDir .. 'Export.lua_backup_2'
local exportLuaBackup3 = testDir .. 'Export.lua_backup_3'
local _remove = os.remove
local _open = io.open
local _close = io.close

local function fileExists(name)
    local f = _open(name, "r")
    if f then
        _close(f)
        return true
    else
        return false
    end
end

local function removeExportLuaBackupFiles()
    _remove(exportLuaBackup1)
    _remove(exportLuaBackup2)
    _remove(exportLuaBackup3)
end

local function checkFile(f, contents)
    if not fileExists(f) then
        reportError('File ' .. f .. ' not found')
        return
    end
    local fin = _open(f)
    local line = fin:read('*l')
    local lineCount = 0
    while line do
        lineCount = lineCount + 1
        if line ~= contents[lineCount] then
            reportError('Line ' .. lineCount .. ' in ' .. f .. ': expected "' .. tostring(contents[lineCount]) .. '" but got "' .. line .. '"', 3)
            return
        end
        line = fin:read('*l')
    end
    _close(fin)
    lineCount = lineCount + 1;
    if contents[lineCount + 1] then
        reportError('Line ' .. lineCount .. ' in ' .. f .. ': expected "' .. tostring(contents[lineCount]) .. '" but got nothing', 3)
        return
    end
end

local config = {
    debug = false,
    reloadUserScriptsOnMissionLoad = false,
    logSubsystemName = 'TEST',
    scriptsDir = testDir,
}

return { test = function()
    log.setEventsEnabled(true)

    expect('INFO     TEST (main): Installing DCS Control API User callbacks')
    expect('DCS.setUserCallbacks')
    initDCSPlug(config)
    checkEvents('A')

    _remove(exportLua)
    removeExportLuaBackupFiles()

    config.installExport = {'load fa_1;', 'fa_'}
    expect('INFO     TEST (main): Installing DCS Control API User callbacks')
    expect('DCS.setUserCallbacks')
    expect('Wrote Export.lua')
    initDCSPlug(config)
    checkFile(exportLua, {'load fa_1;'})
    if (fileExists(exportLuaBackup1 or fileExists(exportLuaBackup2) or fileExists(exportLuaBackup3))) then
        reportError('Export.lua backup not expected')
    end
    checkEvents('B')

    config.installExport = {'load fb_1;', 'fb_'}
    expect('INFO     TEST (main): Installing DCS Control API User callbacks')
    expect('DCS.setUserCallbacks')
    expect('Updated Export.lua')
    initDCSPlug(config)
    checkFile(exportLua, {'load fa_1;', 'load fb_1;'})
    checkFile(exportLuaBackup1, {'load fa_1;'})
    if (fileExists(exportLuaBackup2) or fileExists(exportLuaBackup3)) then
        reportError('Export.lua backup not expected')
    end
    checkEvents('C')

    config.installExport = {'load fc_1;', 'fc_'}
    expect('INFO     TEST (main): Installing DCS Control API User callbacks')
    expect('DCS.setUserCallbacks')
    expect('Updated Export.lua')
    initDCSPlug(config)
    checkFile(exportLua, {'load fa_1;', 'load fb_1;', 'load fc_1;'})
    checkFile(exportLuaBackup2, {'load fa_1;', 'load fb_1;'})
    checkFile(exportLuaBackup1, {'load fa_1;'})
    if (fileExists(exportLuaBackup3)) then
        reportError('Export.lua backup not expected')
    end
    checkEvents('D')

    config.installExport = {'load fb_2;', 'fb_'}
    expect('INFO     TEST (main): Installing DCS Control API User callbacks')
    expect('DCS.setUserCallbacks')
    expect('Updated Export.lua')
    initDCSPlug(config)
    checkFile(exportLua, {'load fa_1;', 'load fb_2;', 'load fc_1;'})
    checkFile(exportLuaBackup3, {'load fa_1;', 'load fb_1;', 'load fc_1;'})
    checkFile(exportLuaBackup2, {'load fa_1;', 'load fb_1;'})
    checkFile(exportLuaBackup1, {'load fa_1;'})
    checkEvents('E')

    removeExportLuaBackupFiles()

    config.installExport = {'load fa_1;', 'xx'}
    expect('INFO     TEST (main): Installing DCS Control API User callbacks')
    expect('DCS.setUserCallbacks')
    initDCSPlug(config)
    checkFile(exportLua, {'load fa_1;', 'load fb_2;', 'load fc_1;'})
    if (fileExists(exportLuaBackup1 or fileExists(exportLuaBackup2) or fileExists(exportLuaBackup3))) then
        reportError('Export.lua backup not expected')
    end
    checkEvents('F')

    config.installExport = {'load fa_1;', 'load'}
    expect('INFO     TEST (main): Installing DCS Control API User callbacks')
    expect('DCS.setUserCallbacks')
    initDCSPlug(config)
    checkFile(exportLua, {'load fa_1;', 'load fb_2;', 'load fc_1;'})
    if (fileExists(exportLuaBackup1 or fileExists(exportLuaBackup2) or fileExists(exportLuaBackup3))) then
        reportError('Export.lua backup not expected')
    end
    checkEvents('G')

    removeExportLuaBackupFiles()

    local fin = _open(exportLua, 'w')
    fin:write('load fa_3\nload fb_3\nload fa_3\nload fc_3\nload fa_3')
    _close(fin)

    config.installExport = {'load fa_3', 'xxx'}
    expect('INFO     TEST (main): Installing DCS Control API User callbacks')
    expect('DCS.setUserCallbacks')
    expect('Updated Export.lua')
    initDCSPlug(config)
    checkFile(exportLua, {'load fa_3', 'load fb_3', 'load fc_3'})
    checkEvents('H')

    removeExportLuaBackupFiles()

    fin = _open(exportLua, 'w')
    fin:write('load fa_3\nload fb_4\nload fc_3\nload fd_4\nload fe_3')
    _close(fin)

    config.installExport = {'load fx_1', '_4'}
    expect('INFO     TEST (main): Installing DCS Control API User callbacks')
    expect('DCS.setUserCallbacks')
    expect('Updated Export.lua')
    initDCSPlug(config)
    checkFile(exportLua, {'load fa_3', 'load fx_1', 'load fc_3', 'load fe_3'})
    checkEvents('I')

    removeExportLuaBackupFiles()

    config.installExport = {'load fx_1', '_3'}
    expect('INFO     TEST (main): Installing DCS Control API User callbacks')
    expect('DCS.setUserCallbacks')
    initDCSPlug(config)
    checkFile(exportLua, {'load fa_3', 'load fx_1', 'load fc_3', 'load fe_3'})
    checkEvents('J')

    removeExportLuaBackupFiles()

    config.installExport = {'load fy_1'}
    expect('INFO     TEST (main): Installing DCS Control API User callbacks')
    expect('DCS.setUserCallbacks')
    expect('Updated Export.lua')
    initDCSPlug(config)
    checkFile(exportLua, {'load fa_3', 'load fx_1', 'load fc_3', 'load fe_3', 'load fy_1'})
    checkEvents('K')

    _remove(exportLua)
    removeExportLuaBackupFiles()

end }