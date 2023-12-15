include("setupSCR522ARadioAutopilotSequences")

--[[
  createPDiController(p, d, i, diCutOff, minOutput, maxOutput, maxOutputChangePerSecond)
]]--
local pitchControl = createPitchSpeedOverrideControl(createPDiController(1.7, 0.4, 0.2, 0.15, -1, 1, 3))
local bankControl = createPDiController(1, 0.3, 0.5, 0.3, -1, 1, 3)
local altitudeControl = createPDiController(0.005, 0.015, 0.001, 2, -0.1, 0.3, 0.05)

include("setupSCR522ARadioControlledAutoPilot", altitudeControl, pitchControl, bankControl)

onCommand(15, 3001).fireSignal('A/P_OFF')
onCommand(15, 3002).fireSignal('RADIO_A')
onCommand(15, 3003).fireSignal('RADIO_B')
onCommand(15, 3004).fireSignal('RADIO_C')
onCommand(15, 3005).fireSignal('RADIO_D')

onDeviceArgument(0, 120).valueAbove(0.1).fireSignal('RADIO_A_L')
onDeviceArgument(0, 121).valueAbove(0.1).fireSignal('RADIO_B_L')
onDeviceArgument(0, 122).valueAbove(0.1).fireSignal('RADIO_C_L')
onDeviceArgument(0, 123).valueAbove(0.1).fireSignal('RADIO_D_L')