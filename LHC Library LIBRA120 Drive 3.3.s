// 3.3 update:
// LHC_SetGonPos: use SetGonX SetGonY ... SetGonT in sequence
// LHC_MoveGonPos: use SetGonX SetGonY ... SetGonT in sequence
// LHC_ResetBacklash: use SetGonX SetGonY ... SetGonT in sequence


// SI units

string LHC_Decimal(number n, number len)
{
	string str
	if(n<0)
		str = "-"+abs(n).decimal(len-1) 
	else
		str = "+"+abs(n).decimal(len-1)
	return str
}

// voltage

number LHC_GetVoltage(void)
{
	string str = "G151xxxxxx"
	Leo_Command("G151",str)
	return val(str.right(6))
}

// magnification

number LHC_GetMag(void)
{
	string str = "G150xxxxxx"
	Leo_Command("G150",str)
	return val(str.right(6))
}

number LHC_GetMagPointer(void)
{
	string str = "G100xx"
	Leo_Command("G100",str)
	return val(str.right(2))
}

void LHC_SetMagPointer(number MagPointer)
{
	if(MagPointer<0 || MagPointer>27)
		ShowAlert("Error in function [LHC_SetMagPointer]:\nMag Pointer was out of the range of 0 to 27.",0)
	else
		Leo_Command("S100"+decimal(MagPointer,2))
}

// illunimation

number LHC_GetIllAperture(void)
{
	string str = "G101xx"
	Leo_Command("G101",str)
	return val(str.right(2))
}

void LHC_SetIllAperture(number ill)
{
	if(ill<0 || ill>29)
		ShowAlert("Error in function [LHC_SetIllAperture]:\nIllumination Pointer was out of the range of 0 to 29.",0)
	else
		Leo_Command("S101"+decimal(ill,2))
}

// focus

number LHC_GetFocusDistance(void)
{
	string str = "G500xxxxxxx"
	Leo_Command("G500",str)
	return val(str.right(7))*1e-9
}

void LHC_SetFocusDistance(number FocusDistance)
{
	if(FocusDistance<0)
		ShowAlert("Error in function [LHC_SetFocusDistance]:\nFocusDistance must be positive or zero.",0)
	else
		Leo_Command("S500"+decimal(FocusDistance*1e9,7))
}

// goniometer

void LHC_GetGonPos(number &x, number &y, number &z, number &t)
{
	string str = "G300xxxxxxxxyyyyyyyyzzzzzzzztttttttt"
	Leo_Command("G300",str)
	x = val(left(str.right(32),8))*1e-9
	y = val(left(str.right(24),8))*1e-9
	z = val(left(str.right(16),8))*1e-9
	t = val(str.right(8))/1e4/180*pi()
}

number LHC_GetGonX(void)
{
	number x,y,z,t
	LHC_GetGonPos(x,y,z,t)
	return x
}

number LHC_GetGonY(void)
{
	number x,y,z,t
	LHC_GetGonPos(x,y,z,t)
	return y
}

number LHC_GetGonZ(void)
{
	number x,y,z,t
	LHC_GetGonPos(x,y,z,t)
	return z
}

number LHC_GetGonT(void)
{
	number x,y,z,t
	LHC_GetGonPos(x,y,z,t)
	return t
}

void LHC_SetGonX(number x)
{
	if(abs(x)>1e-3)
		ShowAlert("Error in function [LHC_SetGonX]:\nx was out of the range of -1 to 1 mm.",0)
	else
		Leo_Command("S303"+LHC_Decimal(x*1e9,8))
}

void LHC_SetGonY(number y)
{
	if(abs(y)>1e-3)
		ShowAlert("Error in function [LHC_SetGonY]:\ny was out of the range of -1 to 1 mm.",0)
	else
		Leo_Command("S304"+LHC_Decimal(y*1e9,8))
}

void LHC_SetGonZ(number z)
{
	if(abs(z)>1e-3)
		ShowAlert("Error in function [LHC_SetGonZ]:\nz was out of the range of -1 to 1 mm.",0)
	else
		Leo_Command("S305"+LHC_Decimal(z*1e9,8))
}

void LHC_SetGonT(number t)
{
	if(abs(t)>65/180*pi())
		ShowAlert("Error in function [LHC_SetGonT]:\nt was out of the range of -65 to 65 deg.",0)
	else
		Leo_Command("S306"+LHC_Decimal(t/pi()*180*1e4,8))
}

void LHC_SetGonPos(number x, number y, number z, number t)
{
	LHC_SetGonX(x)
	LHC_SetGonY(y)
	LHC_SetGonZ(z)
	LHC_SetGonT(t)
}

void LHC_MoveGonPos(number dx, number dy, number dz, number dt)
{
	number x,y,z,t
	LHC_GetGonPos(x,y,z,t)
	if(dx!=0)	LHC_SetGonX(x+dx)
	if(dy!=0)	LHC_SetGonY(y+dy)
	if(dz!=0)	LHC_SetGonZ(z+dz)
	if(dt!=0)	LHC_SetGonT(t+dt)
}

void LHC_ResetBacklash(number xb, number yb, number zb, number tb)
{
	number x,y,z,t
	LHC_GetGonPos(x,y,z,t)
	if(xb!=0)
	{
		LHC_SetGonX(x-xb)
		LHC_SetGonX(x)
	}
	if(yb!=0)
	{
		LHC_SetGonY(y-yb)
		LHC_SetGonY(y)
	}
	if(zb!=0)
	{
		LHC_SetGonZ(z-zb)
		LHC_SetGonZ(z)
	}
	if(tb!=0)
	{
		LHC_SetGonT(t-tb)
		LHC_SetGonT(t)
	}
}