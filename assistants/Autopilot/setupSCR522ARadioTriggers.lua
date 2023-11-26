local channelA_Argument = ...
defineSignalGroup('RADIO').forSignals('RADIO_A', 'RADIO_B', 'RADIO_C', 'RADIO_D')
onDeviceArgument(0, channelA_Argument).value(1).fireSignal('RADIO_A')
onDeviceArgument(0, channelA_Argument + 1).value(1).fireSignal('RADIO_B')
onDeviceArgument(0, channelA_Argument + 2).value(1).fireSignal('RADIO_C')
onDeviceArgument(0, channelA_Argument + 3).value(1).fireSignal('RADIO_D')
