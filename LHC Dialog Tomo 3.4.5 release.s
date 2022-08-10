Class LHC_TomoDialog: UIFrame
{
	// system parameters
	number m_V, m_Mag, m_a, m_k, m_Bin // high voltage, magnification, rotation angle, pixel length, viewer binning
	// configurations
	string m_Folder, m_Prefix
	number m_tStart, m_dt, m_tStop
	number m_RefDefocus
	string m_ImgDefocus
	number m_PositionTrackingOn, m_DefocusTrackingOn
	// advanced settings
	number m_PointerColor, m_PointerDiameter
	number m_xb, m_yb, m_zb, m_tb
	number m_Delay
	number m_kpp, m_kip
	number m_PositionErrorThreshold, m_PositionErrorCorrectOn, m_PositionErrorWarningOn
	number m_wDiv, m_hDiv, m_nr, m_Cs, m_AC
	number m_DefocusMin, m_DefocusMax, m_DefocusStep, m_DefocusAccuracy
	number m_kpf, m_kif
	number m_DefocusErrorThreshold, m_DefocusErrorCorrectOn, m_DefocusErrorWarningOn
	// control parameters
	number m_n, m_i, m_Corrected
	number m_ux, m_cx, m_ex, m_exi
	number m_uy, m_cy, m_ey, m_eyi
	number m_uf, m_cf, m_ef, m_efi
	// images and components
	image m_Img0, m_Img1, m_Img2, m_ImgF, m_ImgE
	number m_w, m_h
	Component m_Circle0, m_Circle1, m_Circle2
	Component m_Box0, m_Box1, m_Box2
	number m_ImgFLMode, m_ImgFRMode
	Component m_AnnotationL, m_AnnotationR
	// thread paramters
	number m_Thread, m_Run
		
	LHC_TomoDialog(object self)
	{
		result("Tomo dialog created\n")
	}
	
	~LHC_TomoDialog(object self)
	{
		result("Tomo dialog destoryed\n")
	}
	
	void GetConfig(object self)
	{
		m_Folder = self.LookUpElement("#Field_Folder").DLGGetStringValue()
		m_Prefix = self.LookUpElement("#Field_Prefix").DLGGetStringValue()		
		m_tStart = self.LookUpElement("#Field_tStart").DLGGetValue()/180*pi()
		m_dt = self.LookUpElement("#Field_dt").DLGGetValue()/180*pi()
		m_tStop = self.LookUpElement("#Field_tStop").DLGGetValue()/180*pi()
		m_RefDefocus = self.LookUpElement("#Field_RefDefocus").DLGGetValue()*1e-9
		m_ImgDefocus = self.LookUpElement("#Field_ImgDefocus").DLGGetStringValue()
		m_PositionTrackingOn = self.LookUpElement("#Check_PositionTrackingOn").DLGGetValue()
		m_DefocusTrackingOn = self.LookUpElement("#Check_DefocusTrackingOn").DLGGetValue()
	}

	void Clear(object self)
	{
		// delete components
		if(m_Box0.ComponentIsValid())	m_Box0.ComponentRemoveFromParent()
		if(m_Box1.ComponentIsValid())	m_Box1.ComponentRemoveFromParent()
		if(m_Box2.ComponentIsValid())	m_Box2.ComponentRemoveFromParent()
		if(m_Circle0.ComponentIsValid())	m_Circle0.ComponentRemoveFromParent()
		if(m_Circle1.ComponentIsValid())	m_Circle1.ComponentRemoveFromParent()
		if(m_Circle2.ComponentIsValid())	m_Circle2.ComponentRemoveFromParent()
		if(m_AnnotationL.ComponentIsValid())	m_AnnotationL.ComponentRemoveFromParent()
		if(m_AnnotationR.ComponentIsValid())	m_AnnotationR.ComponentRemoveFromParent()
		// delete images
		if(m_Img0.ImageIsValid())	m_Img0.DeleteImage()
		if(m_Img1.ImageIsValid())	m_Img1.DeleteImage()
		if(m_Img2.ImageIsValid())	m_Img2.DeleteImage()
		if(m_ImgF.ImageIsValid())	m_ImgF.DeleteImage()
		if(m_ImgE.ImageIsValid())	m_ImgE.DeleteImage()
	}
	
	void AddROIListener(object self, image img, string name)
	{
		number w,h
		img.GetSize(w,h)
		ImageDisplay disp = img.ImageGetImageDisplay(0)
		ROI FullROI = NewROI()
		FullROI.ROISetVolatile(0)
		FullROI.ROISetResizable(0)
		FullROI.ROISetDeletable(0)
		FullROI.ROISetName(name)
		FullROI.ROISetRectangle(0,0,h,w)
		FullROI.ROISetColor(0,0,0)
		disp.ImageDisplayAddROI(FullROI) 				
		disp.ImageDisplayAddEventListener(self,"roi_end_track:"+name)
	}
	
	void RegulatePosition(object self, number ux, number uy, number a)
	{
		LHC_Rotate(ux,uy,-a)
		number t = LHC_GetGonT()
		LHC_MoveGonPos(ux,uy/cos(t),0,0)
		LHC_ResetBacklash(m_xb,m_yb,0,0)
	}
	
	void RegulateDefocus(object self, number uf)
	{
		LHC_SetFocusDistance(LHC_GetFocusDistance()+uf)
	}
	
	void CalculatePositionError(object self)
	{
		if(m_i<2)
			return
		number t0 = LHC_GetGonT()
		number t1 = t0-m_dt
		image img0 := m_Img0.LHC_Stretch(m_a+pi()/2,cos(t1)/cos(t0))
		number sx,sy
		LHC_MeasureShift(m_Img1,img0,sx,sy)
		number ex1 = m_ImgE.GetPixel(m_i-1,0)*1e-9
		number ey1 = m_ImgE.GetPixel(m_i-1,1)*1e-9
		m_ex = ex1 - sx*m_Bin*m_k
		m_ey = ey1 + sy*m_Bin*m_k
		m_ImgE.SetPixel(m_i,0,m_ex*1e9)
		m_ImgE.SetPixel(m_i,1,m_ey*1e9)
	}
	
	void CalculateDefocusError(object self)
	{
		if(m_i<1)
			return
		image img
		if(m_wDiv==m_hDiv)
			img := m_Img0
		else
			img := m_Img0.LHC_Rotate(-m_a,"c")
		image DefocusMap := img.LHC_FindDefocusMap(m_wDiv, m_hDiv, m_nr, m_k*m_Bin, m_V, m_Cs, m_AC \
								,m_DefocusMin, m_DefocusMax, m_DefocusStep, m_DefocusAccuracy)
		number defocus = DefocusMap.LHC_RegressLimit2STD().mean()
		m_ef = m_RefDefocus-defocus
		m_ImgE.SetPixel(m_i,2,m_ef*1e9)
	}
	
	number CorrectErrorIfNecessary(object self)
	{
		if(!m_Corrected && ((m_PositionErrorCorrectOn && max(abs(m_ex),abs(m_ey))>m_PositionErrorThreshold) \
							||(m_DefocusErrorCorrectOn && abs(m_ef)>m_DefocusErrorThreshold)) )
		{
			self.RegulatePosition(m_ex,m_ey,m_a)
			self.RegulateDefocus(m_ef)
			m_cx += m_ex
			m_cy += m_ey
			m_cf += m_ef
			sleep(m_Delay)
			return 1
		}
		else
			return 0
	}
	
	void WarnIfNecessary(object self)
	{
		if(m_PositionErrorWarningOn && max(abs(m_ex),abs(m_ey))>m_PositionErrorThreshold)
		{
			ShowAlert("Position error was larger than "+m_PositionErrorThreshold*1e9+" nm.",1)
			m_Run = 0
		}
		if(m_DefocusErrorWarningOn && abs(m_ef)>m_DefocusErrorThreshold)
		{
			ShowAlert("Defocus error was larger than "+m_DefocusErrorThreshold*1e9+" nm.",1)
			m_Run = 0
		}
	}
	
	void UpdateComponentRect(object self, Component &c, string style, number i)
	{
		if(!c.ComponentIsValid())
			return
		if(style=="Circle" && m_i>i)
			c.ComponentSetRect(  m_h/2 - m_PointerDiameter/2/m_k/m_Bin + m_ImgE.GetPixel(m_i-i,1)*1e-9/m_k/m_Bin \
								,m_w/2 - m_PointerDiameter/2/m_k/m_Bin - m_ImgE.GetPixel(m_i-i,0)*1e-9/m_k/m_Bin \
								,m_h/2 + m_PointerDiameter/2/m_k/m_Bin + m_ImgE.GetPixel(m_i-i,1)*1e-9/m_k/m_Bin \
								,m_w/2 + m_PointerDiameter/2/m_k/m_Bin - m_ImgE.GetPixel(m_i-i,0)*1e-9/m_k/m_Bin )
		else
			c.ComponentSetRect(  m_h/2 - m_PointerDiameter/2/m_k/m_Bin \
								,m_w/2 - m_PointerDiameter/2/m_k/m_Bin \
								,m_h/2 + m_PointerDiameter/2/m_k/m_Bin \
								,m_w/2 + m_PointerDiameter/2/m_k/m_Bin )
	}
	
	void UpdateImgF(object self)
	{
		string name = "#"+m_i
		number defocus
		if(self.LookUpElement("#Label_Progress").DLGGetTitle()!=""+m_i+" / "+m_n)
		{
			defocus = m_RefDefocus-m_ef
			name += " DF"+round(defocus*1e9)+"nm"
		}
		m_ImgF.SetName(name)
		if(m_ImgFLMode)
		{
			m_AnnotationL.TextAnnotationSetText("Subarea FFT")		
			image sub
			number ws,hs
			if(m_wDiv==m_hDiv)
			{
				ws = m_w/m_wDiv
				hs = m_h/m_hDiv
				sub := m_Img0[m_h/2-hs/2, m_w/2-ws/2, m_h/2+hs/2, m_w/2+ws/2]
			}
			else
			{
				image imgr := m_Img0.LHC_Rotate(-m_a,"c")
				ws = m_w/2
				hs = m_h/2/m_hDiv
				sub := imgr[m_h/4-hs/2, 0, m_h/4+hs/2, ws]
				while(ws>=2*hs)
				{
					sub := sub[0,0,hs,ws/2]+sub[0,ws/2,hs,ws]
					sub.GetSize(ws,hs)
				}
			}
			image SubFFT := modulus(realfft(sub))
			m_ImgF[0,0,m_h,m_w/2] = LHC_Resize(SubFFT[0,0,hs,ws/2],m_w/2,m_h)/mean(SubFFT)/2
		}
		else
		{
			m_AnnotationL.TextAnnotationSetText("Full FFT")
			image Img0FFT := modulus(realfft(m_Img0))
			m_ImgF[0,0,m_h,m_w/2] = Img0FFT[0,0,m_h,m_w/2]/mean(Img0FFT)/2
		}
		if(m_ImgFRMode)
		{
			m_AnnotationR.TextAnnotationSetText("Fitted CTF")
			if(self.LookUpElement("#Label_Progress").DLGGetTitle()!=""+m_i+" / "+m_n)
			{
				image CTF := LHC_CreateCTF(m_w/2,m_k*m_Bin,m_V,m_Cs,m_AC,defocus)
				image ImgFRight := realimage("",8,m_w/2,m_h)
				ImgFRight = CTF[sqrt(icol**2+(irow-m_h/2)**2),0]
				m_ImgF[0,m_w/2,m_h,m_w] = ImgFRight
			}
			else
				m_ImgF[0,m_w/2,m_h,m_w] = 0
		}
		else
		{
			m_AnnotationR.TextAnnotationSetText("Ref. CTF")
			image CTF := LHC_CreateCTF(m_w/2,m_k*m_Bin,m_V,m_Cs,m_AC,m_RefDefocus)
			image ImgFRight := realimage("",8,m_w/2,m_h)
			ImgFRight = CTF[sqrt(icol**2+(irow-m_h/2)**2),0]
			m_ImgF[0,m_w/2,m_h,m_w] = ImgFRight
		}
	}
	
	void ResultLog(object self)
	{
		string str = m_i.LHC_SetStringLength(5) \
					+(round(LHC_GetGonT()/pi()*1800)/10).LHC_SetStringLength(10) \
					+"X pos.(nm): "+round(m_ux*1e9).LHC_SetStringLength(6)+round(m_cx*1e9).LHC_SetStringLength(6)+round(m_ex*1e9).LHC_SetStringLength(6) \
					+"Y pos.(nm): "+round(m_uy*1e9).LHC_SetStringLength(6)+round(m_cy*1e9).LHC_SetStringLength(6)+round(m_ey*1e9).LHC_SetStringLength(6) \
					+"Defocus(nm): "+round(m_uf*1e9).LHC_SetStringLength(6)+round(m_cf*1e9).LHC_SetStringLength(6)+round(m_ef*1e9).LHC_SetStringLength(6)+"\n"
		result(str)
		if(m_Prefix!="TrackToStartAngle")
			(m_Folder+m_Prefix+"Log.txt").LHC_Result(str)
	}
	
	object Init(object self)
	{
		// add thread
		m_Run = 0
		m_Thread = self.AddMainThreadPeriodicTask("ThreadHandler",0.1)
		// read settings
		string name = GetApplicationDirectory(4,1)+"LHC Tomo Dialog Settings.txt"
		if(name.DoesFileExist())
		{
			number file = name.OpenFileForReading()
			string str
			// configurations
			if(file.ReadFileLine(str))	m_Folder = left(str,len(str)-len("\n"))
			if(file.ReadFileLine(str))	m_Prefix = left(str,len(str)-len("\n"))
			if(file.ReadFileLine(str))	m_tStart = val(str)
			if(file.ReadFileLine(str))	m_dt = val(str)
			if(file.ReadFileLine(str))	m_tStop = val(str)
			if(file.ReadFileLine(str))	m_RefDefocus = val(str)
			if(file.ReadFileLine(str))	m_ImgDefocus = left(str,len(str)-len("\n"))
			if(file.ReadFileLine(str))	m_PositionTrackingOn = val(str)
			if(file.ReadFileLine(str))	m_DefocusTrackingOn = val(str)
			// position tracking parameters
			if(file.ReadFileLine(str))	m_PointerColor = val(str)
			if(file.ReadFileLine(str))	m_PointerDiameter = val(str)
			if(file.ReadFileLine(str))	m_xb = val(str)
			if(file.ReadFileLine(str))	m_yb = val(str)
			if(file.ReadFileLine(str))	m_zb = val(str)
			if(file.ReadFileLine(str))	m_tb = val(str)
			if(file.ReadFileLine(str))	m_Delay = val(str)
			if(file.ReadFileLine(str))	m_kpp = val(str)
			if(file.ReadFileLine(str))	m_kip = val(str)
			if(file.ReadFileLine(str))	m_PositionErrorThreshold = val(str)
			if(file.ReadFileLine(str))	m_PositionErrorCorrectOn = val(str)
			if(file.ReadFileLine(str))	m_PositionErrorWarningOn = val(str)
			// defocus tracking parameters
			if(file.ReadFileLine(str))	m_wDiv = val(str)
			if(file.ReadFileLine(str))	m_hDiv = val(str)
			if(file.ReadFileLine(str))	m_nr = val(str)
			if(file.ReadFileLine(str))	m_Cs = val(str)	
			if(file.ReadFileLine(str))	m_AC = val(str)
			if(file.ReadFileLine(str))	m_DefocusMin = val(str)
			if(file.ReadFileLine(str))	m_DefocusMax = val(str)
			if(file.ReadFileLine(str))	m_DefocusStep = val(str)
			if(file.ReadFileLine(str))	m_DefocusAccuracy = val(str)
			if(file.ReadFileLine(str))	m_kpf = val(str)
			if(file.ReadFileLine(str))	m_kif = val(str)
			if(file.ReadFileLine(str))	m_DefocusErrorThreshold = val(str)
			if(file.ReadFileLine(str))	m_DefocusErrorCorrectOn = val(str)
			if(file.ReadFileLine(str))	m_DefocusErrorWarningOn = val(str)
			file.CloseFile()
		}
		// group file
		TagGroup Group_File = DLGCreateGroup().DLGIdentifier("#Group_File")
		Group_File.DLGAddElement(DLGCreateLabel("Folder:",8).DLGAnchor("West"))
		Group_File.DLGAddElement(DLGCreateStringField(m_Folder).DLGWidth(28).DLGIdentifier("#Field_Folder"))
		Group_File.DLGAddElement(DLGCreatePushButton("...","ButtonPressed_Browse").DLGIdentifier("#Button_Browse"))
		Group_File.DLGAddElement(DLGCreateLabel("Prefix:",8).DLGAnchor("West"))
		Group_File.DLGAddElement(DLGCreateStringField(m_Prefix).DLGWidth(28).DLGIdentifier("#Field_Prefix"))
		Group_File.DLGAddElement(DLGCreatePushButton("O","ButtonPressed_Open").DLGIdentifier("#Button_Open"))
		// group tilt
		TagGroup Group_Tilt = DLGCreateGroup().DLGIdentifier("#Group_Tilt")
		Group_Tilt.DLGAddElement(DLGCreateLabel("Tilt:",8).DLGAnchor("West"))
		Group_Tilt.DLGAddElement(DLGCreateRealField(round(m_tStart/pi()*1800)/10).DLGWidth(8).DLGIdentifier("#Field_tStart"))
		Group_Tilt.DLGAddElement(DLGCreateRealField(round(m_dt/pi()*1800)/10).DLGWidth(7).DLGIdentifier("#Field_dt"))
		Group_Tilt.DLGAddElement(DLGCreateRealField(round(m_tStop/pi()*1800)/10).DLGWidth(8).DLGIdentifier("#Field_tStop"))
		Group_Tilt.DLGAddElement(DLGCreateLabel("deg",4))
		// group defocus
		TagGroup Group_Defocus = DLGCreateGroup().DLGIdentifier("#Group_Defocus")
		Group_Defocus.DLGAddElement(DLGCreateLabel("Ref. defocus:",15).DLGAnchor("West"))
		Group_Defocus.DLGAddElement(DLGCreateIntegerField(m_RefDefocus*1e9).DLGWidth(21).DLGIdentifier("#Field_RefDefocus"))
		Group_Defocus.DLGAddElement(DLGCreateLabel("nm",4))
		Group_Defocus.DLGAddElement(DLGCreateLabel("Image defocus:",15).DLGAnchor("West"))
		Group_Defocus.DLGAddElement(DLGCreateStringField(m_ImgDefocus).DLGWidth(21).DLGIdentifier("#Field_ImgDefocus"))
		Group_Defocus.DLGAddElement(DLGCreateLabel("nm",4).DLGAnchor("West"))
		// group track
		TagGroup Group_Track = DLGCreateGroup().DLGIdentifier("#Group_Track")
		Group_Track.DLGAddElement(DLGCreateLabel("Track:",10).DLGAnchor("West"))
		Group_Track.DLGAddElement(DLGCreateCheckBox("Position  ",m_PositionTrackingOn).DLGIdentifier("#Check_PositionTrackingOn"))
		Group_Track.DLGAddElement(DLGCreateCheckBox("Defocus   ",m_DefocusTrackingOn).DLGIdentifier("#Check_DefocusTrackingOn"))
		Group_Track.DLGAddElement(DLGCreatePushButton("A","ButtonPressed_Advanced").DLGIdentifier("#Button_Advanced"))
		// group button
		TagGroup Group_Button = DLGCreateGroup().DLGIdentifier("#Group_Button")
		Group_Button.DLGAddElement(DLGCreatePushButton("Start","ButtonPressed_StartStop").DLGIdentifier("#Button_StartStop"))
		Group_Button.DLGAddElement(DLGCreatePushButton("View","ButtonPressed_View").DLGIdentifier("#Button_View"))
		Group_Button.DLGAddElement(DLGCreatePushButton("Acquire","ButtonPressed_Acquire").DLGIdentifier("#Button_Acquire"))
		Group_Button.DLGAddElement(DLGCreatePushButton("Next","ButtonPressed_Next").DLGIdentifier("#Button_Next"))
		Group_Button.DLGAddElement(DLGCreatePushButton("Run","ButtonPressed_Run").DLGIdentifier("#Button_Run"))
		// create dialog
		TagGroup dialog	= DLGCreateDialog("")
		dialog.DLGAddElement(Group_File.DLGTableLayOut(3,3,0))
		dialog.DLGAddElement(Group_Tilt.DLGTableLayOut(5,1,0))
		dialog.DLGAddElement(Group_Defocus.DLGTableLayOut(3,2,0))
		dialog.DLGAddElement(Group_Track.DLGTableLayOut(4,1,0))
		dialog.DLGAddElement(DLGCreateLabel("0 / 0",20).DLGIdentifier("#Label_Progress").DLGAnchor("West"))
		dialog.DLGAddElement(DLGCreateProgressBar("#ProgressBar").DLGFill("X"))
		dialog.DLGAddElement(Group_Button.DLGTableLayOut(5,1,0))
		return self.super.Init(dialog)
	}
	
	void AboutToCloseDocument(object self,number verify )
	{
		// remove thread
		m_Thread.RemoveMainThreadTask()
		// delete components and images
		self.Clear()
		// get settings
		self.GetConfig()
		// write settings
		string name = GetApplicationDirectory(4,1)+"LHC Tomo Dialog Settings.txt"
		number file = name.CreateFileForWriting()
		// configurations
		file.WriteFile(m_Folder+"\n")
		file.WriteFile(m_Prefix+"\n")
		file.WriteFile(m_tStart+"\n")
		file.WriteFile(m_dt+"\n")
		file.WriteFile(m_tStop+"\n")
		file.WriteFile(m_RefDefocus+"\n")
		file.WriteFile(m_ImgDefocus+"\n")
		file.WriteFile(m_PositionTrackingOn+"\n")
		file.WriteFile(m_DefocusTrackingOn+"\n")
		// position tracking parameters
		file.WriteFile(m_PointerColor+"\n")
		file.WriteFile(m_PointerDiameter+"\n")
		file.WriteFile(m_xb+"\n")
		file.WriteFile(m_yb+"\n")
		file.WriteFile(m_zb+"\n")
		file.WriteFile(m_tb+"\n")
		file.WriteFile(m_Delay+"\n")
		file.WriteFile(m_kpp+"\n")
		file.WriteFile(m_kip+"\n")
		file.WriteFile(m_PositionErrorThreshold+"\n")
		file.WriteFile(m_PositionErrorCorrectOn+"\n")
		file.WriteFile(m_PositionErrorWarningOn+"\n")
		// defocus tracking parameters
		file.WriteFile(m_wDiv+"\n")
		file.WriteFile(m_hDiv+"\n")
		file.WriteFile(m_nr+"\n")
		file.WriteFile(m_Cs+"\n")
		file.WriteFile(m_AC+"\n")
		file.WriteFile(m_DefocusMin+"\n")
		file.WriteFile(m_DefocusMax+"\n")
		file.WriteFile(m_DefocusStep+"\n")
		file.WriteFile(m_DefocusAccuracy+"\n")
		file.WriteFile(m_kpf+"\n")
		file.WriteFile(m_kif+"\n")
		file.WriteFile(m_DefocusErrorThreshold+"\n")
		file.WriteFile(m_DefocusErrorCorrectOn+"\n")
		file.WriteFile(m_DefocusErrorWarningOn+"\n")
		file.CloseFile()
	}
	
	void ButtonPressed_Browse(object self)
	{	
		string folder
		if(GetDirectoryDialog("Browse for a directory","",folder))
			self.LookUpElement("#Field_Folder").DLGValue(folder)
	}
	
	void ButtonPressed_Open(object self)
	{
		TagGroup names = m_Folder.LHC_CreateFileNameList(m_Prefix+decimal(m_i,4),".dm3")
		if(names.TagGroupCountTags()==0)
			ShowAlert("Images of current tilt angle were not found.",0)
		else
			for(number i=0;i<names.TagGroupCountTags();i++)
			{
				string name
				names.TagGroupGetIndexedTagAsString(i,name)
				OpenImage(m_Folder+name).ShowImage()
			}
	}
	
	TagGroup ButtonPressed_Advanced(object self)
	{
		// box pointer
		TagGroup Box_TargetPointer = DLGCreateBox("")
		Box_TargetPointer.DLGAddElement(DLGCreateLabel("Pointer color:",18).DLGAnchor("West"))
		TagGroup Choice_Color = DLGCreateChoice(m_PointerColor)
		Choice_Color.DLGAddChoiceItemEntry("black             ")
		Choice_Color.DLGAddChoiceItemEntry("blue")
		Choice_Color.DLGAddChoiceItemEntry("green")
		Choice_Color.DLGAddChoiceItemEntry("cyan")
		Choice_Color.DLGAddChoiceItemEntry("red")
		Choice_Color.DLGAddChoiceItemEntry("pink")
		Choice_Color.DLGAddChoiceItemEntry("yellow")
		Choice_Color.DLGAddChoiceItemEntry("white")
		Box_TargetPointer.DLGAddElement(Choice_Color)
		Box_TargetPointer.DLGAddElement(DLGCreateLabel("",4).DLGAnchor("West"))
		Box_TargetPointer.DLGAddElement(DLGCreateLabel("Pointer diameter:",18).DLGAnchor("West"))
		TagGroup Field_PointerDiameter = DLGCreateIntegerField(m_PointerDiameter*1e9).DLGWidth(20)
		Box_TargetPointer.DLGAddElement(Field_PointerDiameter)
		Box_TargetPointer.DLGAddElement(DLGCreateLabel("nm",4).DLGAnchor("West"))
		// box backlash
		TagGroup Box_Backlash = DLGCreateBox("")
		Box_Backlash.DLGAddElement(DLGCreateLabel("X backlash compensation:",28).DLGAnchor("West"))
		TagGroup Field_xb = DLGCreateIntegerField(m_xb*1e9).DLGWidth(10)
		Box_Backlash.DLGAddElement(Field_xb)
		Box_Backlash.DLGAddElement(DLGCreateLabel("nm",4).DLGAnchor("West"))
		Box_Backlash.DLGAddElement(DLGCreateLabel("Y backlash compensation:",28).DLGAnchor("West"))
		TagGroup Field_yb = DLGCreateIntegerField(m_yb*1e9).DLGWidth(10)
		Box_Backlash.DLGAddElement(Field_yb)
		Box_Backlash.DLGAddElement(DLGCreateLabel("nm",4).DLGAnchor("West"))
		Box_Backlash.DLGAddElement(DLGCreateLabel("Z backlash compensation:",28).DLGAnchor("West"))
		TagGroup Field_zb = DLGCreateIntegerField(m_zb*1e9).DLGWidth(10)
		Box_Backlash.DLGAddElement(Field_zb)
		Box_Backlash.DLGAddElement(DLGCreateLabel("nm",4).DLGAnchor("West"))
		Box_Backlash.DLGAddElement(DLGCreateLabel("Tilt backlash compensation:",28).DLGAnchor("West"))
		TagGroup Field_tb = DLGCreateIntegerField(m_tb/pi()*180).DLGWidth(10)
		Box_Backlash.DLGAddElement(Field_tb)
		Box_Backlash.DLGAddElement(DLGCreateLabel("deg",4).DLGAnchor("West"))
		// box delay
		TagGroup Box_Delay = DLGCreateBox("")
		Box_Delay.DLGAddElement(DLGCreateLabel("Stabilization time:",28).DLGAnchor("West"))
		TagGroup Field_Delay = DLGCreateIntegerField(m_Delay).DLGWidth(10)
		Box_Delay.DLGAddElement(Field_Delay)
		Box_Delay.DLGAddElement(DLGCreateLabel("sec",4))
		// box position PI
		TagGroup Box_PositionPI = DLGCreateBox("")
		Box_PositionPI.DLGAddElement(DLGCreateLabel("Position error Kp:",28).DLGAnchor("West"))
		TagGroup Field_kpp = DLGCreateRealField(m_kpp).DLGWidth(10)
		Box_PositionPI.DLGAddElement(Field_kpp)
		Box_PositionPI.DLGAddElement(DLGCreateLabel("",4))
		Box_PositionPI.DLGAddElement(DLGCreateLabel("Position error Ki:",28).DLGAnchor("West"))
		TagGroup Field_kip = DLGCreateRealField(m_kip).DLGWidth(10)
		Box_PositionPI.DLGAddElement(Field_kip)
		Box_PositionPI.DLGAddElement(DLGCreateLabel("",4))
		// box position error
		TagGroup Box_PositionError = DLGCreateBox("")
		Box_PositionError.DLGAddElement(DLGCreateLabel("Position error threshold:",28).DLGAnchor("West"))
		TagGroup Field_PositionErrorThreshold = DLGCreateIntegerField(m_PositionErrorThreshold*1e9).DLGWidth(10)
		Box_PositionError.DLGAddElement(Field_PositionErrorThreshold)
		Box_PositionError.DLGAddElement(DLGCreateLabel("nm",4).DLGAnchor("West"))
		TagGroup Check_PositionErrorCorrectOn = DLGCreateCheckBox("correct before next tilting",m_PositionErrorCorrectOn)
		Box_PositionError.DLGAddElement(Check_PositionErrorCorrectOn)
		Box_PositionError.DLGAddElement(DLGCreateLabel("").DLGAnchor("West"))
		Box_PositionError.DLGAddElement(DLGCreateLabel("").DLGAnchor("West"))
		TagGroup Check_PositionErrorWarningOn = DLGCreateCheckBox("warn before next tilting   ",m_PositionErrorWarningOn)
		Box_PositionError.DLGAddElement(Check_PositionErrorWarningOn)
		Box_PositionError.DLGAddElement(DLGCreateLabel("").DLGAnchor("West"))
		Box_PositionError.DLGAddElement(DLGCreateLabel("").DLGAnchor("West"))
		// box CTF fitting
		TagGroup Box_CTFFitting = DLGCreateBox("")
		Box_CTFFitting.DLGAddElement(DLGCreateLabel("Number of image divisions:",28).DLGAnchor("West"))
		TagGroup Choice_Div = DLGCreateChoice(log(m_hDiv)/log(2)*2-(m_hDiv>1&&m_wDiv>1))
		Choice_Div.DLGAddChoiceItemEntry("1x1")
		Choice_Div.DLGAddChoiceItemEntry("2x2")
		Choice_Div.DLGAddChoiceItemEntry("2x1")
		Choice_Div.DLGAddChoiceItemEntry("4x4")	
		Choice_Div.DLGAddChoiceItemEntry("4x1")	
		Choice_Div.DLGAddChoiceItemEntry("8x8")	
		Choice_Div.DLGAddChoiceItemEntry("8x1")	
		Box_CTFFitting.DLGAddElement(Choice_Div)
		Box_CTFFitting.DLGAddElement(DLGCreateLabel("",4).DLGAnchor("West"))
		Box_CTFFitting.DLGAddElement(DLGCreateLabel("Number of considered rings:",28).DLGAnchor("West"))
		TagGroup Field_nr = DLGCreateIntegerField(m_nr).DLGWidth(10)
		Box_CTFFitting.DLGAddElement(Field_nr)
		Box_CTFFitting.DLGAddElement(DLGCreateLabel("",4).DLGAnchor("West"))
		Box_CTFFitting.DLGAddElement(DLGCreateLabel("Spherical aberration:",28).DLGAnchor("West"))
		TagGroup Field_Cs = DLGCreateRealField(m_Cs*1e3).DLGWidth(10)
		Box_CTFFitting.DLGAddElement(Field_Cs)
		Box_CTFFitting.DLGAddElement(DLGCreateLabel("mm",4).DLGAnchor("West"))
		Box_CTFFitting.DLGAddElement(DLGCreateLabel("Amplitude contrast:",28).DLGAnchor("West"))
		TagGroup Field_AC = DLGCreateRealField(m_AC).DLGWidth(10)
		Box_CTFFitting.DLGAddElement(Field_AC)
		Box_CTFFitting.DLGAddElement(DLGCreateLabel("",4).DLGAnchor("West"))
		// box defocus finding
		TagGroup Box_DefocusFinding = DLGCreateBox("")
		Box_DefocusFinding.DLGAddElement(DLGCreateLabel("Lower limit of defocus:",28).DLGAnchor("West"))
		TagGroup Field_DefocusMin = DLGCreateIntegerField(m_DefocusMin*1e9).DLGWidth(10)
		Box_DefocusFinding.DLGAddElement(Field_DefocusMin)
		Box_DefocusFinding.DLGAddElement(DLGCreateLabel("nm",4).DLGAnchor("West"))
		Box_DefocusFinding.DLGAddElement(DLGCreateLabel("Upper limit of defocus:",28).DLGAnchor("West"))
		TagGroup Field_DefocusMax = DLGCreateIntegerField(m_DefocusMax*1e9).DLGWidth(10)
		Box_DefocusFinding.DLGAddElement(Field_DefocusMax)
		Box_DefocusFinding.DLGAddElement(DLGCreateLabel("nm",4).DLGAnchor("West"))
		Box_DefocusFinding.DLGAddElement(DLGCreateLabel("Defocus search step:",28).DLGAnchor("West"))
		TagGroup Field_DefocusStep = DLGCreateIntegerField(m_DefocusStep*1e9).DLGWidth(10)
		Box_DefocusFinding.DLGAddElement(Field_DefocusStep)
		Box_DefocusFinding.DLGAddElement(DLGCreateLabel("nm",4).DLGAnchor("West"))
		Box_DefocusFinding.DLGAddElement(DLGCreateLabel("Defocus finding accuracy:",28).DLGAnchor("West"))
		TagGroup Field_DefocusAccuracy = DLGCreateIntegerField(m_DefocusAccuracy*1e9).DLGWidth(10)
		Box_DefocusFinding.DLGAddElement(Field_DefocusAccuracy)
		Box_DefocusFinding.DLGAddElement(DLGCreateLabel("nm",4).DLGAnchor("West"))
		// box defocus PI
		TagGroup Box_DefocusPI = DLGCreateBox("")
		Box_DefocusPI.DLGAddElement(DLGCreateLabel("Defocus error Kp:",28).DLGAnchor("West"))
		TagGroup Field_kpf = DLGCreateRealField(m_kpf).DLGWidth(10)
		Box_DefocusPI.DLGAddElement(Field_kpf)
		Box_DefocusPI.DLGAddElement(DLGCreateLabel("",4))
		Box_DefocusPI.DLGAddElement(DLGCreateLabel("Defocus error Ki:",28).DLGAnchor("West"))
		TagGroup Field_kif = DLGCreateRealField(m_kif).DLGWidth(10)
		Box_DefocusPI.DLGAddElement(Field_kif)
		Box_DefocusPI.DLGAddElement(DLGCreateLabel("",4))
		// box defocus error
		TagGroup Box_DefocusError = DLGCreateBox("")
		Box_DefocusError.DLGAddElement(DLGCreateLabel("Defocus error threshold:",28).DLGAnchor("West"))
		TagGroup Field_DefocusErrorThreshold = DLGCreateIntegerField(m_DefocusErrorThreshold*1e9).DLGWidth(10)
		Box_DefocusError.DLGAddElement(Field_DefocusErrorThreshold)
		Box_DefocusError.DLGAddElement(DLGCreateLabel("nm",4).DLGAnchor("West"))
		TagGroup Check_DefocusErrorCorrectOn = DLGCreateCheckBox("correct before next tilting",m_DefocusErrorCorrectOn)
		Box_DefocusError.DLGAddElement(Check_DefocusErrorCorrectOn)
		Box_DefocusError.DLGAddElement(DLGCreateLabel("").DLGAnchor("West"))
		Box_DefocusError.DLGAddElement(DLGCreateLabel("").DLGAnchor("West"))
		TagGroup Check_DefocusErrorWarningOn = DLGCreateCheckBox("warn before next tilting   ",m_DefocusErrorWarningOn)
		Box_DefocusError.DLGAddElement(Check_DefocusErrorWarningOn)
		Box_DefocusError.DLGAddElement(DLGCreateLabel("").DLGAnchor("West"))
		Box_DefocusError.DLGAddElement(DLGCreateLabel("").DLGAnchor("West"))
		// create tabs
		TagGroup Tab_PositionTracking = DLGCreateTab("Position Tracking")
		Tab_PositionTracking.DLGAddElement(Box_TargetPointer.DLGTableLayOut(3,2,0))
		Tab_PositionTracking.DLGAddElement(Box_Backlash.DLGTableLayOut(3,4,0))
		Tab_PositionTracking.DLGAddElement(Box_Delay.DLGTableLayOut(3,1,0))
		Tab_PositionTracking.DLGAddElement(Box_PositionPI.DLGTableLayOut(3,2,0))
		Tab_PositionTracking.DLGAddElement(Box_PositionError.DLGTableLayOut(3,3,0))
		TagGroup Tab_DefocusTracking = DLGCreateTab("Defocus Tracking")
		Tab_DefocusTracking.DLGAddElement(Box_CTFFitting.DLGTableLayOut(3,4,0))
		Tab_DefocusTracking.DLGAddElement(Box_DefocusFinding.DLGTableLayOut(3,4,0))
		Tab_DefocusTracking.DLGAddElement(Box_DefocusPI.DLGTableLayOut(3,2,0))
		Tab_DefocusTracking.DLGAddElement(Box_DefocusError.DLGTableLayOut(3,3,0))
		TagGroup Tabs = DLGCreateTabList()
		Tabs.DLGAddElement(Tab_PositionTracking)
		Tabs.DLGAddElement(Tab_DefocusTracking)
		// create the dialog
		TagGroup dialog = DLGCreateDialog("Advanced Settings")
		dialog.DLGAddElement(Tabs)
		object DialogObject = Alloc(UIFrame)
		DialogObject.Init(dialog)
		// function of OK pressed
		if(DialogObject.Pose())
		{
			self.SetElementIsEnabled("#Group_Button",0)
			// box pointer
			m_PointerColor = Choice_Color.DLGGetValue()
			if(Field_PointerDiameter.DLGGetValue()<0)
				ShowAlert("Pointer diameter was less than 0.",0)
			else
				m_PointerDiameter = Field_PointerDiameter.DLGGetValue()*1e-9
			// box backlash
			m_xb = Field_xb.DLGGetValue()*1e-9
			m_yb = Field_yb.DLGGetValue()*1e-9
			m_zb = Field_zb.DLGGetValue()*1e-9
			m_tb = Field_tb.DLGGetValue()/180*pi()
			// box delay
			if(Field_Delay.DLGGetValue()<0)
				ShowAlert("Stabilization time was less than 0.",2)
			else
				m_Delay = Field_Delay.DLGGetValue()
			// box position PI
			if(Field_kpp.DLGGetValue()<0 || Field_kpp.DLGGetValue()>1)
				ShowAlert("Position error Kp was out of the range of 0~1.",0)
			else
				m_kpp = Field_kpp.DLGGetValue()
			if(Field_kip.DLGGetValue()<0 || Field_kip.DLGGetValue()>1)
				ShowAlert("Position error Ki was out of the range of 0~1.",0)
			else
				m_kip = Field_kip.DLGGetValue()
			// box position error
			if(Field_PositionErrorThreshold.DLGGetValue()<0)
				ShowAlert("Position error threshold was less than 0",2)
			else
				m_PositionErrorThreshold = Field_PositionErrorThreshold.DLGGetValue()*1e-9
			m_PositionErrorCorrectOn = Check_PositionErrorCorrectOn.DLGGetValue()
			m_PositionErrorWarningOn = Check_PositionErrorWarningOn.DLGGetValue()
			// box CTF fitting
			m_hDiv = 2**floor((Choice_Div.DLGGetValue()+1)/2)
			m_wDiv = Choice_Div.DLGGetValue().mod(2)==0? 1:m_hDiv
			if(Field_nr.DLGGetValue()<=0)
				ShowAlert("Number of considered rings must be greater than 0.",0)
			else
				m_nr = Field_nr.DLGGetValue()
			m_Cs = Field_Cs.DLGGetValue()*1e-3
			m_AC = Field_AC.DLGGetValue()
			// box defocus finding
			if(Field_DefocusMax.DLGGetValue()>0)
				ShowAlert("Upper limit of defocus must be negative or zero.",0)
			else
				m_DefocusMax = Field_DefocusMax.DLGGetValue()*1e-9
			if(Field_DefocusMin.DLGGetValue()>Field_DefocusMax.DLGGetValue())
				ShowAlert("Upper limit of defocus must be greater than or equal to lower limit of defocus.",0)
			else
				m_DefocusMin = Field_DefocusMin.DLGGetValue()*1e-9
			if(Field_DefocusStep.DLGGetValue()<=0)
				ShowAlert("Defocus search step must be greater than 0.",0)
			else
				m_DefocusStep = Field_DefocusStep.DLGGetValue()*1e-9
			if(Field_DefocusAccuracy.DLGGetValue()<=0)
				ShowAlert("Defocus accuracy must be must be greater than 0.",0)
			else
				m_DefocusAccuracy = Field_DefocusAccuracy.DLGGetValue()*1e-9
			// box kif
			if(Field_kpf.DLGGetValue()<0 || Field_kpf.DLGGetValue()>1)
				ShowAlert("Defocus error Kp was out of the range of 0~1.",0)
			else
				m_kpf = Field_kpf.DLGGetValue()
			if(Field_kif.DLGGetValue()<0 || Field_kif.DLGGetValue()>1)
				ShowAlert("Defocus error Ki was out of the range of 0~1.",0)
			else
				m_kif = Field_kif.DLGGetValue()
			// box defocus error
			if(Field_DefocusErrorThreshold.DLGGetValue()<0)
				ShowAlert("Defocus error threshold was less than 0",2)
			else
				m_DefocusErrorThreshold = Field_DefocusErrorThreshold.DLGGetValue()*1e-9
			m_DefocusErrorCorrectOn = Check_DefocusErrorCorrectOn.DLGGetValue()
			m_DefocusErrorWarningOn = Check_DefocusErrorWarningOn.DLGGetValue()
			// apply settings
			if(m_i>0)
			{
				self.UpdateComponentRect(m_Box0,"Box",0)
				self.UpdateComponentRect(m_Box1,"Box",1)
				self.UpdateComponentRect(m_Box2,"Box",2)
				self.UpdateComponentRect(m_Circle0,"Circle",0)
				self.UpdateComponentRect(m_Circle1,"Circle",1)
				self.UpdateComponentRect(m_Circle2,"Circle",2)
				m_Box0.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
				m_Box1.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
				m_Box2.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
				m_Circle0.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
				m_Circle1.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
				m_Circle2.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
				m_AnnotationL.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
				m_AnnotationR.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
				if(self.LookUpElement("#Label_Progress").DLGGetTitle()!=""+m_i+" / "+m_n)
					self.CalculateDefocusError()
				self.UpdateImgF()
				self.ResultLog()
			}
			self.SetElementIsEnabled("#Group_Button",1)
		}
	}
	
	void ButtonPressed_StartStop(object self)
	{
		if(self.LookUpElement("#Button_StartStop").DLGGetTitle()=="Start")
		{
			// get TEM info
		//	m_V = 120e3
			m_V = LHC_GetVoltage()
			m_Mag = LHC_GetMag()
			m_a = m_Mag.LHC_GetRotationAngle()
			m_k = m_Mag.LHC_GetPixelLength()
			object camera = CM_GetCurrentCamera()
			object AcqParams = camera.CM_GetCameraAcquisitionParameterSet("Imaging","View","Focus",0)
			number xbin, ybin
		//	xbin = ybin = 4
			AcqParams.CM_GetBinning(xbin,ybin)
			if(xbin!=ybin)
			{
				ShowAlert("XY binnings of viewer were different.",0)
				return
			}
			else
				m_Bin = xbin
			// get config info
			self.GetConfig()
			// check config info
			if(m_Folder.DoesDirectoryExist())
			{
				TagGroup files = m_Folder.GetFilesInDirectory(1)
				if(files.TagGroupCountTags()>0)
				{
					if(OKCancelDialog("Folder:\n"+m_Folder+"\nis not empty, clear it?"))
						LHC_ClearFolder(m_Folder)
					else
						return
				}
			}
			else if(OKCancelDialog("Folder:\n"+m_Folder+"\ndoes not exist, create it?"))
				CreateDirectory(m_Folder)
			else
				return
			if(m_dt==0)
			{
				ShowAlert("Tilt step was 0.",0)
				return
			}
			if(m_RefDefocus>0)
			{
				ShowAlert("Ref. defocus was greater than 0.",0)
				return
			}
			if(abs(LHC_GetGonT()-m_tStart)<abs(m_dt))
			{
				m_dt = abs(m_dt)*sgn(m_tStop-m_tStart)
				// show confirm info
				string info = "Heigh voltage:	"+m_V/1e3+" kV\n"
				info += "Magnification:	"+m_Mag/1e3+" k\n"
				info += "Rotation angle:	"+m_a/pi()*180+" deg\n"
				info += "Pixel length:	"+m_k*1e10+" A\n"
				info += "Viewer binning:	"+m_Bin+"\n"
				info += "Folder:		"+m_Folder+"\n"
				info += "Prefix:		"+m_Prefix+"\n"
				info += "Tilt:		from "+m_tStart/pi()*180+" to "+m_tStop/pi()*180+" deg, "+m_dt/pi()*180+" deg/step\n"
				info += "Ref. defocus:	"+m_RefDefocus*1e9+" nm\n"
				if(m_PositionTrackingOn && m_DefocusTrackingOn)
					info += "Track:		position & defocus"
				else if(m_PositionTrackingOn)
					info += "Track:		position"
				else if(m_DefocusTrackingOn)
					info += "Track:		defocus"
				if(!OKCancelDialog("Please confirm the following settings:\n\n"+info))
					return
				result(info+"\n")
				(m_Folder+m_Prefix+"Log.txt").LHC_Result(info+"\n")
			}
			else if(OKCancelDialog("Tilt to start angle with position and defocus tracking?"))
			{
				m_tStop = m_tStart
				m_tStart = LHC_GetGonT()
				if(!GetNumber("Input the tilt step (deg) for tracking to start angle:",m_dt/pi()*180,m_dt))
					return
				m_dt = abs(m_dt/180*pi())*sgn(m_tStop-m_tStart)
				m_Prefix = "TrackToStartAngle"
				m_PositionTrackingOn = 1
				m_DefocusTrackingOn = 1
			}
			else
				return
			// disable buttons and configurations
			self.SetElementIsEnabled("#Group_Button",0)
			self.SetElementIsEnabled("#Field_Folder",0)
			self.SetElementIsEnabled("#Button_Browse",0)
			self.SetElementIsEnabled("#Field_Prefix",0)
			self.SetElementIsEnabled("#Field_tStart",0)
			self.SetElementIsEnabled("#Field_dt",0)
			self.SetElementIsEnabled("#Field_tStop",0)
			self.SetElementIsEnabled("#Field_RefDefocus",0)
			self.SetElementIsEnabled("#Check_PositionTrackingOn",0)
			self.SetElementIsEnabled("#Check_DefocusTrackingOn",0)
			// init control parameters
			m_n = floor((m_tStop-m_tStart)/m_dt)+1
			m_i = 1
			m_Corrected = 0
			m_ux = m_cx = m_ex = m_exi = 0
			m_uy = m_cy = m_ey = m_eyi = 0
			m_uf = m_cf = m_ef = m_efi = 0
			// update progress
			self.LookUpElement("#Label_Progress").DLGTitle(""+m_i+" / "+m_n)
			self.LookUpElement("#ProgressBar").DLGValue(m_i/m_n)
			// create images
		//	m_Img0 = OpenImage(GetApplicationDirectory(2,1)+"1.dm3").LHC_Resize(1024,1024)*0
			m_Img0 = camera.CM_CreateImageForAcquire(AcqParams,"")
			m_Img1 = m_Img0
			m_Img2 = m_Img0
			m_ImgF = m_Img0
			m_Img0.ShowImage()
			m_Img1.ShowImage()
			m_Img2.ShowImage()
			m_ImgF.ShowImage()
			m_Img0.SetName("#"+m_i+" "+m_Prefix)
			m_Img1.SetName("")
			m_Img2.SetName("")
			m_ImgF.SetName("#"+m_i)
			m_Img0.GetSize(m_w,m_h)
			m_ImgE := realimage("",8,m_n+1,3)
			ImageDocument imgDoc = CreateImageDocument("")
			ImageDisplay disp = imgDoc.ImageDocumentAddImageDisplay(m_ImgE,3)
			number limit = max(m_w,m_h)*m_Bin*m_k/2*1e9
			disp.LinePlotImageDisplaySetContrastLimits(-limit,limit)
			disp.LinePlotImageDisplaySetDoAutoSurvey(0,0)
			disp.LinePlotImageDisplaySetSliceDrawingStyle(0,1)
			disp.LinePlotImageDisplaySetSliceDrawingStyle(1,1)
			disp.LinePlotImageDisplaySetSliceDrawingStyle(2,1)
			imgDoc.ImageDocumentShow()
			disp.LinePlotImageDisplaySetLegendShown(1)
			object SliceEx = disp.ImageDisplayGetSliceIDbyIndex(0)
			disp.ImageDisplaySetSliceLabelbyID(SliceEx,"X pos.")
			object SliceEy = disp.ImageDisplayGetSliceIDbyIndex(1)
			disp.ImageDisplaySetSliceLabelbyID(SliceEy,"Y pos.")
			object SliceEf = disp.ImageDisplayGetSliceIDbyIndex(2)
			disp.ImageDisplaySetSliceLabelbyID(SliceEf,"Defocus")
			m_ImgE.ImageSetDimensionUnitString(0,"Image Number")
			m_ImgE.ImageSetIntensityUnitString("nm")
			m_ImgE.SetName("Error")
			// add ROI listeners	
			self.AddROIListener(m_Img0,"Img0MouseClick")
			self.AddROIListener(m_ImgF,"ImgFMouseClick")
			// add components
			ImageDisplay disp0 = m_Img0.ImageGetImageDisplay(0)
			ImageDisplay disp1 = m_Img1.ImageGetImageDisplay(0)
			ImageDisplay disp2 = m_Img2.ImageGetImageDisplay(0)
			m_Box0 = disp0.ComponentAddNewComponent(5,0,0,0,0)
			m_Box1 = disp1.ComponentAddNewComponent(5,0,0,0,0)
			m_Box2 = disp2.ComponentAddNewComponent(5,0,0,0,0)
			m_Box0.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
			m_Box1.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
			m_Box2.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
			m_Circle0 = disp0.ComponentAddNewComponent(6,0,0,0,0)
			m_Circle1 = disp1.ComponentAddNewComponent(6,0,0,0,0)
			m_Circle2 = disp2.ComponentAddNewComponent(6,0,0,0,0)
			m_Circle0.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
			m_Circle1.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
			m_Circle2.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
			ImageDisplay dispF = m_ImgF.ImageGetImageDisplay(0)
			m_AnnotationL = dispF.ComponentAddNewComponent(13,0,0,0,0)
			m_AnnotationL.ComponentSetFontSize(40)
			m_AnnotationR = dispF.ComponentAddNewComponent(13,0,m_w/2,0,0)
			m_AnnotationR.ComponentSetFontSize(40)
			m_AnnotationL.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
			m_AnnotationR.ComponentSetForegroundColor(mod(m_PointerColor/4,2),mod(m_PointerColor/2,2),mod(m_PointerColor,2))
			// update components
			self.UpdateComponentRect(m_Box0,"Box",0)
			self.UpdateComponentRect(m_Box1,"Box",1)
			self.UpdateComponentRect(m_Box2,"Box",2)
			self.UpdateComponentRect(m_Circle0,"Circle",0)
			self.UpdateComponentRect(m_Circle1,"Circle",1)
			self.UpdateComponentRect(m_Circle2,"Circle",2)
			// update ImgF
			m_ImgFLMode = 0
			m_ImgFRMode = 1
			self.UpdateImgF()
			// change window positions
			number WindowSize0 = 512
			number WindowSize12F = 256
			number FrameSize0x, FrameSize0y, FrameSize12Fx, FrameSize12Fy
			m_Img0.SetWindowSize(WindowSize0,WindowSize0)
			m_Img1.SetWindowSize(WindowSize12F,WindowSize12F)
			m_Img2.SetWindowSize(WindowSize12F,WindowSize12F)
			m_ImgF.SetWindowSize(WindowSize12F,WindowSize12F)
			m_Img0.ImageGetOrCreateImageDocument().ImageDocumentGetWindow().WindowGetFrameSize(FrameSize0x,FrameSize0y)
			m_Img1.ImageGetOrCreateImageDocument().ImageDocumentGetWindow().WindowGetFrameSize(FrameSize12Fx,FrameSize12Fy)
			number top = 0
		//	number left = 0
			number left = 140
			m_Img2.ImageGetOrCreateImageDocument().ImageDocumentGetWindow().WindowSetFramePosition(left,top)
			m_Img1.ImageGetOrCreateImageDocument().ImageDocumentGetWindow().WindowSetFramePosition(left+FrameSize12Fx,top)
			m_Img0.ImageGetOrCreateImageDocument().ImageDocumentGetWindow().WindowSetFramePosition(left+FrameSize12Fx*2,top)
			m_ImgF.ImageGetOrCreateImageDocument().ImageDocumentGetWindow().WindowSetFramePosition(left+FrameSize12Fx*2+FrameSize0x,top)
			m_ImgE.ImageGetOrCreateImageDocument().ImageDocumentGetWindow().WindowSetFramePosition(left,top+FrameSize12Fy)
			m_ImgE.ImageGetOrCreateImageDocument().ImageDocumentGetWindow().WindowSetFrameSize(FrameSize12Fx*2,FrameSize0y-FrameSize12Fy)
			self.GetFrameWindow().WindowSetFramePosition(left+FrameSize12Fx*2+FrameSize0x,top+FrameSize12Fy)
			// reset back lash
			if(TwoButtonDialog("Reset backlash?","Yes","Skip"))
			{
				number MagPointer = LHC_GetMagPointer()
				number IllAperture = LHC_GetIllAperture()
				LHC_SetIllAperture(4)
				sleep(1)
				LHC_SetMagPointer(7)
				sleep(2)
			//	image img1 := OpenImage(GetApplicationDirectory(2,1)+"1.dm3").LHC_Resize(1024,1024)
				image img1 := camera.CM_AcquireImage(AcqParams)
				LHC_ResetBacklash(m_xb,m_yb,m_zb,m_tb)
				sleep(m_Delay)
			//	image img2 := OpenImage(GetApplicationDirectory(2,1)+"1.dm3").LHC_Resize(1024,1024)
				image img2 := camera.CM_AcquireImage(AcqParams)
				number sx,sy
				LHC_MeasureShift(img1,img2,sx,sy)
				number mag = LHC_GetMag()
				number a = mag.LHC_GetRotationAngle()
				number k = mag.LHC_GetPixelLength()
				number ux = -sx*m_Bin*k
				number uy = sy*m_Bin*k
				self.RegulatePosition(ux,uy,a)
				sleep(m_Delay)
			//	image img3 := OpenImage(GetApplicationDirectory(2,1)+"1.dm3").LHC_Resize(1024,1024)
				image img3 := camera.CM_AcquireImage(AcqParams)
				// result
				result("X backlash: "+round(ux*1e9)+"nm\nY backlash: "+round(uy*1e9)+"nm\n")
				if(m_Prefix!="TrackToStartAngle")
					(m_Folder+m_Prefix+"Log.txt").LHC_Result("X backlash: "+round(ux*1e9)+"nm\nY backlash: "+round(uy*1e9)+"nm\n")
				// show Mag10 img
				img1 := img1.rotate(-a+m_a)
				img1.ShowImage()
				img1.SetName("Before reseting backlash @Mag10k")
				img2 := img2.rotate(-a+m_a)
				img2.ShowImage()
				img2.SetName("After reseting backlash @Mag10k")
				img3 := img3.rotate(-a+m_a)
				img3.ShowImage()
				img3.SetName("After correcting position @Mag10k")
				LHC_SetMagPointer(MagPointer)
				sleep(1)
				LHC_SetIllAperture(IllAperture)
				ShowAlert("Backlash was reseted",2)
			}
			// show result
			string str = "#    Tilt(deg) X pos.(nm): U     Um    E     Y pos.(nm): U     Um    E     Defocus(nm): U     Um    E\n"
			result(DateStamp()+"	start\n"+str)
			if(m_Prefix!="TrackToStartAngle")
				(m_Folder+m_Prefix+"Log.txt").LHC_Result(DateStamp()+"	start\n"+str)
			// enable buttons
			self.SetElementIsEnabled("#Group_Button",1)
			self.SetElementIsEnabled("#Button_View",1)
			if(m_Prefix!="TrackToStartAngle")
				self.SetElementIsEnabled("#Button_Acquire",1)
			self.SetElementIsEnabled("#Button_Run",1)
			self.LookUpElement("#Button_StartStop").DLGTitle("Stop")
		}
		else
		{
			if(m_i<m_n)
				if(!OKCancelDialog("Abort current task?"))
					return
			// disable buttons
			self.SetElementIsEnabled("#Group_Button",0)
			self.SetElementIsEnabled("#Button_View",0)
			self.SetElementIsEnabled("#Button_Acquire",0)
			self.SetElementIsEnabled("#Button_Next",0)
			self.SetElementIsEnabled("#Button_Run",0)
			self.SetElementIsEnabled("#Button_Open",0)
			// show result
			result(DateStamp()+"	stop\n")
			if(m_Prefix!="TrackToStartAngle")
			{
				(m_Folder+m_Prefix+"Log.txt").LHC_Result(DateStamp()+"	stop\n")
				if(TwoButtonDialog("Save error curves as .dm3 file?","Yes","No"))
					m_ImgE.SaveImage(m_Folder+m_Prefix+"ErrorCurves.dm3")
			}
			// update progress
			m_i = m_n = 0
			self.LookUpElement("#Label_Progress").DLGTitle(""+m_i+" / "+m_n)
			self.LookUpElement("#ProgressBar").DLGValue(m_i/m_n)
			// delete components and images
			self.Clear()
			// enable buttons and configeration
			self.SetElementIsEnabled("#Group_Button",1)
			self.SetElementIsEnabled("#Field_Folder",1)
			self.SetElementIsEnabled("#Button_Browse",1)
			self.SetElementIsEnabled("#Field_Prefix",1)
			self.SetElementIsEnabled("#Field_tStart",1)
			self.SetElementIsEnabled("#Field_dt",1)
			self.SetElementIsEnabled("#Field_tStop",1)
			self.SetElementIsEnabled("#Field_RefDefocus",1)
			self.SetElementIsEnabled("#Check_PositionTrackingOn",1)
			self.SetElementIsEnabled("#Check_DefocusTrackingOn",1)
			self.LookUpElement("#Button_StartStop").DLGTitle("Start")
		}
	}
	
	void ButtonPressed_View(object self)
	{
		// disable buttons
		self.SetElementIsEnabled("#Group_Button",0)
		// acquire image (view mode)
		object camera = CM_GetCurrentCamera()
		object AcqParams = camera.CM_GetCameraAcquisitionParameterSet("Imaging","View","Focus",0)
	//	image img := OpenImage(GetApplicationDirectory(2,1)+"1.dm3")
		image img := camera.CM_AcquireImage(AcqParams)
		m_Img0 = img.LHC_Resize(m_w,m_h)
		self.LookUpElement("#Label_Progress").DLGTitle(""+m_i+" / "+m_n+"   viewed")
		// analysis
		self.CalculatePositionError()
		self.UpdateComponentRect(m_Circle0,"Circle",0)
		self.CalculateDefocusError()
		self.UpdateImgF()
		// result
		self.ResultLog()
		// correct and review
		if(self.CorrectErrorIfNecessary())
		{
			m_Corrected = 1
			self.ButtonPressed_View()
			return
		}
		self.WarnIfNecessary()
		// enable buttons
		self.SetElementIsEnabled("#Group_Button",1)
		if(m_Prefix=="TrackToStartAngle")
			self.SetElementIsEnabled("#Button_Next",1)
	}
	
	void ButtonPressed_Acquire(object self)
	{
		// disable buttons
		self.SetElementIsEnabled("#Group_Button",0)
		// acquire images
		object camera = CM_GetCurrentCamera()
		object AcqParams = camera.CM_GetCameraAcquisitionParameterSet("Imaging","Acquire","Record",0)
		number FocusDistance = LHC_GetFocusDistance()
		number count
		image DefocusList := LHC_Val(self.LookUpElement("#Field_ImgDefocus").DLGGetStringValue(),count)*1e-9
		number IsTargetDefocusIncluded = 0
		for(number i=0;i<count;i++)
		{
			LHC_SetFocusDistance(FocusDistance-m_RefDefocus+DefocusList.GetPixel(i,0))
		//	image img := OpenImage(GetApplicationDirectory(2,1)+"1.dm3")
			image img := camera.CM_AcquireImage(AcqParams)
			img.SaveImage(m_Folder+m_Prefix+decimal(m_i,4)+"DF"+round(DefocusList.GetPixel(i,0)*1e9)+"nm.dm3")
			// copy image
			if(abs(DefocusList.GetPixel(i,0)-m_RefDefocus)<m_DefocusAccuracy)
			{
				m_Img0 = img.LHC_Resize(m_w,m_h)
				IsTargetDefocusIncluded = 1
			}
		}
		LHC_SetFocusDistance(FocusDistance)
		if(!IsTargetDefocusIncluded)
		{
		//	image img := OpenImage(GetApplicationDirectory(2,1)+"1.dm3")
			image img := camera.CM_AcquireImage(AcqParams)
			m_Img0 = img.LHC_Resize(m_w,m_h)
		}
		self.LookUpElement("#Label_Progress").DLGTitle(""+m_i+" / "+m_n+"   acquired")
		// analysis
		self.CalculatePositionError()
		self.UpdateComponentRect(m_Circle0,"Circle",0)
		self.CalculateDefocusError()
		self.UpdateImgF()
		// result
		self.ResultLog()
		// correct and re-acquire
		if(self.CorrectErrorIfNecessary())
		{
			m_Corrected = 1
			self.ButtonPressed_Acquire()
			return
		}
		self.WarnIfNecessary()
		// enable buttons
		self.SetElementIsEnabled("#Group_Button",1)
		self.SetElementIsEnabled("#Button_Next",1)
		self.SetElementIsEnabled("#Button_Open",1)
	}
	
	void ButtonPressed_Next(object self)
	{
		// end
		if(m_i==m_n)
		{
			m_Run = 0
			ShowAlert("Finished.",2)
			return
		}
		// disable buttons
		self.SetElementIsEnabled("#Group_Button",0)
		// move to next angle
		LHC_SetGonT(LHC_GetGonT()+m_dt)
		LHC_ResetBacklash(0,0,0,m_tb)
		// track position
		if(m_PositionTrackingOn)
		{
			if(m_i>1)
			{
				m_exi += m_ex + m_cx
				m_eyi += m_ey + m_cy
			}
			m_ux = m_kpp*m_ex + m_kip*m_exi
			m_uy = m_kpp*m_ey + m_kip*m_eyi
			self.RegulatePosition(m_ux,m_uy,m_a)
			sleep(m_Delay)
		}
		// track focus
		if(m_DefocusTrackingOn)
		{
			if(m_i>1)
				m_efi += m_ef + m_cf
			m_uf = m_kpf*m_ef + m_kif*m_efi
			self.RegulateDefocus(m_uf)
		}
		// update progress
		m_i++
		m_Corrected = 0
		m_cx = m_cy = m_cf = 0
		self.LookUpElement("#Label_Progress").DLGTitle(""+m_i+" / "+m_n)
		self.LookUpElement("#ProgressBar").DLGValue(m_i/m_n)
		// update images
		m_Img2 = m_Img1
		m_Img1 = m_Img0
		m_Img0 = 0
		m_Img2.SetName(m_Img1.GetName())
		m_Img1.SetName(m_Img0.GetName())
		m_Img0.SetName("#"+m_i+" "+m_Prefix)
		self.UpdateComponentRect(m_Circle2,"Circle",2)
		self.UpdateComponentRect(m_Circle1,"Circle",1)
		self.UpdateComponentRect(m_Circle0,"Circle",0)
		self.UpdateImgF()
		// enable buttons
		self.SetElementIsEnabled("#Group_Button",1)
		self.SetElementIsEnabled("#Button_Next",0)
		self.SetElementIsEnabled("#Button_Open",0)
	}
	
	void ButtonPressed_Run(object self)
	{
		if(OKCancelDialog("Press \"Shift\" key to break"))
			m_Run = 1
	}
	
	void ThreadHandler(object self)
	{
		if(!m_Run)
			return
		if(ShiftDown())
		{
			m_Run = 0
			ShowAlert("Auto run is broken.",2)
			return
		}
		if(m_Prefix=="TrackToStartAngle")
		{
			if(self.LookUpElement("#Label_Progress").DLGGetTitle()==""+m_i+" / "+m_n+"   viewed")
				self.ButtonPressed_Next()
			else
				self.ButtonPressed_View()
		}
		else
		{
			if(self.LookUpElement("#Label_Progress").DLGGetTitle()==""+m_i+" / "+m_n+"   acquired")
				self.ButtonPressed_Next()
			else
				self.ButtonPressed_Acquire()
		}
	}
	
	void Img0MouseClick(Object self, Number e_fl, ImageDisplay ImgDisp, Number r_fl, Number r_fl2, ROI r)
	{
		// verify it is the proper ROI
		if(r.ROIGetName()!="Img0MouseClick")
			return
		// verify it is not autorun
		if(m_Run)
			return
		// get the mouse position
		number WinX, WinY
		DocumentWindow win = ImgDisp.ImageDisplayGetImage().ImageGetOrCreateImageDocument().ImageDocumentGetWindow()
		win.WindowGetMousePosition(WinX,WinY)
		// compute the mouse-coordinates as image coordinates
		number C2Wox, C2Woy, C2Wsx, C2Wsy
		ImgDisp.ComponentGetChildToWindowTransform(C2Wox, C2Woy, C2Wsx, C2Wsy)
		number x = trunc((WinX - C2Wox) / C2Wsx)
		number y = trunc((WinY - C2Woy) / C2Wsy)
		// pointer position
		number px = -(x-m_w/2)*m_Bin*m_k
		number py = (y-m_h/2)*m_Bin*m_k
		// redefine target or redefine defocus or move image
		if(!ControlDown())
		{
			m_ex = px
			m_ey = py
			m_ImgE.SetPixel(m_i,0,m_ex*1e9)
			m_ImgE.SetPixel(m_i,1,m_ey*1e9)
			self.UpdateComponentRect(m_Circle0,"Circle",0)
			self.ResultLog()
		}
		else if(OKCancelDialog("Move image?"))
		{
			self.RegulatePosition(px,py,m_a)
			m_cx += px
			m_cy += py
			self.SetElementIsEnabled("#Button_Next",0)
			if(OKCancelDialog("Image has been moved. View now?"))
				self.ButtonPressed_View()
			else
				self.ResultLog()
		}
	}
	
	void ImgFMouseClick(Object self, Number e_fl, ImageDisplay ImgDisp, Number r_fl, Number r_fl2, ROI r)
	{
		// verify it is the proper ROI
		if(r.ROIGetName()!="ImgFMouseClick")
			return
		// verify it is not autorun
		if(m_Run)
			return
		// get the mouse position
		number WinX, WinY
		DocumentWindow win = ImgDisp.ImageDisplayGetImage().ImageGetOrCreateImageDocument().ImageDocumentGetWindow()
		win.WindowGetMousePosition(WinX,WinY)
		// compute the mouse-coordinates as image coordinates
		number C2Wox, C2Woy, C2Wsx, C2Wsy
		ImgDisp.ComponentGetChildToWindowTransform(C2Wox, C2Woy, C2Wsx, C2Wsy)
		number x = trunc((WinX - C2Wox) / C2Wsx)
		number y = trunc((WinY - C2Woy) / C2Wsy)
		// left: change focus/change show mode, right: redefine defocus feedback/change show mode
		if(x>=0 && x<m_w/2 && y>=0 && y<m_h)
		{
			if(ControlDown())
			{
				number df
				if(GetNumber("Increase actual defocus by (nm):",0,df))
				{
					df *= 1e-9
					self.RegulateDefocus(df)
					m_cf += df
					self.SetElementIsEnabled("#Button_Next",0)
					if(OKCancelDialog("Defocus has been changed. View now?"))
						self.ButtonPressed_View()
					else
						self.ResultLog()
				}
			}
			else
				m_ImgFLMode = !m_ImgFLMode
		}
		if(x>=m_w/2 && x<m_w && y>=0 && y<m_h)
		{
			if(ControlDown())
			{
				number defocus = m_RefDefocus-m_ef
				if(GetNumber("Correct defocus feedback value (nm):",defocus*1e9,defocus))
				{
					defocus *= 1e-9
					m_ef = m_RefDefocus-defocus
					m_ImgE.SetPixel(m_i,2,m_ef*1e9)
					m_ImgF.SetName("#"+m_i+" DF"+round(defocus*1e9)+"nm")
					self.ResultLog()
				}
			}
			else
				m_ImgFRMode = !m_ImgFRMode
		}
		self.UpdateImgF()
	}
}

void main(void)
{
	object dialog = Alloc(LHC_TomoDialog).Init()
	dialog.Display("Tomo")
	dialog.SetElementIsEnabled("#Button_View",0)
	dialog.SetElementIsEnabled("#Button_Acquire",0)
	dialog.SetElementIsEnabled("#Button_Next",0)
	dialog.SetElementIsEnabled("#Button_Run",0)
	dialog.SetElementIsEnabled("#Button_Open",0)
}

main()