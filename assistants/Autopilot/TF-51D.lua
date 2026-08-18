include("setupSCR522ARadioAutopilotSequences")

--[[
  createPDiController(p, d, i, diCutOff, minOutput, maxOutput, maxOutputChangePerSecond)
]]--
local pitchControl = createPitchSpeedOverrideControl(createPDiController(2, 0.1, 0.2, 0.15, -1, 1, 3), 70)
local bankControl = createPDiController(3, 0.4, 0.5, 0.3, -1, 1, 3)
local altitudeControl = createPDiController(0.005, 0.015, 0.001, 2, -0.1, 0.3, 0.05)
local headingControl = createPDiController(2.5, 0.8, 0.1, 0.2, -0.4, 0.4, 0.1)

-- Simple rudder controller for sideslip nulling (only active in Heading mode)
local rudderControl = createPDiController(1.5, 0.4, 0.05, 0.3, -0.3, 0.3, 0.15)

include("setupSCR522ARadioControlledAutopilot", altitudeControl, pitchControl, bankControl, headingControl, rudderControl)

onCommand(24, 3001).fireSignal('A/P_OFF')
onCommand(24, 3002).fireSignal('RADIO_A')
onCommand(24, 3003).fireSignal('RADIO_B')
onCommand(24, 3004).fireSignal('RADIO_C')
onCommand(24, 3005).fireSignal('RADIO_D')

onDeviceArgument(0, 122).valueAbove(0.1).fireSignal('RADIO_A_L')
onDeviceArgument(0, 123).valueAbove(0.1).fireSignal('RADIO_B_L')
onDeviceArgument(0, 124).valueAbove(0.1).fireSignal('RADIO_C_L')
onDeviceArgument(0, 125).valueAbove(0.1).fireSignal('RADIO_D_L')