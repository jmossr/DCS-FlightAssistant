local flightAssistantCore = ...
local isDebugEnabled = flightAssistantCore.config.isDebugEnabled
local type = type
local tinsert = table.insert
local pairs = pairs
local fmtInfo = flightAssistantCore.logger.fmtInfo
local fmtWarning = flightAssistantCore.logger.fmtWarning
local loadLua = flightAssistantCore.loadLua
local extensionsDir = flightAssistantCore.extensionsDir

--[[------
    --Extension support
--------]]
local INIT_ASSISTANT = 'initAssistant'
local INIT_PUNIT = 'initPUnit'
local BEFORE_PUNIT_ACTIVATION = 'beforePUnitActivation'
local AFTER_PUNIT_ACTIVATION = 'afterPUnitActivation'
local BEFORE_PUNIT_DEACTIVATION = 'beforePUnitDeactivation'
local AFTER_PUNIT_DEACTIVATION = 'afterPUnitDeactivation'
local BEFORE_SIMULATION_FRAME = 'beforeSimulationFrame'
local AFTER_SIMULATION_FRAME = 'afterSimulationFrame'
local extensionEvents = { INIT_ASSISTANT,
                          INIT_PUNIT, BEFORE_PUNIT_ACTIVATION, AFTER_PUNIT_ACTIVATION,
                          BEFORE_PUNIT_DEACTIVATION, AFTER_PUNIT_DEACTIVATION,
                          BEFORE_SIMULATION_FRAME, AFTER_SIMULATION_FRAME }
local extensions = {}
local function addExtensionFunction(libName, lib, functionName)
    local f = lib[functionName]
    if f and type(f) ~= 'function' then
        fmtWarning("Ignoring %s.%s: it is a %s instead of a function.", libName, functionName, type(f))
    elseif f then
        if isDebugEnabled then
            fmtInfo("Registering extension function %s.%s", libName, functionName)
        end
        if not extensions[functionName] then
            extensions[functionName] = { f }
        else
            tinsert(extensions[functionName], f)
        end
    end
end
local function callExtensionFunctions(functions, p1, p2)
    if functions then
        for _, f in pairs(functions) do
            f(p1, p2)
        end
    end
end
local function initAssistant(assistantSelf, configTable)
    callExtensionFunctions(extensions.initAssistant, assistantSelf, configTable)
end
local function initPUnit(pUnit, proxy)
    callExtensionFunctions(extensions.initPUnit, pUnit, proxy)
end
local function beforePUnitActivation(pUnit)
    callExtensionFunctions(extensions.beforePUnitActivation, pUnit)
end
local function afterPUnitActivation(pUnit)
    callExtensionFunctions(extensions.afterPUnitActivation, pUnit)
end
local function beforePUnitDeactivation(pUnit)
    callExtensionFunctions(extensions.beforePUnitDeactivation, pUnit)
end
local function afterPUnitDeactivation(pUnit)
    callExtensionFunctions(extensions.afterPUnitDeactivation, pUnit)
end
local function beforeSimulationFrame(pUnit)
    callExtensionFunctions(extensions.beforeSimulationFrame, pUnit)
end
local function afterSimulationFrame(pUnit)
    callExtensionFunctions(extensions.afterSimulationFrame, pUnit)
end
--[[------
    --Extension libs
--------]]
local libs = {}

--[[------
    --Extension import functions
--------]]
local function requireExtensionLib(name, path)
    local lib = libs[path]
    if not lib then
        lib = loadLua(path, nil, flightAssistantCore)
        libs[path] = lib
        for _, event in pairs(extensionEvents) do
            addExtensionFunction(name, lib, event)
        end
    end
    return lib
end
local function requireExtension(name)
    return requireExtensionLib(name, extensionsDir .. name .. '.lua', true)
end
local function getOptionalExtension(name)
    return libs[extensionsDir .. name .. '.lua']
end

return {
    initAssistant = initAssistant,
    initPUnit = initPUnit,
    beforePUnitActivation = beforePUnitActivation,
    afterPUnitActivation = afterPUnitActivation,
    beforeSimulationFrame = beforeSimulationFrame,
    afterSimulationFrame = afterSimulationFrame,
    beforePUnitDeactivation = beforePUnitDeactivation,
    afterPUnitDeactivation = afterPUnitDeactivation,
    requireExtension = requireExtension,
    getOptionalExtension = getOptionalExtension,
}