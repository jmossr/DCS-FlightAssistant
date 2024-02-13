local flightAssistant = getfenv(1)
local fmtInfo = flightAssistant.fmtInfo

--local function confine(value, min, max)
--    if value < min then
--        return min
--    elseif value > max then
--        return max
--    else
--        return value
--    end
--end

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
    maxOutputChangePerSecond : maximum amount the output value can change in 1 second
------]]--
local function createPDiController(p, d, i, diCutOff, minOutput, maxOutput, maxOutputChangePerSecond)
    local lastError = 0
    local error
    local errorChangeSpeed = 0
    local accumError = 0
    local output = 0
    local target = 0
    local lowOutputCutOff = minOutput
    local highOutputCutOff = maxOutput
    local maxOutputChangeSpeed = maxOutputChangePerSecond
    local logStatePrefix
    local preparePDiFunction

    local function limitOutput(pdiValue, deltaTime)
        local maxDeltaOutput = deltaTime * maxOutputChangeSpeed
        local outputLimLow = output - maxDeltaOutput
        local outputLimHigh = output + maxDeltaOutput
        outputLimLow = outputLimLow > lowOutputCutOff and outputLimLow or lowOutputCutOff
        outputLimHigh = outputLimHigh < highOutputCutOff and outputLimHigh or highOutputCutOff
        return (pdiValue < outputLimLow and outputLimLow) or (pdiValue > outputLimHigh and outputLimHigh) or pdiValue
    end

    local function preparePDi(value, deltaTime)
        lastError = error
        error = target - value
        errorChangeSpeed = (error - lastError) / deltaTime
        if not diCutOff or errorChangeSpeed > -diCutOff and errorChangeSpeed < diCutOff then
            accumError = accumError + error * deltaTime
        else
            accumError = 0
        end
    end

    local function prepareInitial(value, _)
        error = target - value
        errorChangeSpeed = 0
        accumError = 0
        output = 0
        preparePDiFunction = preparePDi
    end

    local function process(value, deltaTime)
        preparePDiFunction(value, deltaTime)
        local pdiValue = error * p + errorChangeSpeed * d + accumError * i
        output = limitOutput(pdiValue, deltaTime)

        if logStatePrefix then
            fmtInfo('%s error; dt; de/dt; accum; raw; out; target: %s; %s; %s; %s; %s; %s; %s', logStatePrefix, error, deltaTime, errorChangeSpeed, accumError, pdiValue, output, target)
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

    local function getTarget()
        return target
    end

    local function reset()
        preparePDiFunction = prepareInitial
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

    local function getMaxOutput()
        return highOutputCutOff
    end

    local function setMinOutput(min)
        lowOutputCutOff = min
    end

    local function getMinOutput()
        return lowOutputCutOff
    end

    local function setMaxOutputChangePerSecond(maxChangePerSecond)
        maxOutputChangeSpeed = maxChangePerSecond
    end

    local function getMaxOutputChangePerSecond()
        return maxOutputChangeSpeed
    end

    local function setLogStatePrefix(prefix)
        logStatePrefix = prefix
    end

    reset()

    return { process = process,
             setTarget = setTarget,
             getTarget = getTarget,
             setMaxOutput = setMaxOutput,
             getMaxOutput = getMaxOutput,
             setMinOutput = setMinOutput,
             getMinOutput = getMinOutput,
             setMaxOutputChangePerSecond = setMaxOutputChangePerSecond,
             getMaxOutputChangePerSecond = getMaxOutputChangePerSecond,
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