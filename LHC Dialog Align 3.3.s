Class LHC_AlignDialog: UIFrame
{
	string m_Folder
	number m_Area, m_Bin
	number m_tStart, m_dt
	number m_a // angle from x axis to tilt axis
	TagGroup m_ImageNameList
	number m_n, m_i
	image m_Img, m_ImgSum
	number m_w, m_h
	image m_exList, m_eyList
	number m_Thread, m_Align, m_Create, m_Show
	
	LHC_AlignDialog(object self)
	{
		result("Align dialog created\n")
	}
	
	~LHC_AlignDialog(object self)
	{
		result("Align dialog destoryed\n")
	}
	
	object Init(object self)
	{
		// add thread
		m_Align = m_Create = m_Show = 0
		m_Thread = self.AddMainThreadPeriodicTask("ThreadHandler",0.1)
		// init members
		m_Folder = GetApplicationDirectory(2,1)
		m_Area = 0
		m_Bin = 1
		// group config
		TagGroup Group_Config = DLGCreateGroup().DLGIdentifier("#Group_Config")
		Group_Config.DLGAddElement(DLGCreateLabel("Folder:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateStringField(m_Folder).DLGWidth(20).DLGIdentifier("#Field_Folder"))
		Group_Config.DLGAddElement(DLGCreatePushButton("...","ButtonPressed_Browse").DLGIdentifier("#Button_Browse"))
		Group_Config.DLGAddElement(DLGCreateLabel("Area:").DLGAnchor("West"))
		TagGroup Choice_Area = DLGCreateChoice(m_Area).DLGIdentifier("#Choice_Area")
		Choice_Area.DLGAddChoiceItemEntry("full image        ")
		Choice_Area.DLGAddChoiceItemEntry("top left")
		Choice_Area.DLGAddChoiceItemEntry("top right")
		Choice_Area.DLGAddChoiceItemEntry("bottom left")
		Choice_Area.DLGAddChoiceItemEntry("bottom right")
		Choice_Area.DLGAddChoiceItemEntry("1/4 center")
		Group_Config.DLGAddElement(Choice_Area)
		Group_Config.DLGAddElement(DLGCreateLabel(""))
		Group_Config.DLGAddElement(DLGCreateLabel("Bin:").DLGAnchor("West"))
		TagGroup Choice_Bin = DLGCreateChoice(log(m_Bin)/log(2)).DLGIdentifier("#Choice_Bin")
		Choice_Bin.DLGAddChoiceItemEntry("1                    ")
		Choice_Bin.DLGAddChoiceItemEntry("2")
		Choice_Bin.DLGAddChoiceItemEntry("4")
		Choice_Bin.DLGAddChoiceItemEntry("8")
		Group_Config.DLGAddElement(Choice_Bin)
		Group_Config.DLGAddElement(DLGCreateLabel(""))
		Group_Config.DLGAddElement(DLGCreateLabel("Start:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateRealField(m_tStart/pi()*180).DLGWidth(20).DLGIdentifier("#Field_tStart"))
		Group_Config.DLGAddElement(DLGCreateLabel("deg"))
		Group_Config.DLGAddElement(DLGCreateLabel("Step:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateRealField(m_dt/pi()*180).DLGWidth(20).DLGIdentifier("#Field_dt"))
		Group_Config.DLGAddElement(DLGCreateLabel("deg"))
		Group_Config.DLGAddElement(DLGCreateLabel("Axis:").DLGAnchor("West"))
		Group_Config.DLGAddElement(DLGCreateRealField(m_a/pi()*180).DLGWidth(20).DLGIdentifier("#Field_a"))
		Group_Config.DLGAddElement(DLGCreateLabel("deg"))
		// group button
		TagGroup Group_Button = DLGCreateGroup().DLGIdentifier("#Group_Button")
		Group_Button.DLGAddElement(DLGCreatePushButton(" Align ","ButtonPressed_Align").DLGIdentifier("#Button_Align"))
		Group_Button.DLGAddElement(DLGCreatePushButton("Show","ButtonPressed_Show").DLGIdentifier("#Button_Show"))
		// create dialog
		TagGroup dialog	= DLGCreateDialog("")
		dialog.DLGAddElement(Group_Config.DLGTableLayOut(3,6,0))
		dialog.DLGAddElement(DLGCreateLabel("0 / 0",20).DLGIdentifier("#Label_Progress").DLGAnchor("West"))
		dialog.DLGAddElement(DLGCreateProgressBar("#ProgressBar").DLGFill("X"))
		dialog.DLGAddElement(Group_Button.DLGTableLayOut(2,1,0))
		return self.super.Init(dialog)
	}
	
	void AboutToCloseDocument(object self, number verify)
	{
		m_Thread.RemoveMainThreadTask()
		if(m_Img.ImageIsValid())
			m_Img.DeleteImage()
	}
	
	void ButtonPressed_Browse(object self)
	{
		string folder
		if(GetDirectoryDialog("Browse for a directory","",folder))
			self.LookUpElement("#Field_Folder").DLGValue(folder)
	}
	
	void ButtonPressed_Align(object self)
	{
		m_Folder = self.LookUpElement("#Field_Folder").DLGGetStringValue()
		if(!m_Folder.DoesDirectoryExist())
		{
			ShowAlert("Folder does not exist.",0)
			return
		}
		m_ImageNameList = m_Folder.LHC_CreateFileNameList(".dm3")
		m_n = m_ImageNameList.TagGroupCountTags()
		if(m_n<2)
		{
			ShowAlert("At least two images are required.",0)
			return
		}
		if(DoesFileExist(m_Folder+"Align.txt"))
		{
			if(OKCancelDialog("Delete the existing Align.txt file?"))
				DeleteFile(m_Folder+"Align.txt")
			else
				return
		}
		if(m_Img.ImageIsValid())
			m_Img.DeleteImage()
		m_Area = self.LookUpElement("#Choice_Area").DLGGetValue()
		m_Bin = 2**self.LookUpElement("#Choice_Bin").DLGGetValue()
		m_tStart = self.LookUpElement("#Field_tStart").DLGGetValue()/180*pi()
		m_dt = self.LookUpElement("#Field_dt").DLGGetValue()/180*pi()
		m_a = self.LookUpElement("#Field_a").DLGGetValue()/180*pi()
		m_exList := realimage("",8,m_n)
		m_eyList := realimage("",8,m_n)
		string name
		m_ImageNameList.TagGroupGetIndexedTagAsString(0,name)
		image img := OpenImage(m_Folder+name)
		img.GetSize(m_w,m_h)
		m_Img := img.LHC_Resize(m_w/m_Bin,m_h/m_Bin)
		string str = "Start:	"+m_tStart/pi()*180+"	deg\n" \
					+"Step:	"+m_dt/pi()*180+"	deg\n" \
					+"Axis:	"+m_a/pi()*180+"	deg\n" \
					+"Bin:	"+m_Bin+"\n" \
					+"#	sx(pixel)	sy(pixel)	cc\n"
		result(str)
		(m_Folder+"Align.txt").LHC_Result(str)
		self.LookUpElement("#Label_Progress").DLGTitle(""+1+" / "+m_n+"   aligned")
		self.LookUpElement("#ProgressBar").DLGValue(1/m_n)
		m_i = 1
		m_Align = 1
	}
	
	void ButtonPressed_Show(object self)
	{
		m_Folder = self.LookUpElement("#Field_Folder").DLGGetStringValue()
		if(!m_Folder.DoesDirectoryExist())
		{
			ShowAlert("Folder does not exist.",0)
			return
		}
		m_ImageNameList = m_Folder.LHC_CreateFileNameList(".dm3")
		m_n = m_ImageNameList.TagGroupCountTags()
		if(m_n==0)
		{
			ShowAlert("Images were not found.",0)
			return
		}
		if(m_Img.ImageIsValid())
			m_Img.DeleteImage()
		m_i = 0
		m_Show = 1
	}
	
	void ThreadHandler(object self)
	{
		if(m_Align)
		{
			if(m_i<m_n && !ShiftDown())
			{
				number w = m_w/m_Bin
				number h = m_h/m_Bin
				string name
				m_ImageNameList.TagGroupGetIndexedTagAsString(m_i,name)
				image img := OpenImage(m_Folder+name).LHC_Resize(w,h)
				number t1 = m_tStart + m_dt*(m_i-1)
				number t2 = m_tStart + m_dt*m_i
				image imgs := img.LHC_Stretch(m_a+pi()/2,cos(t1)/cos(t2))
				image img1, img2
				if(m_Area==0)
				{
					img1 := m_Img
					img2 := imgs
				}
				else if(m_Area==1)
				{
					img1 := m_Img[0,0,h/2,w/2]
					img2 := imgs[0,0,h/2,w/2]
				}
				else if(m_Area==2)
				{
					img1 := m_Img[0,w/2,h/2,w]
					img2 := imgs[0,w/2,h/2,w]
				}
				else if(m_Area==3)
				{
					img1 := m_Img[h/2,0,h,w/2]
					img2 := imgs[h/2,0,h,w/2]
				}
				else if(m_Area==4)
				{
					img1 := m_Img[h/2,w/2,h,w]
					img2 := imgs[h/2,w/2,h,w]
				}
				else if(m_Area==5)
				{
					img1 := m_Img[h/4,w/4,h/4*3,w/4*3]
					img2 := imgs[h/4,w/4,h/4*3,w/4*3]
				}
				number sx,sy,cc
				cc = LHC_MeasureShift(img1,img2,sx,sy)
				sx *= m_Bin
				sy *= m_Bin
				m_exList.SetPixel(m_i,0,m_exList.GetPixel(m_i-1,0)-sx)
				m_eyList.SetPixel(m_i,0,m_eyList.GetPixel(m_i-1,0)-sy)
				m_Img := img
				string str = ""+(m_i+1)+"	"+sx+"	"+sy+"	"+cc+"\n"
				result(str)
				(m_Folder+"Align.txt").LHC_Result(str)
				self.LookUpElement("#Label_Progress").DLGTitle(""+(m_i+1)+" / "+m_n+"   aligned")
				self.LookUpElement("#ProgressBar").DLGValue((m_i+1)/m_n)
				m_i++
			}
			else
			{
				m_Align = 0
				if(OKCancelDialog("Aligned finished. Create aligned images and average image?"))
				{
					if(!DoesDirectoryExist(m_Folder+"/Align/"))
						CreateDirectory(m_Folder+"/Align/")
					if(!DoesDirectoryExist(m_Folder+"/Average/"))
						CreateDirectory(m_Folder+"/Average/")
					m_exList := m_exList[0,0,1,m_i] - mean(m_exList[0,0,1,m_i])
					m_eyList := m_eyList[0,0,1,m_i] - mean(m_eyList[0,0,1,m_i])
					m_ImgSum := realimage("",8,m_w,m_h)
					m_n = m_i
					m_i = 0
					m_Create = 1
				}
			}
		}
		if(m_Create)
		{
			if(m_i<m_n && !ShiftDown())
			{
				string name
				m_ImageNameList.TagGroupGetIndexedTagAsString(m_i,name)
				number ex = m_exList.GetPixel(m_i,0)
				number ey = m_eyList.GetPixel(m_i,0)
				image img := OpenImage(m_Folder+name).LHC_Shift(ex,ey)
				img.SaveImage(m_Folder+"/Align/Align-"+name)
				m_ImgSum += img
				self.LookUpElement("#Label_Progress").DLGTitle(""+(m_i+1)+" / "+m_n+"   created")
				self.LookUpElement("#ProgressBar").DLGValue((m_i+1)/m_n)
				m_i++
			}
			else
			{
				m_Create = 0
				image img := NewImage("",m_Img.ImageGetDataType(),m_w,m_h)
				img = m_ImgSum/m_n
				img.SaveImage(m_Folder+"/Average/Average.dm3")
				ShowAlert("Aligned images and average image were created.",2)
			}
		}
		if(m_Show)
		{
			if(m_i<m_n && !ShiftDown())
			{
				string name
				m_ImageNameList.TagGroupGetIndexedTagAsString(m_i,name)
				m_Img = OpenImage(m_Folder+name)
				m_Img.ShowImage()
				m_Img.SetName(name)
				self.LookUpElement("#Label_Progress").DLGTitle(""+(m_i+1)+" / "+m_n+"   shown")
				self.LookUpElement("#ProgressBar").DLGValue((m_i+1)/m_n)
				m_i++
			}
			else
				m_Show = 0
		}
	}
}

void main(void)
{
	object dialog = Alloc(LHC_AlignDialog).Init()
	dialog.Display("Align")
}

main()