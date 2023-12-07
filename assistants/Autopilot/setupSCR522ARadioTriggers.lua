local channelA_Arg, channelB_Arg, channelC_Arg, channelD_Arg, txLight_Arg = ...
channelB_Arg = channelB_Arg or (channelA_Arg + 1)
channelC_Arg = channelC_Arg or (channelA_Arg + 2)
channelD_Arg = channelD_Arg or (channelA_Arg + 3)
txLight_Arg = txLight_Arg or (channelA_Arg + 4)

defineSignalGroup('RADIO').forSignals('RADIO_A', 'RADIO_B', 'RADIO_C', 'RADIO_D')
onDeviceArgument(0, channelA_Arg).valueAbove(0.1).fireSignal('RADIO_A')
onDeviceArgument(0, channelB_Arg).valueAbove(0.1).fireSignal('RADIO_B')
onDeviceArgument(0, channelC_Arg).valueAbove(0.1).fireSignal('RADIO_C')
onDeviceArgument(0, channelD_Arg).valueAbove(0.1).fireSignal('RADIO_D')
