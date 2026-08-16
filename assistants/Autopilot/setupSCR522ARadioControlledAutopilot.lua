local altitudeControl, pitchControl, bankControl, headingControl, rudderControl = ...
--[[
  createAutopilot(sampleTime, altitudeControl, pitchControl, bankControl [, headingControl, rudderControl])
  Note: Rudder is only active in A/P_LVL_HDG mode
]]--
local autopilot = createAutopilot(0.07, altitudeControl, pitchControl, bankControl, headingControl, rudderControl)
local autopilotEngageLevelFlight = autopilot.engageLevelFlight
local autopilotEngageLevelBank = autopilot.engageLevelBank
local autopilotEngageLevelHeading = autopilot.engageLevelHeading
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
onSignal('A/P_LVL_HDG').call(function()
    local switched, capturedHdg = autopilotEngageLevelHeading(selfData)
    if switched then
        local hdgDeg = math.deg(capturedHdg or 0)
        textToOwnShip(string.format('A/P LVL HDG - %.1f°', hdgDeg), 10)
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
