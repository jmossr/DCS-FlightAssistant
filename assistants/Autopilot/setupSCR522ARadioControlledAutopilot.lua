local altitudeControl, pitchControl, bankControl = ...
--[[
  createAutopilot(sampleTime, altitudeControl, pitchControl, bankControl [, rudderControl])
]]--
local autopilot = createAutopilot(0.07, altitudeControl, pitchControl, bankControl)
local autopilotEngageLevelFlight = autopilot.engageLevelFlight
local autopilotEngageLevelBank = autopilot.engageLevelBank
local autopilotFly = autopilot.fly
local autopilotDisengage = autopilot.disengage
local textToOwnShip = textToOwnShip

onSignal('A/P_LVL_BNK').call(function()
    if autopilotEngageLevelBank(selfData) then
        textToOwnShip('A/P LVL BNK')
    end
end)
onSignal('A/P_LVL').call(function()
    if autopilotEngageLevelFlight(selfData) then
        textToOwnShip('A/P LVL')
    end
end)
onSignal('A/P_OFF').call(function()
    if autopilotDisengage() then
        textToOwnShip('A/P OFF')
    end
end)

onSimulationFrame(function()
    autopilotFly(selfData)
end)

onUnitDeactivating(autopilotDisengage)
