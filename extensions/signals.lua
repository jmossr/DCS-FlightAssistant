--[[------
    --FlightAssistant
    --Signals, Signal groups and Signal sequences
--------]]
local tinsert = table.insert
local type = type
local error = error
local osclock = os.clock
local pairs = pairs
local sformat = string.format
local flightAssistant = ...
local builderLib = flightAssistant.requireExtension('builder')
local createBuilder = builderLib.createBuilder
local isDebugEnabled = flightAssistant.isDebugEnabled
local isDebugUnitEnabled = flightAssistant.isDebugUnitEnabled
local fire = flightAssistant.fire
local fmtInfo = flightAssistant.fmtInfo
local fmtWarning = flightAssistant.fmtWarning
local indexOf = flightAssistant.indexOf
local listAddOnce = flightAssistant.listAddOnce

--[[------
    --Signal
--------]]
local function updateSequences(pUnit, signal)
    local signalGroup = pUnit.signalGroupPerSignal[signal]
    if signalGroup then
        local sequences = signalGroup.sequences
        local n = #sequences
        local sequence
        for i = 1, n do
            sequence = sequences[i]
            sequence:fire(signal)
        end
    end
end

local function sFire(self)
    if not self.firing then
        if isDebugEnabled then
            fmtInfo('firing %s', self.name)
        end
        self.firing = true
        local signal = self.signal
        fire(self.observers, signal)
        updateSequences(self.pUnit, signal)
        self.firing = false
    end
end

local function getOrCreateSignal(pUnit, signal)
    local s = pUnit.signals[signal]
    if not s then
        s = { pUnit = pUnit, name = "signal '" .. signal .. "'", signal = signal, observers = {}, fire = sFire }
        pUnit.signals[signal] = s
    end
    return s
end

local function fireSignal(pUnit, signal)
    local s = pUnit.signals[signal]
    if s then
        s:fire()
    else
        updateSequences(pUnit, signal)
    end
end

--[[------
    --Signal groups and Signal sequences
--------]]
local function checkAppendSignalArgs(builder, actionName, signal1, signal2, signal3, signal4, rem)
    if type(signal1) ~= 'string' then
        builder:close()
        error(sformat('%s(signal1, signal2, signal3, signal4) \'signal%s\' must be a string, not a %s', actionName, 1, type(signal1)), 3)
    end
    if signal2 then
        if type(signal2) ~= 'string' then
            builder:close()
            error(sformat('%s(signal1, signal2, signal3, signal4) \'signal%s\' must be a string, not a %s', actionName, 2, type(signal2)), 3)
        end
        if signal3 then
            if type(signal3) ~= 'string' then
                builder:close()
                error(sformat('%s(signal1, signal2, signal3, signal4) \'signal%s\' must be a string, not a %s', actionName, 3, type(signal3)), 3)
            end
            if signal4 then
                if type(signal4) ~= 'string' then
                    builder:close()
                    error(sformat('%s(signal1, signal2, signal3, signal4) \'signal%s\' must be a string, not a %s', actionName, 4, type(signal4)), 3)
                end
                if rem then
                    builder:close()
                    error(sformat('%s(signal1, signal2, signal3, signal4) can only take up to 4 signals. To add more signals, call .plus(s1, s2, s3, s4) as many times as necessary.'), 3)
                end
            end
        end
    end
end

local function addAppendSignalsAction(builder, actionName, appendf)
    local proxy = builder.proxy
    if not proxy then
        proxy = {}
        builder.proxy = proxy
    end
    local append = function(signal1, signal2, signal3, signal4)
        appendf(builder, signal1)
        if signal2 then
            appendf(builder, signal2)
            if signal3 then
                appendf(builder, signal3)
                if signal4 then
                    appendf(builder, signal4)
                end
            end
        end
        return proxy
    end
    if isDebugUnitEnabled then
        proxy[actionName] = function(signal1, signal2, signal3, signal4, rem)
            checkAppendSignalArgs(builder, actionName, signal1, signal2, signal3, signal4, rem)
            return append(signal1, signal2, signal3, signal4)
        end
    else
        proxy[actionName] = append
    end
end

--[[------
  --Signal sequence
------]]--
local function checkSignalSequence(sequence, signal)
    if not sequence.disabled then
        local timestamp = osclock()
        if sequence.index > 1 and (timestamp - sequence.startTime) > sequence.within then
            if isDebugEnabled then
                fmtInfo('%s timed out', sequence.name)
            end
            sequence.index = 1
        end
        local expecting = sequence.signals[sequence.index]
        if signal == expecting then
            sequence.index = sequence.index + 1
        elseif signal == sequence.signals[1] then
            sequence.index = 2
        else
            sequence.index = 1
        end
        if sequence.index > sequence.len then
            sequence.index = 1
            if isDebugEnabled then
                fmtInfo('%s completed', sequence.name)
            end
            fire(sequence.observers, sequence.name, nil)
        else
            if sequence.index == 2 then
                sequence.startTime = osclock()
            end
            if isDebugEnabled then
                fmtInfo("%s length %i, expecting '%s', received '%s', new index %i", sequence.name, sequence.len, expecting, signal, sequence.index)
            end
        end
    end
