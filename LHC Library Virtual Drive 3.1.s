// voltage
number LHC_GetVoltage(void) return 0
// magnification
number LHC_GetMag(void) return 0
number LHC_GetMagPointer(void) return 0
void LHC_SetMagPointer(number MagPointer) {}
// illumination
number LHC_GetIllAperture(void) return 0
void LHC_SetIllAperture(number ill) {}
// focus
number LHC_GetFocusDistance(void) return 0
void LHC_SetFocusDistance(number FocusDistance) {}
// goniometer
void LHC_GetGonPos(number &x, number &y, number &z, number &t) {}
number LHC_GetGonX(void) return 0
number LHC_GetGonY(void) return 0
number LHC_GetGonZ(void) return 0
number LHC_GetGonT(void) return 0
void LHC_SetGonX(number x) {}
void LHC_SetGonY(number y) {}
void LHC_SetGonZ(number z) {}
void LHC_SetGonT(number t) {}
void LHC_SetGonPos(number x, number y, number z, number t) {}
void LHC_MoveGonPos(number dx, number dy, number dz, number dt) {}
void LHC_ResetBacklash(number xb, number yb, number zb, number tb) {}