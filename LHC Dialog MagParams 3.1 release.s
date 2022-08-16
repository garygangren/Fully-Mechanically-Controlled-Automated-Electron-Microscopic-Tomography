Class LHC_MagParamsDialog: UIFrame
{
	number m_Mag, m_a, m_k  // mag, rotation angle, pixel length
	number m_Direction, m_n, m_StepLen, m_xb, m_yb, m_Delay
	object m_Camera, m_AcqParams
	number m_BinX, m_BinY
	image m_Img
	number m_x0, m_y0, m_z0, m_t0 // original goniometer coordinates
	number m_i
	number m_dx, m_dy // image drift (pixel)
	number m_Thread, m_Measure
	
	LHC_MagParamsDialog(object self)
	{
		result("MagParams dialog created\n")
	}
	
	~LHC_MagParamsDialog(object self)
	{
		result("MagParams dialog destoryed\n")
	}

	object Init(object self)
	{
		// add thread
		m_Measure = 0
		m_Thread = self.AddMainThreadPeriodicTask("ThreadHandler",0.1)
		// box of current data
		TagGroup Box_CurrentData = DLGCreateBox("Current Data").DLGIdentifier("#Box_CurrentData")
		Box_CurrentData.DLGAddElement(DLGCreateStringField(GetApplicationDirectory(4,1),35))
		TagGroup Group_Data = DLGCreateGroup().DLGIdentifier("#Group_Data")
		Group_Data.DLGAddElement(DLGCreateLabel("Magnification:",15).DLGAnchor("West"))
		Group_Data.DLGAddElement(DLGCreateLabel("?",12).DLGIdentifier("#Label_Mag"))
		Group_Data.DLGAddElement(DLGCreatePushButton("Get","ButtonPressed_Get").DLGIdentifier("#Button_Get"))
		Group_Data.DLGAddElement(DLGCreateLabel("Rotation angle:",15).DLGAnchor("West"))
		Group_Data.DLGAddElement(DLGCreateLabel("?",12).DLGAnchor("West").DLGIdentifier("#Label_a"))
		Group_Data.DLGAddElement(DLGCreatePushButton("Set","ButtonPressed_SetRotationAngle").DLGIdentifier("#Button_SetRotationAngle"))
		Group_Data.DLGAddElement(DLGCreateLabel("Pixel length:",15).DLGAnchor("West"))
		Group_Data.DLGAddElement(DLGCreateLabel("?",12).DLGAnchor("West").DLGIdentifier("#Label_k"))
		Group_Data.DLGAddElement(DLGCreatePushButton("Set","ButtonPressed_SetPixelLength").DLGIdentifier("#Button_SetPixelLength"))
		Box_CurrentData.DLGAddElement(Group_Data.DLGTableLayOut(3,3,0))
		// box of measure
		TagGroup Box_Measure = DLGCreateBox("Measure").DLGIdentifier("#Box_Measure")
		TagGroup Group_Config = DLGCreateGroup().DLGIdentifier("#Group_Config")
		Group_Config.DLGAddElement(DLGCreateLabel("Driving direction:",17).DLGAnchor("West"))
		TagGroup Choice_Direction = DLGCreateChoice(0).DLGIdentifier("#Choice_Direction")
		Choice_Direction.DLGAddChoiceItemEntry("X+     ",1)
		Choice_Direction.DLGAddChoiceItemEntry("X-     ",2)
		Choice_Direction.DLGAddChoiceItemEntry("Y+     ",3)
		Choice_Direction.DLGAddChoiceItemEntry("Y-     ",4)
		Group_Config.DLGAddElement(Choice_Direction)
		Group_Config.DLGAddElement(DLGCreateLabel("").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateLabel("Step number:",17).DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateIntegerField(5).DLGWidth(12).DLGIdentifier("#Field_StepNum"))
		Group_Config.DLGAddElement(DLGCreateLabel("").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateLabel("Step length:",17).DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateIntegerField(100).DLGWidth(12).DLGIdentifier("#Field_StepLen"))
		Group_Config.DLGAddElement(DLGCreateLabel("nm").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateLabel("X backlash:",17).DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateIntegerField(5000).DLGWidth(12).DLGIdentifier("#Field_xb"))
		Group_Config.DLGAddElement(DLGCreateLabel("nm").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateLabel("Y backlash:",17).DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateIntegerField(2000).DLGWidth(12).DLGIdentifier("#Field_yb"))
		Group_Config.DLGAddElement(DLGCreateLabel("nm").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateLabel("Delay time:",17).DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateIntegerField(10).DLGWidth(12).DLGIdentifier("#Field_Delay"))
		Group_Config.DLGAddElement(DLGCreateLabel("sec").DLGAnchor("West"))
		Box_Measure.DLGAddElement(Group_Config.DLGTableLayOut(3,6,0))
		Box_Measure.DLGAddElement(DLGCreateLabel("0 / 0",20).DLGAnchor("West").DLGIdentifier("#Label_Progress"))
		Box_Measure.DLGAddElement(DLGCreateProgressBar("#ProgressBar").DLGFill("X"))
		Box_Measure.DLGAddElement(DLGCreatePushButton("Measure","ButtonPressed_Measure").DLGIdentifier("#Button_Measure").DLGInternalPadding(10,0))
		// init dialog
		TagGroup dialog	= DLGCreateDialog("")
		dialog.DLGAddElement(Box_CurrentData)
		dialog.DLGAddElement(Box_Measure)
		return self.super.Init(dialog)
	}
	
	void AboutToCloseDocument(object self,number verify )
	{
		m_Thread.RemoveMainThreadTask()
	}
	
	void ButtonPressed_Get(object self)
	{
		m_Mag = LHC_GetMag()
		m_a = m_Mag.LHC_GetRotationAngle()
		m_k = m_Mag.LHC_GetPixelLength()
		self.LookUpElement("#Label_Mag").DLGTitle(""+m_Mag/1e3+" k")
		self.LookUpElement("#Label_a").DLGTitle(""+round(m_a/pi()*1800)/10+" deg")
		self.LookUpElement("#Label_k").DLGTitle(""+round(m_k*1e12)/1e2+" A")
	}
	
	void ButtonPressed_SetRotationAngle(object self)
	{
		number a
		if(GetNumber("Please input rotation angle (deg) of Mag "+m_Mag/1e3+" k:",m_a/pi()*180,a))
		{
			m_Mag.LHC_SetRotationAngle(a/180*pi())
			m_a = m_Mag.LHC_GetRotationAngle()
			self.LookUpElement("#Label_a").DLGTitle(""+round(m_a/pi()*1800)/10+" deg")
		}
	}
	
	void ButtonPressed_SetPixelLength(object self)
	{
		number k
		if(GetNumber("Please input pixel length (A) of Mag "+m_Mag/1e3+" k:",m_k*1e10,k))
		{
			m_Mag.LHC_SetPixelLength(k*1e-10)
			m_k = m_Mag.LHC_GetPixelLength()
			self.LookUpElement("#Label_k").DLGTitle(""+round(m_k*1e12)/1e2+" A")
		}	
	}
	
	void ButtonPressed_Measure(object self)
	{
		// read settings
		m_Direction = self.LookUpElement("#Choice_Direction").DLGGetValue()
		m_n = self.LookUpElement("#Field_StepNum").DLGGetValue()
		m_StepLen = self.LookUpElement("#Field_StepLen").DLGGetValue()*1e-9
		m_xb = self.LookUpElement("#Field_xb").DLGGetValue()*1e-9
		m_yb = self.LookUpElement("#Field_yb").DLGGetValue()*1e-9
		m_Delay = self.LookUpElement("#Field_Delay").DLGGetValue()
		// check settings
		if(m_StepLen<100e-9)
		{
			ShowAlert("Step length must be greater than or equal to 100 nm.",0)
			return
		}
		if(m_n<=0)
		{
			ShowAlert("Step number must be positive.",0)
			return
		}
		if(m_Delay<0)
		{
			ShowAlert("Delay time was less than 0.",0)
			return
		}
		// show confirm info
		string confirm = "Please confirm the following settings:\n"
		confirm += "\nMagnification:	"+m_Mag/1e3+" k\n"
		if(m_Direction==0)
			confirm += "Driving direction:	X+\n"
		else if(m_Direction==1)
			confirm += "Driving direction:	X-\n"
		else if(m_Direction==2)
			confirm += "Driving direction:	Y+\n"
		else
			confirm += "Driving direction:	Y-\n"
		confirm += "Step number:	"+m_n+"\n"
		confirm += "Step length:	"+m_StepLen*1e9+" nm\n"
		confirm += "X backlash:	"+m_xb*1e9+" nm\n"
		confirm += "Y backlash:	"+m_yb*1e9+" nm\n"
		confirm += "Delay time:	"+m_Delay+" second\n"
		confirm += "\n(Press \"Shift\" key to break)"
		if(!OKCancelDialog(confirm))
			return
		// initialize
		self.SetElementIsEnabled("#Button_Measure",0)
		LHC_GetGonPos(m_x0,m_y0,m_z0,m_t0)
		LHC_SetGonT(0)
		if(m_Direction==0)		LHC_ResetBacklash(abs(m_xb),0,0,0)
		else if(m_Direction==1)	LHC_ResetBacklash(-abs(m_xb),0,0,0)
		else if(m_Direction==2)	LHC_ResetBacklash(0,abs(m_yb),0,0)
		else if(m_Direction==3)	LHC_ResetBacklash(0,-abs(m_yb),0,0)
		m_Camera = CM_GetCurrentCamera()
		m_AcqParams = m_Camera.CM_GetCameraAcquisitionParameterSet("Imaging","View","Focus",0)
		m_AcqParams.CM_GetBinning(m_BinX,m_BinY)
		m_i = 0
		sleep(m_Delay)
		m_dx = m_dy = 0
		result("#	sx(pixel)	sy(pixel)\n")
	//	m_Img = realimage("",4,400,400)
		m_Img = m_Camera.CM_AcquireImage(m_AcqParams)
		// update progress
		self.LookUpElement("#Label_Progress").DLGTitle(""+m_i+" / "+m_n)
		self.LookUpElement("#ProgressBar").DLGValue(m_i/m_n)
		// turn on measure in thread handler
		m_Measure = 1
	}
	
	void ThreadHandler(object self)
	{
		// measure
		if(m_Measure)
		{
			if(m_i<m_n && !SpaceDown())
			{
				m_i++
				if(m_Direction==0)		LHC_SetGonX(LHC_GetGonX()+m_StepLen)
				else if(m_Direction==1)	LHC_SetGonX(LHC_GetGonX()-m_StepLen)
				else if(m_Direction==2)	LHC_SetGonY(LHC_GetGonY()+m_StepLen)
				else if(m_Direction==3)	LHC_SetGonY(LHC_GetGonY()-m_StepLen)
				sleep(m_Delay)	
			//	image img := realimage("",4,400,400)
				image img := m_Camera.CM_AcquireImage(m_AcqParams)
				number sx,sy
				LHC_MeasureShift(m_Img,img,sx,sy)
				m_dx += sx
				m_dy += sy
				result(m_i+"	"+sx+"	"+sy+"\n")
				m_Img := img
				self.LookUpElement("#Label_Progress").DLGTitle(""+m_i+" / "+m_n)
				self.LookUpElement("#ProgressBar").DLGValue(m_i/m_n)
			}
			else
			{
				m_Measure = 0
				number x,y,z,t
				LHC_GetGonPos(x,y,z,t)
				number dxg = x-m_x0
				number dyg = y-m_y0
				number dxi = m_dx*m_BinX
				number dyi = m_dy*m_BinY
				number k = sqrt((dxg*dxg+dyg*dyg)/(dxi*dxi+dyi*dyi))
				number a = sgn(-dxg*dyi-dyg*dxi)*acos((dxg*dxi-dyg*dyi)/(dxg*dxg+dyg*dyg)*k)
				string str = "Magnification:	"+m_Mag/1e3+" k\nRotation angle:	"+a/pi()*180+" deg\nPixel length:	"+k*1e10+" A\n"
				result(str)
				LHC_SetGonPos(m_x0,m_y0,m_z0,m_t0)
				if(m_Direction==0)		LHC_ResetBacklash(abs(m_xb),0,0,0)
				else if(m_Direction==1)	LHC_ResetBacklash(-abs(m_xb),0,0,0)
				else if(m_Direction==2)	LHC_ResetBacklash(0,abs(m_yb),0,0)
				else if(m_Direction==3)	LHC_ResetBacklash(0,-abs(m_yb),0,0)
				if(OKCancelDialog("Task finished.\n\n"+str+"\nSave?"))
				{
					m_Mag.LHC_SetPixelLength(k)
					m_Mag.LHC_SetRotationAngle(a)
					self.ButtonPressed_Get()
				}
				self.SetElementIsEnabled("#Button_Measure",1)
			}
		}
	}	
}

void main()
{
	object dialog = Alloc(LHC_MagParamsDialog).Init()
	dialog.Display("MagParams")
}

main()