local flightAssistant = getfenv(1)
local fmtInfo = flightAssistant.fmtInfo

local function confine(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

--[[------
    PDi controller
    PD control always active
    I steps in only when error changes are small

    p                        : coefficient for the proportional term
    d                        : coefficient for the derivative term
    i                        : coefficient for the integral term
    diCutOff                 : maximum amount the error may change per second to still take the integral term into account
    maxOutput                : high cut off off value for the calculated output
    minOutput                : low cut off off value for the calculated output
    maxOutputChangeSpeed     : maximum amount the output value can change in 1 second
------]]--
local function createPDiController(p, d, i, diCutOff, minOutput, maxOutput, maxOutputChangeSpeed)
    local lastError = 0
    local error
    local errorChangeSpeed = 0
    local accumError = 0
    local output = 0
    local target = 0
    local lowDiCutOff = -diCutOff
    local lowOutputCutOff = minOutput
    local highOutputCutOff = maxOutput
    local logStatePrefix

    local function limitOutput(pdiValue, deltaTime)
        local maxDeltaOutput = deltaTime * maxOutputChangeSpeed
        local outputLimLow = output - maxDeltaOutput
        local outputLimHigh = output + maxDeltaOutput
        outputLimLow = outputLimLow > lowOutputCutOff and outputLimLow or lowOutputCutOff
        outputLimHigh = outputLimHigh < highOutputCutOff and outputLimHigh or highOutputCutOff
        return confine(pdiValue, outputLimLow, outputLimHigh)
    end

    local function process(value, deltaTime)
        if not error then
            error = target - value
            errorChangeSpeed = 0
            accumError = 0
            output = 0
        else
            lastError = error
            error = target - value
            errorChangeSpeed = (error - lastError) / deltaTime
            if errorChangeSpeed > lowDiCutOff and errorChangeSpeed < diCutOff then
                accumError = accumError + error * deltaTime
            else
                accumError = 0
            end
        end
        local pdiValue = error * p + errorChangeSpeed * d + accumError * i
        output = limitOutput(pdiValue, deltaTime)

        if logStatePrefix then
            fmtInfo('%s error; de/dt; accum; raw; out; target: %s; %s; %s; %s; %s; %s', logStatePrefix, error, errorChangeSpeed, accumError, pdiValue, output, target)
        end
        return output
    end

    local function setTarget(value)
        if error then
            local lastKnownValue = target - error
            error = value - lastKnownValue
        end
        target = value
    end

    local function reset()
        error = nil
    end

    local function isStable(maxError, maxErrorChangeSpeed)
        return error > -maxError and error < maxError
                and errorChangeSpeed > -maxErrorChangeSpeed and errorChangeSpeed < maxErrorChangeSpeed
    end

    local function getState()
        return error, errorChangeSpeed, accumError, output, target
    end

    local function setMaxOutput(max)
        highOutputCutOff = max
    end

    local function setMinOutput(min)
        lowOutputCutOff = min
    end

    local function setLogStatePrefix(prefix)
        logStatePrefix = prefix
    end

    return { process = process,
             setTarget = setTarget,
             setMaxOutput = setMaxOutput,
             setMinOutput = setMinOutput,
             getState = getState,
             isStable = isStable,
             reset = reset,
             setLogStatePrefix = setLogStatePrefix
    }
end

local function initPUnit(_, proxy)
    proxy.createPDiController = createPDiController
end

return { initPUnit = initPUnit }