local flightAssistant = ...
local isSimulationPaused = flightAssistant.isSimulationPaused

local LoGetModelTime = Export.LoGetModelTime
local LoGetADIPitchBankYaw = Export.LoGetADIPitchBankYaw
local LoSetCommand = Export.LoSetCommand
local LoGetAngleOfSideSlip = Export.LoGetAngleOfSideSlip

local function createAutopilot(minSampleTime, altitudeControl, pitchControl, bankControl, rudderControl)
    local maxSampleTime = minSampleTime * 50
    local lastSampleTime = 0
    local time, deltaTime
    local pitch, bank
    local pitchInput, rollInput, rudderInput
    local processAltitude = altitudeControl and altitudeControl.process
    local setPitchTarget = pitchControl.setTarget
    local processPitch = pitchControl.process
    local resetPitchControl = pitchControl.reset
    local processBank = bankControl.process
    local resetBankControl = bankControl.reset
    local processSideSlip = rudderControl and rudderControl.process
    local resetRudderControl = rudderControl and rudderControl.reset
    local engaged

    local function reset()
        lastSampleTime = 0
        resetPitchControl()
        resetBankControl()
        if resetRudderControl then
            resetRudderControl()
        end
    end

    local function fly(selfData)
        if engaged and not isSimulationPaused() then
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
            if not engaged then
                reset()
                engaged = true
            end
        end,
        disengage = function()
            engaged = nil
        end,
        isEngaged = function()
            return engaged
        end
    }
end

local function initPUnit(_, proxy)
    proxy.createAutopilot = createAutopilot
end

return { initPUnit = initPUnit }