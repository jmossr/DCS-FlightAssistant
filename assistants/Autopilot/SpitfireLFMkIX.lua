include("setupSCR522ARadioTriggers",120)
include("setupSCR522ARadioAutopilotSequences")

local textToOwnShip = textToOwnShip

--[[
  createPDiController(p, d, i, diCutOff, minOutput, maxOutput, maxOutputChangePerSecond)
]]--
local pitchControl = createPDiController(1.7, 0.4, 0.2, 0.15, -1, 1, 3)
local bankControl = createPDiController(1, 0.3, 0.5, 0.3, -1, 1, 3)
local altitudeControl = createPDiController(0.005, 0.015, 0.001, 2, -0.1, 0.3, 0.05)

--[[
  createAutopilot(sampleTime, altitudeControl, pitchControl, bankControl [, rudderControl])
]]--
local autopilot = createAutopilot(0.07, altitudeControl, pitchControl, bankControl)
local autopilotEngageLevelFlight = autopilot.engageLevelFlight
local autopilotEngageLevelBank = autopilot.engageLevelBank
local autopilotFly = autopilot.fly
local autopilotDisengage = autopilot.disengage

local disengage = function()
    if autopilotDisengage() then
        textToOwnShip('A/P OFF')
    end
end

onSignalSequence('A/P_LVL_BNK').call(function()
    if autopilotEngageLevelBank(selfData) then
        textToOwnShip('A/P LVL BNK')
    end
end)
onSignalSequence('A/P_LVL').call(function()
    if autopilotEngageLevelFlight(selfData) then
        textToOwnShip('A/P LVL')
    end
end)
onSignalSequence('A/P_OFF').call(disengage)

onSimulationFrame(function()
    autopilotFly(selfData)
end)

onUnitDeactivating(autopilotDisengage)
