local LoGetADIPitchBankYaw = Export.LoGetADIPitchBankYaw
local textToOwnShip = textToOwnShip

defineSignalGroup('RADIO').forSignals('RADIO_A', 'RADIO_B', 'RADIO_C', 'RADIO_D')
-- device 0 refers to the main panel, argument 122 refers to the VHF radio indicator light for channel A
-- See DCS\Mods\aircraft\TF-51D\Cockpit\Scripts\mainpanel_init.lua SCR-522A Control panel
onDeviceArgument(0, 122).value(1).fireSignal('RADIO_A')
onDeviceArgument(0, 123).value(1).fireSignal('RADIO_B')
onDeviceArgument(0, 124).value(1).fireSignal('RADIO_C')
onDeviceArgument(0, 125).value(1).fireSignal('RADIO_D')
defineSignalSequence('A/P_ATT').forSignals('RADIO_D', 'RADIO_C', 'RADIO_A').within(2.5)
defineSignalSequence('A/P_LVL').forSignals('RADIO_D', 'RADIO_C', 'RADIO_B').within(2.5)
defineSignalSequence('A/P_OFF').forSignals('RADIO_D', 'RADIO_C', 'RADIO_D').within(2.5)
--[[
  createPDiController(p, d, i, diCutOff, minOutput, maxOutput, maxOutputChangePerSecond)
]]--
local pitchControl = createPDiController(2, 0.1, 0.2, 0.15, -1, 1, 3)
local bankControl = createPDiController(3, 0.4, 0.5, 0.3, -1, 1, 3)
local altitudeControl = createPDiController(0.005, 0.015, 0.001, 2, -0.1, 0.3, 0.05)
local setPitchTarget = pitchControl.setTarget
local setBankTarget = bankControl.setTarget
local setAltitudeTarget = altitudeControl.setTarget

--[[
  createAutopilot(sampleTime, altitudeControl, pitchControl, bankControl [, rudderControl])
]]--
local autopilot = createAutopilot(0.07, altitudeControl, pitchControl, bankControl)
local autopilotFly = autopilot.fly
local autopilotEngage = autopilot.engage
local autopilotDisengage = autopilot.disengage
local autopilotIsEngaged = autopilot.isEngaged

local autopilotMode
local disengage = function()
    autopilotMode = nil
    autopilotDisengage()
    textToOwnShip('A/P OFF')
end

onSignalSequence('A/P_ATT').call(function()
    if not autopilotIsEngaged() or autopilotMode ~= 'A/P_ATT' then
        local _, bank = LoGetADIPitchBankYaw()
        setBankTarget(bank)
        setPitchTarget(0.05)
        setAltitudeTarget(selfData.Position.y)
        autopilotMode = 'A/P_ATT'
        autopilotEngage()
        textToOwnShip('A/P LVL BNK')
    end
end)
onSignalSequence('A/P_LVL').call(function()
    if not autopilotIsEngaged() or autopilotMode ~= 'A/P_LVL' then
        setBankTarget(0)
        setPitchTarget(0.05)
        setAltitudeTarget(selfData.Position.y)
        autopilotMode = 'A/P_LVL'
        autopilotEngage()
        textToOwnShip('A/P LVL')
    end
end)
onSignalSequence('A/P_OFF').call(disengage)

onSimulationFrame(function()
    autopilotFly(selfData)
end)
onUnitDeactivating(disengage)