end

local function onCloseSignalSequenceBuilder(builder)
    if not builder.within then
        fmtWarning('%s was not completed an will be discarded. To complete a signal sequence, .within(seconds) must be called.', builder.name)
    end
end
local function createSignalSequence(builder)
    local signalList = builder.signals
    local len = #signalList
    builder.len = len
    local pUnit = builder.pUnit
    pUnit.sequences[builder.sequenceName] = builder
    if isDebugEnabled then
        fmtInfo('%s created with %s signals', builder.name, len)
    end
    local signalGroupPerSignal = pUnit.signalGroupPerSignal
    local signal
    local signalGroup
    for i = 1, len do
        signal = signalList[i]
        signalGroup = signalGroupPerSignal[signal]
        if signalGroup then
            listAddOnce(signalGroup.sequences, builder)
        else
            error(sformat('signal \'%s\', used in signal sequence \'%s\', must be part of a signal group', signal, builder.sequenceName))
        end
    end
end
local function appendToSignalSequence(builder, signal)
    tinsert(builder.signals, signal)
    local proxy = builder.proxy
    if proxy.forSignals then
        proxy.forSignals = nil
        addAppendSignalsAction(builder, 'plus', appendToSignalSequence)
    end
    if #builder.signals > 1 and not builder.within then
        if isDebugUnitEnabled then
            proxy.within = function(seconds)
                if type(seconds) ~= 'number' then
                    builder:close()
                    error('within(seconds) \'seconds\' must be a positive number, not a ' .. type(seconds), 2)
                end
                if seconds <= 0 then
                    builder:close()
                    error('within(seconds) \'seconds\' must be a positive number, not  ' .. seconds, 2)
                end
                builder.within = seconds
                return builder:build()
            end
        else
            proxy.within = function(seconds)
                builder.within = seconds
                return builder:build()
            end
        end
    end
    return proxy
end
local function createSignalSequenceBuilder(pUnit, name)
    local builder = createBuilder(pUnit, 'signal sequence \'' .. name .. '\'', createSignalSequence, onCloseSignalSequenceBuilder, false)
    builder.signals = {}
    builder.sequenceName = name
    builder.index = 1
    builder.startTime = 0
    builder.observers = {}
    builder.fire = checkSignalSequence
    addAppendSignalsAction(builder, 'forSignals', appendToSignalSequence)
    return builder
end
local function buildOnSignalSequenceAction(builder)
    builder:addBuilderAction(builder.pUnit.sequences[builder.sequenceName].observers)
end
local function createOnSignalSequenceBuilder(pUnit, name)
    local builder = createBuilder(pUnit, 'onSignalSequence(' .. name .. ')', buildOnSignalSequenceAction, nil, true)
    builder.sequenceName = name
    return builder
end

--[[------
  --Signal group
------]]--
local function registerSignalInGroup(group, signal)
    local pUnit = group.pUnit
    local sequences = pUnit.sequences
    local signalGroupPerSignal = pUnit.signalGroupPerSignal

    if signalGroupPerSignal[signal] then
        if signalGroupPerSignal[signal] ~= group.groupName then
            fmtWarning('signal \'%s\' is a member of signal group: \'%s\' and will not be added to group \'%s\'', signal, signalGroupPerSignal[signal], group.groupName)
        end
    else
        signalGroupPerSignal[signal] = group
        tinsert(group.signalSet, signal)
        for _, seq in pairs(sequences) do
            if indexOf(seq.signals, signal) > 0 then
                listAddOnce(group.sequences, seq)
            end
        end
    end
