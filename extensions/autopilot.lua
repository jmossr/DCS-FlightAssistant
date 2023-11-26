local flightAssistant = ...
local isSimulationPaused = flightAssistant.isSimulationPaused

local LoGetModelTime = Export.LoGetModelTime
local LoGetADIPitchBankYaw = Export.LoGetADIPitchBankYaw
local LoSetCommand = Export.LoSetCommand
local LoGetAngleOfSideSlip = Export.LoGetAngleOfSideSlip

local MODE_LEVEL = 1
local MODE_BANK = 2
local MODE_CUSTOM = 3

local function createAutopilot(minSampleTime, altitudeControl, pitchControl, bankControl, rudderControl)
    local maxSampleTime = minSampleTime * 50
    local lastSampleTime = 0
    local time, deltaTime
    local pitch, bank
    local pitchInput, rollInput, rudderInput
    local setAltitudeTarget = altitudeControl and altitudeControl.setTarget
    local processAltitude = altitudeControl and altitudeControl.process
    local setPitchTarget = pitchControl.setTarget
    local processPitch = pitchControl.process
    local resetPitchControl = pitchControl.reset
    local setBankTarget = bankControl.setTarget
    local processBank = bankControl.process
    local resetBankControl = bankControl.reset
    local processSideSlip = rudderControl and rudderControl.process
    local resetRudderControl = rudderControl and rudderControl.reset
    local mode

    local function reset()
        lastSampleTime = 0
        resetPitchControl()
        resetBankControl()
        if resetRudderControl then
            resetRudderControl()
        end
    end

    local function fly(selfData)
        if mode and not isSimulationPaused() then
            time = LoGetModelTime()
            deltaTime = time - lastSampleTime
            if deltaTime > maxSampleTime then
                lastSampleTime = time
            elseif deltaTime > minSampleTime then
                lastSampleTime = time
                pitch, bank, _ = LoGetADIPitchBankYaw()
                if processAltitude then
                    setPitchTarget(processAltitude(selfData.Position.y, deltaTime))
                end
                pitchInput = processPitch(pitch, deltaTime)
                rollInput = processBank(bank, deltaTime)
                LoSetCommand(2001, pitchInput)
                LoSetCommand(2002, rollInput)
                if processSideSlip then
                    rudderInput = processSideSlip(LoGetAngleOfSideSlip(), deltaTime)
                    LoSetCommand(2003, rudderInput)
                end
            else
                LoSetCommand(2001, pitchInput)
                LoSetCommand(2002, rollInput)
                if processSideSlip then
                    LoSetCommand(2003, rudderInput)
                end
            end
        end
    end
    return {
        fly = fly,
        engage = function()
            if not mode then
                reset()
                mode = MODE_CUSTOM
                return true
            else
                return false
            end
        end,
        setBankTarget = setBankTarget,
        setPitchTarget = setPitchTarget,
        setAltitudeTarget = setAltitudeTarget,
        engageLevelFlight = function(selfData)
            local modeSwitched = mode ~= MODE_LEVEL
            setBankTarget(0)
            setPitchTarget(0.05)
            setAltitudeTarget(selfData.Position.y)
            mode = MODE_LEVEL
            return modeSwitched
        end,
        engageLevelBank = function(selfData)
            local modeSwitched = mode ~= MODE_BANK
            if modeSwitched then
                local _, currentBankAngle = LoGetADIPitchBankYaw()
                setBankTarget(currentBankAngle)
                setPitchTarget(0.05)
                mode = MODE_BANK
            end
            setAltitudeTarget(selfData.Position.y)
            return modeSwitched
        end,
        disengage = function()
            local modeSwitched = mode and true or false
            mode = nil
            return modeSwitched
        end,
        isEngaged = function()
            return mode and true or false
        end
    }
end

local function initPUnit(_, proxy)
    proxy.createAutopilot = createAutopilot
end

return { initPUnit = initPUnit }