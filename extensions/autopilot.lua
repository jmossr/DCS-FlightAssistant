local flightAssistant = getfenv(1)
local isSimulationPaused = flightAssistant.isSimulationPaused
local fmtInfo = flightAssistant.fmtInfo
local isDebugEnabled = flightAssistant.isDebugEnabled

local LoGetModelTime = LoGetModelTime or Export.LoGetModelTime
local LoGetADIPitchBankYaw = LoGetADIPitchBankYaw or Export.LoGetADIPitchBankYaw
local LoGetIndicatedAirSpeed = LoGetIndicatedAirSpeed or Export.LoGetIndicatedAirSpeed
local LoSetCommand = LoSetCommand or Export.LoSetCommand
local LoGetAngleOfSideSlip = LoGetAngleOfSideSlip or Export.LoGetAngleOfSideSlip
local LoGetVerticalVelocity = LoGetVerticalVelocity or Export.LoGetVerticalVelocity

local MODE_LEVEL = 1
local MODE_BANK = 2
local MODE_CUSTOM = 3

local function limitValueChangeSpeed(currentValue, targetValue, maxChangePerSecond, deltaTime)
    local maxDeltaOutput = deltaTime * maxChangePerSecond
    local outputLimLow = currentValue - maxDeltaOutput
    local outputLimHigh = currentValue + maxDeltaOutput
    return (targetValue < outputLimLow and outputLimLow) or (targetValue > outputLimHigh and outputLimHigh) or targetValue
end

local function createPitchSpeedOverrideControl(pitchControl, minimumSpeed, maxPitchChangePerSecond, errorP, vvErrorP)
    local minimumIndicatedSpeed = minimumSpeed or 70
    local pitchUpSpeed = minimumIndicatedSpeed * 1.3
    local baseControl = pitchControl
    local indicatedSpeed
    local error
    local overrideActive
    local requestedPitch = pitchControl.getTarget()
    local targetPitch
    local referencePitch
    local speedP = errorP or 0.1
    local vvP = vvErrorP or 0.001
    local vvReferencePitch
    local maxTargetChangePerSecond = maxPitchChangePerSecond or 0.03

    local function setTarget(pitch)
        requestedPitch = pitch;
    end

    local function process(pitch, deltaTime, stateTable)
        indicatedSpeed = stateTable.indicatedSpeed
        error = indicatedSpeed - minimumIndicatedSpeed
        if error < 0 then
            if not overrideActive then
                overrideActive = true
                referencePitch = stateTable.pitch
                vvReferencePitch = nil
            end
            targetPitch = referencePitch + error * speedP
        elseif overrideActive then
            if indicatedSpeed > pitchUpSpeed then
                targetPitch = limitValueChangeSpeed(targetPitch, requestedPitch, maxTargetChangePerSecond, deltaTime)
            else
                if not vvReferencePitch then
                    vvReferencePitch = targetPitch
                end
                targetPitch = limitValueChangeSpeed(targetPitch, vvReferencePitch - stateTable.verticalVelocity * vvP, maxTargetChangePerSecond, deltaTime)
            end
            if targetPitch >= requestedPitch then
                overrideActive = false
                targetPitch = requestedPitch
            end
        else
            targetPitch = requestedPitch
        end
        baseControl.setTarget(targetPitch)
        return baseControl.process(pitch, deltaTime)
    end
    return {
        process = process,
        setTarget = setTarget,
        reset = baseControl.reset
    }
end
local function createAutopilot(minSampleTime, altitudeControl, pitchControl, bankControl, rudderControl)
    local maxSampleTime = minSampleTime * 50
    local lastSampleTime = 0
    local lastLogTime = 0
    local time, deltaTime
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
    local stateTable = { selfData = nil, pitch = 0, bank = 0, yaw = 0, sideSlipAngle = 0, verticalVelocity = 0, indicatedSpeed = 0 }

    local function prepareStateTable(selfData)
        stateTable.selfData = selfData
        stateTable.pitch, stateTable.bank, stateTable.yaw = LoGetADIPitchBankYaw()
        stateTable.sideSlipAngle = LoGetAngleOfSideSlip()
        stateTable.verticalVelocity = LoGetVerticalVelocity()
        stateTable.indicatedSpeed = LoGetIndicatedAirSpeed()
    end

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
            if isDebugEnabled and (time - lastLogTime > 5) then
                lastLogTime = time
                fmtInfo('autopilot active')
            end

            deltaTime = time - lastSampleTime
            if deltaTime > maxSampleTime or deltaTime < 0 then
                lastSampleTime = time
            elseif deltaTime > minSampleTime then
                lastSampleTime = time
                prepareStateTable(selfData, deltaTime)
                if processAltitude then
                    setPitchTarget(processAltitude(selfData.Position.y, deltaTime, stateTable))
                end
                pitchInput = processPitch(stateTable.pitch, deltaTime, stateTable)
                rollInput = processBank(stateTable.bank, deltaTime, stateTable)
                LoSetCommand(2001, pitchInput)
                LoSetCommand(2002, rollInput)
                if processSideSlip then
                    rudderInput = processSideSlip(stateTable.sideSlipAngle, deltaTime, stateTable)
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
                if isDebugEnabled then
                    fmtInfo('autopilot engage')
                end
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
            if modeSwitched then
                if isDebugEnabled then
                    fmtInfo('autopilot engage level flight')
                end
                reset()
                setBankTarget(0)
                setPitchTarget(0.05)
            end
            setAltitudeTarget(selfData.Position.y)
            mode = MODE_LEVEL
            return modeSwitched
        end,
        engageLevelBank = function(selfData)
            local modeSwitched = mode ~= MODE_BANK
            if modeSwitched then
                if isDebugEnabled then
                    fmtInfo('autopilot engage bank hold')
                end
                reset()
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
            if modeSwitched and isDebugEnabled then
                fmtInfo('autopilot disengage')
            end
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
    proxy.createPitchSpeedOverrideControl = createPitchSpeedOverrideControl
end

return { initPUnit = initPUnit }