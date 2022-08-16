Class LHC_FindDefocusDialog: UIFrame
{
	string m_Folder
	TagGroup m_ImageNameList
	number m_n, m_i
	number m_wDiv, m_hDiv
	number m_a
	number m_nr
	number m_k, m_V, m_Cs, m_AC
	number m_DefocusMin, m_DefocusMax, m_DefocusStep, m_DefocusAccuracy
	number m_Thread, m_Run
	
	LHC_FindDefocusDialog(object self)
	{
		result("DF dialog created\n")
	}
	
	~LHC_FindDefocusDialog(object self)
	{
		result("DF dialog destoryed\n")
	}
	
	object Init(object self)
	{
		// add thread
		m_Run = 0
		m_Thread = self.AddMainThreadPeriodicTask("ThreadHandler",0.1)
		// init members
		m_Folder = GetApplicationDirectory(2,1)
		m_wDiv = m_hDiv = 1
		m_a = 0
		m_nr = 2
		m_V = 120e3
		m_Cs = 2.2e-3
		m_AC = 0.15
		m_DefocusMin = -5000e-9
		m_DefocusMax = -100e-9
		m_DefocusStep = 100e-9
		m_DefocusAccuracy = 1e-9
		// group file
		TagGroup Group_File = DLGCreateGroup()
		Group_File.DLGAddElement(DLGCreateLabel("Source:").DLGAnchor("West"))
		TagGroup Choice_Source = DLGCreateChoice(0).DLGIdentifier("#Choice_Source")
		Choice_Source.DLGAddChoiceItemEntry("Front image")
		Choice_Source.DLGAddChoiceItemEntry("Images in a folder")
		Group_File.DLGAddElement(Choice_Source)
		Group_File.DLGAddElement(DLGCreateLabel(""))
		Group_File.DLGAddElement(DLGCreateLabel("Folder:").DLGAnchor("West"))
		Group_File.DLGAddElement(DLGCreateStringField(m_Folder).DLGWidth(23).DLGIdentifier("#Field_Folder"))
		Group_File.DLGAddElement(DLGCreatePushButton("...","ButtonPressed_Browse").DLGIdentifier("#Button_Browse"))
		// group config
		TagGroup Group_Config = DLGCreateGroup()
		Group_Config.DLGAddElement(DLGCreateLabel("Image division:").DLGAnchor("West"))
		TagGroup Choice_Div = DLGCreateChoice(0).DLGIdentifier("#Choice_Div")
		Choice_Div.DLGAddChoiceItemEntry("1x1   ")
		Choice_Div.DLGAddChoiceItemEntry("2x2")
		Choice_Div.DLGAddChoiceItemEntry("2x1")
		Choice_Div.DLGAddChoiceItemEntry("4x4")	
		Choice_Div.DLGAddChoiceItemEntry("4x1")	
		Choice_Div.DLGAddChoiceItemEntry("8x8")	
		Choice_Div.DLGAddChoiceItemEntry("8x1")	
		Group_Config.DLGAddElement(Choice_Div)
		Group_Config.DLGAddElement(DLGCreateLabel(""))
		Group_Config.DLGAddElement(DLGCreateLabel("Tilt axis:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateRealField(m_a/pi()*180).DLGWidth(12).DLGIdentifier("#Field_a"))
		Group_Config.DLGAddElement(DLGCreateLabel("deg"))	
		Group_Config.DLGAddElement(DLGCreateLabel("Considered rings:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateIntegerField(m_nr).DLGWidth(12).DLGIdentifier("#Field_nr"))
		Group_Config.DLGAddElement(DLGCreateLabel(""))	
		Group_Config.DLGAddElement(DLGCreateLabel("Pixel length:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateRealField(m_k*1e10).DLGWidth(12).DLGIdentifier("#Field_k"))
		Group_Config.DLGAddElement(DLGCreateLabel("A"))	
		Group_Config.DLGAddElement(DLGCreateLabel("High voltage:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateIntegerField(m_V/1e3).DLGWidth(12).DLGIdentifier("#Field_V"))
		Group_Config.DLGAddElement(DLGCreateLabel("kV"))	
		Group_Config.DLGAddElement(DLGCreateLabel("Spherical aberration:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateRealField(m_Cs*1e3).DLGWidth(12).DLGIdentifier("#Field_Cs"))
		Group_Config.DLGAddElement(DLGCreateLabel("mm"))	
		Group_Config.DLGAddElement(DLGCreateLabel("Amplitude contrast:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateRealField(m_AC).DLGWidth(12).DLGIdentifier("#Field_AC"))
		Group_Config.DLGAddElement(DLGCreateLabel(""))	
		Group_Config.DLGAddElement(DLGCreateLabel("Lower limit:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateIntegerField(m_DefocusMin*1e9).DLGWidth(12).DLGIdentifier("#Field_DefocusMin"))
		Group_Config.DLGAddElement(DLGCreateLabel("nm"))	
		Group_Config.DLGAddElement(DLGCreateLabel("Upper limit:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateIntegerField(m_DefocusMax*1e9).DLGWidth(12).DLGIdentifier("#Field_DefocusMax"))
		Group_Config.DLGAddElement(DLGCreateLabel("nm"))	
		Group_Config.DLGAddElement(DLGCreateLabel("Search step:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateIntegerField(m_DefocusStep*1e9).DLGWidth(12).DLGIdentifier("#Field_DefocusStep"))
		Group_Config.DLGAddElement(DLGCreateLabel("nm"))	
		Group_Config.DLGAddElement(DLGCreateLabel("Accuracy:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateIntegerField(m_DefocusAccuracy*1e9).DLGWidth(12).DLGIdentifier("#Field_DefocusAccuracy"))
		Group_Config.DLGAddElement(DLGCreateLabel("nm"))
		// create dialog
		TagGroup dialog	= DLGCreateDialog("")
		dialog.DLGAddElement(Group_File.DLGTableLayOut(3,2,0))
		dialog.DLGAddElement(Group_Config.DLGTableLayOut(3,11,0))
		dialog.DLGAddElement(DLGCreateLabel("0 / 0",20).DLGIdentifier("#Label_Progress").DLGAnchor("West"))
		dialog.DLGAddElement(DLGCreateProgressBar("#ProgressBar").DLGFill("X"))
		dialog.DLGAddElement(DLGCreatePushButton("Find Defocus","ButtonPressed_Find").DLGIdentifier("#Button_Find"))
		return self.super.Init(dialog)
	}
	
	void AboutToCloseDocument(object self, number verify)
	{
		m_Thread.RemoveMainThreadTask()
	}
	
	void ButtonPressed_Browse(object self)
	{
		string folder
		if(GetDirectoryDialog("Browse for a directory","",folder))
			self.LookUpElement("#Field_Folder").DLGValue(folder)
	}
	
	void ButtonPressed_Find(object self)
	{
		m_hDiv = 2**floor((self.LookUpElement("#Choice_Div").DLGGetValue()+1)/2)
		m_wDiv = self.LookUpElement("#Choice_Div").DLGGetValue().mod(2)==0? 1:m_hDiv
		m_a = self.LookUpElement("#Field_a").DLGGetValue()/180*pi()
		m_nr = self.LookUpElement("#Field_nr").DLGGetValue()
		m_k = self.LookUpElement("#Field_k").DLGGetValue()*1e-10
		m_V = self.LookUpElement("#Field_V").DLGGetValue()*1e3
		m_Cs = self.LookUpElement("#Field_Cs").DLGGetValue()*1e-6
		m_AC = self.LookUpElement("#Field_AC").DLGGetValue()
		m_DefocusMin = self.LookUpElement("#Field_DefocusMin").DLGGetValue()*1e-9
		m_DefocusMax = self.LookUpElement("#Field_DefocusMax").DLGGetValue()*1e-9
		m_DefocusStep = self.LookUpElement("#Field_DefocusStep").DLGGetValue()*1e-9
		m_DefocusAccuracy = self.LookUpElement("#Field_DefocusAccuracy").DLGGetValue()*1e-9
		if(self.LookUpElement("#Choice_Source").DLGGetValue()==0)
		{
			image img := GetFrontImage()
			number tps = GetOSTicksPerSecond()
			number t1 = GetOSTickCount()
			if(m_wDiv!=m_hDiv)
				img := img.LHC_Rotate(-m_a,"c")
			image DefocusMap := img.LHC_FindDefocusMap(m_wDiv,m_hDiv,m_nr,m_k,m_V,m_Cs,m_AC \
									,m_DefocusMin,m_DefocusMax,m_DefocusStep,m_DefocusAccuracy)
			number rx,ry,rc
			number defocus = DefocusMap.LHC_RegressLimit2STD(rx,ry,rc).mean()
			number t2 = GetOSTickCount()
			string str = "Time cost:	"+(t2-t1)/tps+" s\nDefocus:	"+round(defocus*1e9)+" nm\n"
			if(m_hDiv>1)
			{
				number w,h
				img.GetSize(w,h)
				number t = atan(sqrt(rx**2+ry**2)*m_hDiv/h/m_k)
				str += "Tilt angle:	"+round(t/pi()*1800)/10+" deg\n"
			}
			if(m_wDiv>1)
			{
				number a = atan(rx/ry)
				str += "Tilt axis:	"+round(a/pi()*1800)/10+" deg\n"
			}
			result(str)
			if(OKCancelDialog(str+"\nShow defous map?"))
			{
				DefocusMap *= 1e9
				DefocusMap.ShowImage()
				DefocusMap.SetWindowSize(256,256)
				DefocusMap.SetName("Defocus Map (nm)")
			}
		}
		else
		{
			m_Folder = self.LookUpElement("#Field_Folder").DLGGetStringValue()
			if(!m_Folder.DoesDirectoryExist())
			{
				ShowAlert("Folder does not exist.",0)
				return
			}
			m_ImageNameList = LHC_CreateFileNameList(m_Folder,".dm3")
			m_n = m_ImageNameList.TagGroupCountTags()
			if(m_n==0)
			{
				ShowAlert(".dm3 image was not found.",0)
				return
			}
			if(DoesFileExist(m_Folder+"Defocus.txt"))
			{
				if(OKCancelDialog("Delete the existing Defocus.txt file?"))
					DeleteFile(m_Folder+"Defocus.txt")
				else
					return
			}
			string str = "#	defocus(nm)"
			if(m_hDiv>1)	str += "	tilt angle(deg)"
			if(m_wDiv>1)	str += "	tilt axis(deg)"
			str += "\n"
			result(str)
			(m_Folder+"Defocus.txt").LHC_Result(str)
			(m_Folder+"Defocus.txt").LHC_Result("#	defocus(nm)")
			m_i = 0
			m_Run = 1
		}
	}
	
	void ThreadHandler(object self)
	{
		if(!m_Run)
			return
		if(m_i<m_n && !ShiftDown())
		{
			string name
			m_ImageNameList.TagGroupGetIndexedTagAsString(m_i,name)
			image img := OpenImage(m_Folder+name)
			if(m_wDiv!=m_hDiv)
				img := img.LHC_Rotate(-m_a,"c")
			image DefocusMap := img.LHC_FindDefocusMap(m_wDiv,m_hDiv,m_nr,m_k,m_V,m_Cs,m_AC \
									,m_DefocusMin,m_DefocusMax,m_DefocusStep,m_DefocusAccuracy)
			number rx,ry,rc
			number defocus = DefocusMap.LHC_RegressLimit2STD(rx,ry,rc).mean()
			string str = ""+(m_i+1)+"	"+round(defocus*1e9)
			if(m_hDiv>1)
			{
				number w,h
				img.GetSize(w,h)
				number t = atan(sqrt(rx**2+ry**2)*m_hDiv/h/m_k)
				str += "	"+round(t/pi()*1800)/10
			}
			if(m_wDiv>1)
			{
				number a = atan(rx/ry)
				str += "	"+round(a/pi()*1800)/10
			}
			str += "\n"
			result(str)
			(m_Folder+"Defocus.txt").LHC_Result(str)
			self.LookUpElement("#Label_Progress").DLGTitle(""+(m_i+1)+" / "+m_n)
			self.LookUpElement("#ProgressBar").DLGValue((m_i+1)/m_n)
			m_i++
		}
		else
		{
			m_Run = 0
			ShowAlert("Task finished.",2)
		}
	}
}

void main(void)
{
	object dialog = Alloc(LHC_FindDefocusDialog).Init()
	dialog.Display("FindDefocus")
}

main()