end
local function onCloseBuildSignalGroup(group)
    if group.pUnit.signalGroups[group.groupName] == group then
        if isDebugEnabled then
            fmtInfo('signal group \'%s\' defined with %s signals', group.groupName, #group.signalSet)
        end
    else
        fmtWarning('Signal group \'%s\' was not completed an will be discarded. To complete a signal group, at least one signal must be added.', group.groupName)
    end
end
local function appendToSignalGroup(group, signal)
    group.pUnit.signalGroups[group.groupName] = group
    if group.proxy and group.proxy.forSignals then
        group.proxy.forSignals = nil
        addAppendSignalsAction(group, 'plus', appendToSignalGroup)
    end
    registerSignalInGroup(group, signal)
    return group.proxy
end
local function createSignalGroupBuilder(pUnit, name)
    if type(name) ~= 'string' then
        error(sformat('defineSignalGroup(name) \'name\' must be a string, not a %s', type(name)), 2)
    end
    if pUnit.signalGroups[name] then
        error(sformat('defineSignalGroup: a signal group with name \'%s\' already exists', name), 2)
    end
    local group = createBuilder(pUnit, 'signal group \'' .. name .. "'", createSignalSequence, onCloseBuildSignalGroup, false)
    group.groupName = name
    group.signalSet = {}
    group.sequences = {}
    addAppendSignalsAction(group, 'forSignals', appendToSignalGroup)
    return group
end

--[[------
  --fireSignal action builder extension
------]]--
do
    local function buildWithSignalAction(builder, signal)
        local actionId = 'fireSignal(' .. signal .. ')'
        local pUnit = builder.pUnit
        builder.actionId = actionId
        builder.buildActionCb = function()
            return getOrCreateSignal(pUnit, signal)
        end
        return builder:build()
    end
    local function prepareProxy(builder, proxy)
        if isDebugUnitEnabled then
            proxy.fireSignal = function(signal)
                if type(signal) ~= 'string' then
                    builder:close()
                    error('.signal(signal) \'signal\' must be a string not a ' .. type(signal), 2)
                end
                return buildWithSignalAction(builder, signal)
            end
        else
            proxy.fireSignal = function(signal)
                return buildWithSignalAction(builder, signal)
            end
        end
    end

    builderLib.addBuilderExtension(prepareProxy)
end
--[[------
  --PUnit extension
------]]--
local function initPUnit(pUnit, proxy)
    if not pUnit.signals then
        pUnit.signals = {}
        pUnit.sequences = {}
        pUnit.signalGroups = {}
        pUnit.signalGroupPerSignal = {}

        if isDebugUnitEnabled then
            proxy.fireSignal = function(signal)
                if type(signal) ~= 'string' then
                    error('fireSignal(signal) \'signal\' must be a string, not a ' .. type(signal), 2)
                end
                return fireSignal(pUnit, signal)
            end
            proxy.onSignal = function(signal, f)
                if type(signal) ~= 'string' then
                    error('onSignal(signal) \'signal\' must be a string, not a ' .. type(signal), 2)
                end
                local bproxy = createBuilder(pUnit, 'onSignal(' .. signal .. ')', function(builder)
                    builder:addBuilderAction(getOrCreateSignal(builder.pUnit, signal).observers);
                end, nil, true).proxy
                if type(f) == 'function' then
                    return bproxy.call(f)
                else
                    return bproxy
                end
            end
            proxy.defineSignalSequence = function(sequenceName)
                if type(sequenceName) ~= 'string' then
                    error(sformat('defineSignalSequence(name) \'name\' must be a string, not a %s', type(sequenceName)), 2)
                end
                if pUnit.sequences[sequenceName] then
                    error(sformat('defineSignalSequence: a signal sequence with name \'%s\' already exists', sequenceName), 2)
                end
                return createSignalSequenceBuilder(pUnit, sequenceName).proxy
            end
            proxy.onSignalSequence = function(sequenceName, f)
                if not pUnit.sequences[sequenceName] then
                    error('onSignalSequence(name): No existing signal sequence with name \'' .. sequenceName .. '\' was found.', 2)
                end
                local bproxy = createOnSignalSequenceBuilder(pUnit, sequenceName).proxy
                if type(f) == 'function' then
                    return bproxy.call(f)
                else
                    return bproxy
                end
            end
            proxy.defineSignalGroup = function(groupName)
                if type(groupName) ~= 'string' then
                    error('defineSignalGroup(name) \'name\' must be a string, not a ' .. type(groupName), 2)
                end
                if pUnit.signalGroups[groupName] then
                    error('defineSignalGroup(name): A signal group with name \'' .. groupName .. '\' already exists', 2)
                end
                return createSignalGroupBuilder(pUnit, groupName).proxy
            end
        else
            proxy.fireSignal = function(signal)
                return fireSignal(pUnit, signal)
            end
            proxy.onSignal = function(signal, f)
                local bproxy = createBuilder(pUnit, 'onSignal(' .. signal .. ')', function(builder)
                    builder:addBuilderAction(getOrCreateSignal(builder.pUnit, signal).observers);
                end, nil, true).proxy
                if type(f) == 'function' then
                    return bproxy.call(f)
                else
                    return bproxy
                end
            end
            proxy.defineSignalSequence = function(sequenceName)
                return createSignalSequenceBuilder(pUnit, sequenceName).proxy
            end
            proxy.onSignalSequence = function(sequenceName, f)
                local bproxy = createOnSignalSequenceBuilder(pUnit, sequenceName).proxy
                if type(f) == 'function' then
                    return bproxy.call(f)
                else
                    return bproxy
                end
            end
            proxy.defineSignalGroup = function(groupName)
                return createSignalGroupBuilder(pUnit, groupName).proxy
            end
        end
    end
end

return {
    initPUnit = initPUnit,
    fireSignal = fireSignal,
}