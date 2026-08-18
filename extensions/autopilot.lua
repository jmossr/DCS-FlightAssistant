local flightAssistantCore = ...
local isSimulationPaused = flightAssistantCore.simulation.isPaused
local fmtInfo = flightAssistantCore.logger.fmtInfo
local isDebugEnabled = flightAssistantCore.config.isDebugEnabled

local LoGetModelTime = LoGetModelTime or Export.LoGetModelTime
local LoGetADIPitchBankYaw = LoGetADIPitchBankYaw or Export.LoGetADIPitchBankYaw
local LoGetIndicatedAirSpeed = LoGetIndicatedAirSpeed or Export.LoGetIndicatedAirSpeed
local LoSetCommand = LoSetCommand or Export.LoSetCommand
local LoGetVerticalVelocity = LoGetVerticalVelocity or Export.LoGetVerticalVelocity

local MODE_LEVEL = 1
local MODE_BANK = 2
local MODE_HEADING = 4
local MODE_CUSTOM = 3

local function limitValueChangeSpeed(currentValue, targetValue, maxChangePerSecond, deltaTime)
    local maxDeltaOutput = deltaTime * maxChangePerSecond
    local outputLimLow = currentValue - maxDeltaOutput
    local outputLimHigh = currentValue + maxDeltaOutput
    return (targetValue < outputLimLow and outputLimLow) or (targetValue > outputLimHigh and outputLimHigh) or targetValue
end

local function headingError(current, target)
    local err = target - current
    if err > math.pi then
        err = err - 2 * math.pi
    elseif err < -math.pi then
        err = err + 2 * math.pi
    end
    return err
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
local function createAutopilot(minSampleTime, altitudeControl, pitchControl, bankControl, headingControl, rudderControl)
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
    local processHeading = headingControl and headingControl.process
    local setHeadingTarget = headingControl and headingControl.setTarget
    local resetHeadingControl = headingControl and headingControl.reset
    local processSideSlip = rudderControl and rudderControl.process
    local resetRudderControl = rudderControl and rudderControl.reset
    local mode
    local desiredHeading = 0
    local headingCaptured = false
    local stateTable = { selfData = nil, pitch = 0, bank = 0, yaw = 0, heading = 0, sideSlipAngle = 0, verticalVelocity = 0, indicatedSpeed = 0 }

    -- LoGetAngleOfSideSlip() returns bogus values on some aircraft (observed ~-7.7 rad on the
    -- Mosquito; max aerodynamic sideslip is ±π/2). Compute sideslip from consecutive Position
    -- samples instead: slip = heading - track (velocity vector direction).
    -- DCS world frame: x=north, y=up, z=east. Heading 0=north, increasing clockwise.
    local prevPosX, prevPosZ, lastSlip
    local function computeSideSlip(selfData)
        local pos = selfData and selfData.Position
        if pos then
            local px, pz = pos.x, pos.z
            if prevPosX ~= nil then
                local dx = px - prevPosX
                local dz = pz - prevPosZ
                local dist = math.sqrt(dx * dx + dz * dz)
                if dist > 1 then
                    prevPosX = px
                    prevPosZ = pz
                    local track = math.atan2(dz, dx)
                    local slip = selfData.Heading - track
                    if slip > math.pi then slip = slip - 2 * math.pi end
                    if slip < -math.pi then slip = slip + 2 * math.pi end
                    lastSlip = slip
                end
            else
                prevPosX = px
                prevPosZ = pz
            end
        end
        return lastSlip or 0
    end

    local function prepareStateTable(selfData)
        stateTable.selfData = selfData
        stateTable.pitch, stateTable.bank, stateTable.yaw = LoGetADIPitchBankYaw()
        stateTable.heading = selfData and selfData.Heading or 0
        stateTable.sideSlipAngle = computeSideSlip(selfData)
        stateTable.verticalVelocity = LoGetVerticalVelocity()
        stateTable.indicatedSpeed = LoGetIndicatedAirSpeed()
    end

    local function reset()
        lastSampleTime = 0
        prevPosX = nil
        prevPosZ = nil
        lastSlip = nil
        resetPitchControl()
        resetBankControl()
        if resetHeadingControl then
            resetHeadingControl()
        end
        if resetRudderControl then
            resetRudderControl()
        end
        headingCaptured = false
    end

    local function fly(selfData)
        if mode and not isSimulationPaused() then
            time = LoGetModelTime()
            if isDebugEnabled and (time - lastLogTime > 2) then
                lastLogTime = time
                if mode == MODE_HEADING then
                    fmtInfo('AP hdg: bank=%.1f° hdgErr=%.1f° slip=%.4f rad rudder=%.4f',
                        math.deg(stateTable.bank),
                        math.deg(headingError(stateTable.heading, desiredHeading)),
                        stateTable.sideSlipAngle,
                        rudderInput or 0)
                else
                    fmtInfo('AP active: mode=%s bank=%.1f° pitch=%.1f°',
                        tostring(mode), math.deg(stateTable.bank), math.deg(stateTable.pitch))
                end
            end

            deltaTime = time - lastSampleTime
            if deltaTime > maxSampleTime or deltaTime < 0 then
                lastSampleTime = time
            elseif deltaTime > minSampleTime then
                lastSampleTime = time
                prepareStateTable(selfData)

                if processAltitude then
                    setPitchTarget(processAltitude(selfData.Position.y, deltaTime, stateTable))
                end

                if processHeading and mode == MODE_HEADING then
                    if not headingCaptured then
                        desiredHeading = stateTable.heading
                        headingCaptured = true
                    end
                    local hdgErr = headingError(stateTable.heading, desiredHeading)
                    local bankCmd = -processHeading(hdgErr, deltaTime, stateTable)
                    setBankTarget(bankCmd)
                end

                pitchInput = processPitch(stateTable.pitch, deltaTime, stateTable)
                rollInput = processBank(stateTable.bank, deltaTime, stateTable)
                LoSetCommand(2001, pitchInput)
                LoSetCommand(2002, rollInput)

                if processSideSlip and mode == MODE_HEADING then
                    rudderInput = processSideSlip(stateTable.sideSlipAngle, deltaTime, stateTable)
                    LoSetCommand(2003, rudderInput)
                end
            else
                LoSetCommand(2001, pitchInput)
                LoSetCommand(2002, rollInput)
                if processSideSlip and mode == MODE_HEADING then
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
        engageLevelHeading = function(selfData)
            local modeSwitched = mode ~= MODE_HEADING
            if modeSwitched then
                if isDebugEnabled then
                    fmtInfo('autopilot engage level heading')
                end
                reset()
                desiredHeading = selfData and selfData.Heading or 0
                setBankTarget(0)
                setPitchTarget(0.05)
                mode = MODE_HEADING
                headingCaptured = true
            end
            if setAltitudeTarget then
                setAltitudeTarget(selfData.Position.y)
            end
            return modeSwitched, desiredHeading
        end,
        captureHeading = function(newHeading)
            if mode == MODE_HEADING then
                desiredHeading = newHeading
                headingCaptured = true
                return true
            end
            return false
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