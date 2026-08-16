-- FuG 16ZY: 4-position rotary selector, positions I/II/III/IV = values 0.0/0.1/0.2/0.3
-- Unlike the SCR-522 which has 4 separate buttons, the FuG 16ZY is a rotary: moving from
-- position I to IV passes through II and III. Sequences must therefore use adjacent steps only.
--
-- Each single click of the knob fires exactly one directional signal:
--   Moving up (towards IV):  FUG_UP_II, FUG_UP_III, FUG_UP_IV
--   Moving down (towards I): FUG_DN_III, FUG_DN_II, FUG_DN_I
--
-- Engagement sequences (all within 2.5 seconds):
--   Heading hold : Go to I, tap II, return to I    (I -> II -> I)
--   Level flight : Go to I, sweep up to III        (I -> II -> III)
--   Bank hold    : Go to IV, sweep down to II      (IV -> III -> II)
--   Disengage    : Go to IV, tap III, return to IV (IV -> III -> IV)

defineSignalGroup('FUG_RADIO').forSignals('FUG_UP_II', 'FUG_UP_III', 'FUG_UP_IV', 'FUG_DN_III').plus('FUG_DN_II', 'FUG_DN_I')

defineSignalSequence('A/P_LVL_HDG_FUG_SQ').forSignals('FUG_DN_I', 'FUG_UP_II', 'FUG_DN_I').within(2.5)
defineSignalSequence('A/P_LVL_FUG_SQ').forSignals('FUG_DN_I', 'FUG_UP_II', 'FUG_UP_III').within(2.5)
defineSignalSequence('A/P_LVL_BNK_FUG_SQ').forSignals('FUG_UP_IV', 'FUG_DN_III', 'FUG_DN_II').within(2.5)
defineSignalSequence('A/P_OFF_FUG_SQ').forSignals('FUG_UP_IV', 'FUG_DN_III', 'FUG_UP_IV').within(2.5)

onSignalSequence('A/P_LVL_HDG_FUG_SQ').fireSignal('A/P_LVL_HDG')
onSignalSequence('A/P_LVL_FUG_SQ').fireSignal('A/P_LVL')
onSignalSequence('A/P_LVL_BNK_FUG_SQ').fireSignal('A/P_LVL_BNK')
onSignalSequence('A/P_OFF_FUG_SQ').fireSignal('A/P_OFF')
