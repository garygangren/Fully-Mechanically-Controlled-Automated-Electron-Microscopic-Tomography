// SI units

// set string length
string LHC_SetStringLength(string str, number n)
{
	while(len(str)<n)
		str += " "
	return str
}

// convert number to string and set length
string LHC_SetStringLength(number x, number n)
{
	string str = ""+x
	return str.LHC_SetStringLength(n)
}

// result to file
void LHC_Result(string name, string str)
{
	number file
	if(name.DoesFileExist())
	{
		file = name.OpenFileForReadingAndWriting()
		file.ReadFile(file.GetFileSize())
	}
	else
		file = name.CreateFileForWriting()
	file.WriteFile(str)
	file.CloseFile()
}

// clear folder
void LHC_ClearFolder(string folder)
{
	TagGroup files = folder.GetFilesInDirectory(1)
	for(number i=0;i<files.TagGroupCountTags();i++)
	{
		TagGroup file
		files.TagGroupGetIndexedTagAsTagGroup(i,file)
		string name
		file.TagGroupGetTagAsString("Name",name)
		DeleteFile(folder+name)
	}
}

// create file name list with given suffix
TagGroup LHC_CreateFileNameList(string folder, string suffix)
{
	TagGroup files = folder.GetFilesInDirectory(1)
	TagGroup list = NewTagList()
	for(number i=0;i<files.TagGroupCountTags();i++)
	{
		TagGroup file
		files.TagGroupGetIndexedTagAsTagGroup(i,file)
		string name
		file.TagGroupGetTagAsString("Name",name)
		if(len(name)>=len(suffix))
			if(name.right(len(suffix))==suffix)
				list.TagGroupInsertTagAsString(list.TagGroupCountTags(),name)
	}
	return list
}

// create file name list with fiven prefix and suffix
TagGroup LHC_CreateFileNameList(string folder, string prefix, string suffix)
{
	TagGroup files = folder.GetFilesInDirectory(1)
	TagGroup list = NewTagList()
	for(number i=0;i<files.TagGroupCountTags();i++)
	{
		TagGroup file
		files.TagGroupGetIndexedTagAsTagGroup(i,file)
		string name
		file.TagGroupGetTagAsString("Name",name)
		if(len(name)>=len(prefix)+len(suffix))
			if(name.left(len(prefix))==prefix && name.right(len(suffix))==suffix)
				list.TagGroupInsertTagAsString(list.TagGroupCountTags(),name)
	}
	return list
}

// get pixel length for given mag from system folder
number LHC_GetPixelLength(number mag)
{
	string name = GetApplicationDirectory(4,1)+"LHC PixelLength of Mag "+mag+".txt"
	if(!name.DoesFileExist())
	{
		ShowAlert("Error in function [LHC_GetPixelLength]:\nUndefined pixel length of Mag "+mag/1e3+" k.",0)
		return 0
	}
	number file = name.OpenFileForReading()
	string str
	if(!file.ReadFileLine(str))
	{
		ShowAlert("Error in function [LHC_GetPixelLength]:\nReading pixel length of Mag "+mag/1e3+" k failed.",0)
		file.CloseFile()
		name.DeleteFile()
		return 0
	}
	file.CloseFile()
	return val(str)
}

// set pixel length for given mag and save in system folder
void LHC_SetPixelLength(number mag, number k)
{
	string name = GetApplicationDirectory(4,1)+"LHC PixelLength of Mag "+mag+".txt"
	number file = name.CreateFileForWriting()
	file.WriteFile(""+k)
	file.CloseFile()
}

// delete pixel length for given mag in system folder
void LHC_DeletePixelLength(number mag)
{
	string name = GetApplicationDirectory(4,1)+"LHC PixelLength of Mag "+mag+".txt"
	if(name.DoesFileExist())
		name.DeleteFile()
}

// get rotation angle for given mag from system folder
number LHC_GetRotationAngle(number mag)
{
	string name = GetApplicationDirectory(4,1)+"LHC RotationAngle of Mag "+mag+".txt"
	if(!name.DoesFileExist())
	{
		ShowAlert("Error in function [LHC_GetRotationAngle]:\nUndefined rotation angle of Mag "+mag/1e3+" k.",0)
		return 0
	}
	number file = name.OpenFileForReading()
	string str
	if(!file.ReadFileLine(str))
	{
		ShowAlert("Error in function [LHC_GetRotationAngle]:\nReading rotation angle of Mag "+mag/1e3+" k failed.",0)
		file.CloseFile()
		name.DeleteFile()
		return 0
	}
	file.CloseFile()
	return val(str)
}

// set rotation angle for given mag and save in system folder
void LHC_SetRotationAngle(number mag, number a)
{
	string name = GetApplicationDirectory(4,1)+"LHC RotationAngle of Mag "+mag+".txt"
	number file = name.CreateFileForWriting()
	file.WriteFile(""+a)
	file.CloseFile()
}

// delete rotation angle for given mag in system folder
void LHC_DeleteRotationAngle(number mag)
{
	string name = GetApplicationDirectory(4,1)+"LHC RotationAngle of Mag "+mag+".txt"
	if(name.DoesFileExist())
		name.DeleteFile()
}

// get numbers from a string
image LHC_Val(string str, number &count)
{
	image data := realimage("",8,max(len(str),1))
	count = 0
	string nstr = ""
	number point = 0
	number n = 0
	for(number i=1;i<=len(str+" ");i++)
	{
		string bit = (str+" ").left(i).right(1)
		if((bit=="-"||bit=="+")&&nstr=="")
		{
			nstr += bit
		}
		else if(bit=="."&&point==0)
		{
			nstr += bit
			point = 1
		}
		else if(bit=="0"||bit=="1"||bit=="2"||bit=="3"||bit=="4"|| \
			bit=="5"||bit=="6"||bit=="7"||bit=="8"||bit=="9")
		{
			nstr += bit
			n++
		}
		else
		{
			if(n>0)
			{
				data.SetPixel(count,0,val(nstr))
				count++
			}
			nstr = ""
			point = 0
			n = 0
		}
	}
	return data[0,0,1,max(count,1)]
}

// calculate standard deviation
number LHC_STD(image img)
{
	return sqrt(MeanSquare(img-mean(img)))
}

// calculate standard deviation
number LHC_STD(image img1, image img2)
{
	return sqrt(MeanSquare(img1-img2))
}

// rotate vector (x,y) by a rad
void LHC_Rotate(number &x, number &y, number a)
{
	number xr = cos(a)*x-sin(a)*y
	number yr = sin(a)*x+cos(a)*y
	x = xr
	y = yr
}

// solve 2nd order linear equation of AX=B
image LHC_Solve2(image A, image B)
{
	image X := realimage("",8,1,2)
	number wA,hA,wB,hB
	A.GetSize(wA,hA)
	B.GetSize(wB,hB)
	if(wA!=2 || hA!=2 || wB!=1 || hB!=2)
	{
		ShowAlert("Error in function [LHC_Solve2]:\nUnmatched dementions.",0)
		return X
	}
	number a11 = A.GetPixel(0,0)
	number a12 = A.GetPixel(1,0)
	number a21 = A.GetPixel(0,1)
	number a22 = A.GetPixel(1,1)
	number det = a11*a22-a12*a21
	if(det==0)
	{
		ShowAlert("Error in function [LHC_Solve2]:\nDeterminant is 0.",0)
		return X
	}
	number b1 = B.GetPixel(0,0)
	number b2 = B.GetPixel(0,1)
	number x1 = (a22*b1-a12*b2)/det
	number x2 = (a11*b2-a21*b1)/det
	X.SetPixel(0,0,x1)
	X.SetPixel(0,1,x2)
	return X
}

// solve 3rd order linear equation of AX=B
image LHC_Solve3(image A, image B)
{
	image X := realimage("",8,1,3)
	number wA,hA,wB,hB
	A.GetSize(wA,hA)
	B.GetSize(wB,hB)
	if(wA!=3 || hA!=3 || wB!=1 || hB!=3)
	{
		ShowAlert("Error in function [LHC_Solve3]:\nUnmatched dementions.",0)
		return X
	}
	number a11 = A.GetPixel(0,0)
	number a12 = A.GetPixel(1,0)
	number a13 = A.GetPixel(2,0)
	number a21 = A.GetPixel(0,1)
	number a22 = A.GetPixel(1,1)
	number a23 = A.GetPixel(2,1)
	number a31 = A.GetPixel(0,2)
	number a32 = A.GetPixel(1,2)
	number a33 = A.GetPixel(2,2)
	number det = a11*a22*a33-a11*a23*a32-a12*a21*a33+a12*a23*a31+a13*a21*a32-a13*a22*a31
	if(det==0)
	{
		ShowAlert("Error in function [LHC_Solve3]:\nDeterminant is 0.",0)
		return X
	}
	number b1 = B.GetPixel(0,0)
	number b2 = B.GetPixel(0,1)
	number b3 = B.GetPixel(0,2)
	number x1 = (a12*a23*b3-a13*a22*b3-a12*a33*b2+a13*a32*b2+a22*a33*b1-a23*a32*b1)/det
	number x2 =-(a11*a23*b3-a13*a21*b3-a11*a33*b2+a13*a31*b2+a21*a33*b1-a23*a31*b1)/det
	number x3 = (a11*a22*b3-a12*a21*b3-a11*a32*b2+a12*a31*b2+a21*a32*b1-a22*a31*b1)/det
	X.SetPixel(0,0,x1)
	X.SetPixel(0,1,x2)
	X.SetPixel(0,2,x3)
	return X
}

// linear regression wight given weight
image LHC_Regress(image img, image weight, number &rx, number &ry, number &rc)
{
	image imgr = img
	number w,h,w2,h2
	img.GetSize(w,h)
	weight.GetSize(w2,h2)
	if(w2!=w || h2!=h)
	{
		ShowAlert("Error in function [LHC_LinearRegression]:\nImage size was different from weight size.",0)
		return imgr
	}
	if(w==1 && h==1)
	{
		rx = ry = 0
		rc = img.GetPixel(0,0)
	}
	else if(w==1 || h==1)
	{
		number a11,a12,a21,a22,b1,b2
		a11=a12=a21=a22=b1=b2=0
		if(w==1)
		{
			for(number i=0;i<h;i++)
				if(weight.GetPixel(0,i))
				{
					a11 += i*i
					a12 += i
					a21 += i
					a22 += 1
					b1 += i*img.GetPixel(0,i)
					b2 += img.GetPixel(0,i)
				}
		}
		else
		{
			for(number j=0;j<w;j++)
				if(weight.GetPixel(j,0))
				{
					a11 += j*j
					a12 += j
					a21 += j
					a22 += 1
					b1 += j*img.GetPixel(j,0)
					b2 += img.GetPixel(j,0)
				}
		}
		image A := realimage("",8,2,2)
		A.SetPixel(0,0,a11)
		A.SetPixel(1,0,a12)
		A.SetPixel(0,1,a21)
		A.SetPixel(1,1,a22)
		image B := realimage("",8,1,2)
		B.SetPixel(0,0,b1)
		B.SetPixel(0,1,b2)
		image X:= LHC_Solve2(A,B)
		if(w==1)
		{
			rx = 0
			ry = X.GetPixel(0,0)
		}
		else
		{
			rx = X.GetPixel(0,0)
			ry = 0
		}
		rc = X.GetPixel(0,1)
	}
	else
	{
		number a11,a12,a13,a21,a22,a23,a31,a32,a33,b1,b2,b3
		a11=a12=a13=a21=a22=a23=a31=a32=a33=b1=b2=b3=0
		for(number i=0;i<h;i++)
			for(number j=0;j<w;j++)
				if(weight.GetPixel(j,i))
				{
					a11 += j*j
					a12 += i*j
					a13 += j
					b1 += j*img.GetPixel(j,i)
					a21 += i*j
					a22 += i*i
					a23 += i
					b2 += i*img.GetPixel(j,i)
					a31 += j
					a32 += i
					a33 += 1
					b3 += img.GetPixel(j,i)
				}
		image A := realimage("",8,3,3)
		A.SetPixel(0,0,a11)
		A.SetPixel(1,0,a12)
		A.SetPixel(2,0,a13)
		A.SetPixel(0,1,a21)
		A.SetPixel(1,1,a22)
		A.SetPixel(2,1,a23)
		A.SetPixel(0,2,a31)
		A.SetPixel(1,2,a32)
		A.SetPixel(2,2,a33)
		image B := realimage("",8,1,3)
		B.SetPixel(0,0,b1)
		B.SetPixel(0,1,b2)
		B.SetPixel(0,2,b3)
		image X:= LHC_Solve3(A,B)
		rx = X.GetPixel(0,0)
		ry = X.GetPixel(0,1)
		rc = X.GetPixel(0,2)
	}
	for(number i=0;i<h;i++)
		for(number j=0;j<w;j++)
			imgr.SetPixel(j,i,rx*j+ry*i+rc)
	return imgr
}

// linear regress
image LHC_Regress(image img, image weight)
{
	number rx,ry,rc
	return img.LHC_Regress(weight,rx,ry,rc)
}

// linear regress
image LHC_Regress(image img, number &rx, number &ry, number &rc)
{
	number w,h
	img.GetSize(w,h)
	image weight := realimage("",8,w,h)
	weight = 1
	return img.LHC_Regress(weight,rx,ry,rc)
}

// linear regress
image LHC_Regress(image img)
{
	number rx,ry,rc
	return img.LHC_Regress(rx,ry,rc)
}

// linear regress with limit 2 STD
image LHC_RegressLimit2STD(image img, number &rx, number &ry, number &rc)
{
	number w,h
	img.GetSize(w,h)
	image imgr := img.LHC_Regress(rx,ry,rc)
	number STD = LHC_STD(img,imgr)
	image weight := abs(img-imgr)<=2*STD
	return img.LHC_Regress(weight,rx,ry,rc)
}

// linear regress with limit 2 STD
image LHC_RegressLimit2STD(image img)
{
	number w,h
	img.GetSize(w,h)
	image imgr := img.LHC_Regress()
	number STD = LHC_STD(img,imgr)
	image weight := abs(img-imgr)<=2*STD
	return img.LHC_Regress(weight)
}

// resize image
image LHC_Resize(image img0, number w, number h)
{
	image img := NewImage("",img0.ImageGetDataType(),w,h)
	number w0,h0
	img0.GetSize(w0,h0)
	if((w0.mod(w)!=0 && w.mod(w0)!=0) || (h0.mod(h)!=0 && h.mod(h0)!=0))
		ShowAlert("Error in function [LHC_Resize]:\nImage sizes were not divisible by each other.",0)
	else if(w==w0 && h==h0)
		img = img0
	else
	{
		number wScale = w/w0
		number hScale = h/h0
		img = img0[icol/wScale,irow/hScale]
	}
	return img
}
// rotate image by a rad, specify mode
image LHC_Rotate(image img, number a, string m)
{
	number w,h
	img.GetSize(w,h)
	image imgr := img.rotate(a)
	number wr,hr
	imgr.GetSize(wr,hr)
	if(m=="L" || m=="l")	return imgr
	if(m=="M" || m=="m")	return imgr[(hr-h)/2,(wr-w)/2,(hr+h)/2,(wr+w)/2]
	if(m=="S" || m=="s")	return imgr[(hr-h*h/hr)/2,(wr-w*w/wr)/2,(hr+h*h/hr)/2,(wr+w*w/wr)/2]
	if(m=="C" || m=="c")	return imgr[(hr-h/2)/2,(wr-w/2)/2,(hr+h/2)/2,(wr+w/2)/2]
}

// stretch image along a direction
image LHC_Stretch(image img, number a, number k)
{
	number w,h
	img.GetSize(w,h)
	image imgs := NewImage("",img.ImageGetDataType(),w,h)
	number c = cos(a)
	number s = sin(a)
	number p1 = c**2/k+s**2
	number p2 = s**2/k+c**2
	number p = (1-1/k)*c*s
	number wc = (1-p1)*w/2-p*h/2
	number hc = (1-p2)*h/2-p*w/2
	imgs = img[icol*p1+irow*p+wc, irow*p2+icol*p+hc]
	return imgs
}

// filter
image LHC_Filter(image img, number f1, number f2)
{
	number w,h
	img.GetSize(w,h)
	image mask := realimage("",8,w,h)
	number r = sqrt(w**2+h**2)/2
	number r1 = r*f1
	number r2 = r*f2
	mask = iRadius>=r1 && iRadius<=r2
	image imgf := NewImage("",img.ImageGetDataType(),w,h)
	imgf = realifft(realfft(img)*mask)
	return imgf
}

// shift image
image LHC_Shift(image img, number sx, number sy)
{
	number w,h
	img.GetSize(w,h)
	image imgs := NewImage("",img.ImageGetDataType(),w,h)
	imgs = mean(img)
	sx = round(sx)
	sy = round(sy)
	if(abs(sx)>=w || abs(sy)>=h)
		return imgs
	else if(sx>=0 && sy>=0)
		imgs[sy,sx,h,w] = img[0,0,h-sy,w-sx]
	else if(sx>=0 && sy<0)
		imgs[0,sx,h+sy,w] = img[-sy,0,h,w-sx]
	else if(sx<0 && sy>=0)
		imgs[sy,0,h,w+sx] = img[0,-sx,h-sy,w]
	else
		imgs[0,0,h+sy,w+sx] = img[-sy,-sx,h,w]
	return imgs
}

// calculate the corrlation coefficient of two images
number LHC_CorrCoef(image img1, image img2)
{
	number w,h,w2,h2
	img1.GetSize(w,h)
	img2.GetSize(w2,h2)
	if(w2!=w || h2!=h)
	{
		ShowAlert("Error in function [LHC_CorrCoef]:\nImage sizes were different.",0)
		return 0
	}
	image img1d := img1-mean(img1)
	image img2d := img2-mean(img2)
	number s12 = sum(img1d*img2d)
	number s1 = sum(img1d**2)
	number s2 = sum(img2d**2)
	if(s1==0 || s2==0)
		return 0
	else
		return s12/sqrt(s1*s2)
}

// calcuate cross correlation
image LHC_CrossCorrelate(image img1,image img2)
{
	image img1m := img1-mean(img1)
	image img2m := img2-mean(img2)
	compleximage img1f := realfft(img1m)
	compleximage img2f := realfft(img2m)
	image cc := realifft(conjugate(img2f)*img1f)/sqrt(sum(img1m**2)*sum(img2m**2))
	cc.ShiftCenter()
	return cc
}

// measure the shift from img1 to img2
number LHC_MeasureShift(image img1, image img2, number &sx, number &sy)
{
	number w,h,w2,h2
	img1.GetSize(w,h)
	img2.GetSize(w2,h2)
	if(w2!=w || h2!=h)
	{
		ShowAlert("Error in function [LHC_MeasureShift]:\nImage sizes were different.",0)
		return 0
	}
	image img1e := NewImage("",img1.ImageGetDataType(),w*2,h*2)
	img1e[0,0,w,h] = img1-mean(img1)
	image img2e := NewImage("",img2.ImageGetDataType(),w*2,h*2)
	img2e[0,0,w,h] = img2-mean(img2)
	image img := CrossCorrelate(img1e,img2e)
	number cc = img.max(sx,sy)
	sx = w-sx
	sy = h-sy
	return cc
}

// calculate the 1D CTF curve of an image
image LHC_CalculateCTF(image img)
{
	number w,h
	img.GetSize(w,h)
	number n = min(w,h)/2
	image ImgFFT := modulus(realfft(img))
	image ImgPolar := realimage("",8,n,360)
	number p = pi()/180
	number w2 = w/2
	number h2 = h/2
	ImgPolar = ImgFFT[icol*sin(irow*p)+w2,icol*cos(irow*p)+h2]
	image CTF := realimage("",8,n)
	CTF[icol,0] += ImgPolar*icol
	return CTF/mean(CTF)/2
}

// create a 1D CTF curve using given parameters
image LHC_CreateCTF(number n, number k, number V, number Cs, number AC, number defocus)
{
	number c = 2.998e8;		// velocity of light
	number m = 9.1095e-31;	// rest mass of electron
	number h = 6.6261e-34;	// Planck's constant
	number e = 1.6022e-19;	// charge on electron
	number lambda = h/sqrt(2*m*V*e*(1+(e*V)/(2*m*c**2))) // wave length
	number fs = 1/k		// space sample rate
	number df = fs/2/n	// space frequency resolution
	image x := realimage("",8,n)
	number p1 = -pi()*lambda*df**2
	number p2 = 0.5*lambda**2*df**2*Cs
	x = p1*icol**2*(defocus+p2*icol**2)
	image CTF := -sqrt(1-AC**2)*sin(x)-AC*cos(x)
	return CTF**2
}

// Find nodes of created CTF
image LHC_FindNode(image CTF, number nn)
{
	number n,tmp
	CTF.GetSize(n,tmp)
	image nodes := IntegerImage("",4,0,nn)
	nodes = 0
	number count = 0
	for(number i=0;i<n-1;i++)
		if(CTF.GetPixel(i,0)<0.5 && CTF.GetPixel(i+1,0)>=0.5)
		{
			nodes.SetPixel(count,0,i)
			count++
			if(count==nn)
				break
		}
	return nodes
}

// calculate the correlation coefficient of two CTFs
image LHC_CompareCTFs(image CTF1, image CTF2)
{
	number n1,n2,tmp
	CTF1.GetSize(n1,tmp)
	CTF2.GetSize(n2,tmp)
	if(n1!=n2)
	{
		ShowAlert("Error in function [LHC_CompareCTF]:\nThe lengths of CTF curves were different.",0)
		return realimage("",8,1)
	}
	image cc := realimage("",8,n1)
	number node = 0
	for(number i=0;i<n1-1;i++)
		if(CTF2.GetPixel(i,0)<0.5 && CTF2.GetPixel(i+1,0)>=0.5)
		{
			if(node>0)
				cc[0,node,1,i] = LHC_CorrCoef(CTF1[0,node,1,i],CTF2[0,node,1,i])
			node = i
		}
	return cc
}

// calculate the correlation coefficient of the rings of two CTFs
number LHC_CompareCTFs(image CTF1, image CTF2, image nodes)
{
	number n1,n2,nn,tmp
	CTF1.GetSize(n1,tmp)
	CTF2.GetSize(n2,tmp)
	nodes.GetSize(nn,tmp)
	if(n1!=n2)
	{
		ShowAlert("Error in function [LHC_CompareCTF]:\nThe lengths of CTF curves were different.",0)
		return 0
	}
	number cc = 0
	number count = 0
	for(number i=0;i<nn-1;i++)
	{
		number a = nodes.GetPixel(i,0)
		number b = nodes.GetPixel(i+1,0)
		if(b>a)
		{
			cc += LHC_CorrCoef(CTF1[0,a,1,b],CTF2[0,a,1,b])
			count++
		}
		else
			break
	}
	if(count>0)
		cc /= count
	return cc
}

// fit to find defocus using 0.618 method
number LHC_FitCTF(image CTF, number nr, number k, number V, number Cs, number AC \
					,number defocus1, number defocus2, number accuracy)
{
	number n,tmp
	CTF.GetSize(n,tmp)
	if(defocus1==defocus2)
		return defocus1
	number defocus11 = 0.618*defocus1+0.382*defocus2
	number defocus22 = 0.382*defocus1+0.618*defocus2
	image CTF11 := LHC_CreateCTF(n,k,V,Cs,AC,defocus11)
	image CTF22 := LHC_CreateCTF(n,k,V,Cs,AC,defocus22)
	image nodes11 := CTF11.LHC_FindNode(nr+1)
	image nodes22 := CTF22.LHC_FindNode(nr+1)
	number cc11 = LHC_CompareCTFs(CTF,CTF11,nodes11)
	number cc22 = LHC_CompareCTFs(CTF,CTF22,nodes22)
	number m = ceil(log(abs(accuracy/(defocus1-defocus2)))/log(0.618))
	for(number i=0;i<m;i++)
	{
		if(cc11<cc22)
		{
			defocus1 = defocus11
			defocus11 = defocus22
			defocus22 = 0.382*defocus1+0.618*defocus2
			cc11 = cc22
			CTF22 := LHC_CreateCTF(n,k,V,Cs,AC,defocus22)
			nodes22 := CTF22.LHC_FindNode(nr+1)
			cc22 = LHC_CompareCTFs(CTF,CTF22,nodes22)
		}
		else
		{
			defocus2 = defocus22
			defocus22 = defocus11
			defocus11 = 0.618*defocus1+0.382*defocus2
			cc22 = cc11
			CTF11 := LHC_CreateCTF(n,k,V,Cs,AC,defocus11)
			nodes11 := CTF11.LHC_FindNode(nr+1)
			cc11 = LHC_CompareCTFs(CTF,CTF11,nodes11)
		}
	}
	return defocus11
}

// find defocus map
image LHC_FindDefocusMap(image img, number wDiv, number hDiv, number nr, number k, number V, number Cs, number AC \
						,number DefocusMin, number DefocusMax, number DefocusStep, number DefocusAccuracy)
{
	number w,h
	img.GetSize(w,h)
	image DefocusMap := realimage("",8,wDiv,hDiv)
	number n = min(w/wDiv,h/hDiv)/2
	number m = floor((DefocusMax-DefocusMin)/DefocusStep+1)
	image CTFList := realimage("",8,n,m)
	image NodesList := realimage("",8,nr+1,m)
	for(number i=0;i<m;i++)
	{
		image CTF := LHC_CreateCTF(n,k,V,Cs,AC,DefocusMin+DefocusStep*i)
		image nodes := CTF.LHC_FindNode(nr+1)
		CTFList[i,0,i+1,n] = CTF
		NodesList[i,0,i+1,nr+1] = nodes
	}
	for(number i=0;i<hDiv;i++)
		for(number j=0;j<wDiv;j++)
		{
			image sub := img[h/hDiv*i,w/wDiv*j,h/hDiv*(i+1),w/wDiv*(j+1)]
			number ws, hs
			sub.GetSize(ws,hs)
			while(ws>=2*hs)
			{
				sub := sub[0,0,hs,ws/2]+sub[0,ws/2,hs,ws]
				sub.GetSize(ws,hs)
			}
			while(hs>=2*ws)
			{
				sub := sub[0,0,hs/2,ws]+sub[hs/2,0,hs,ws]
				sub.GetSize(ws,hs)
			}
			image CTF1 := sub.LHC_CalculateCTF()
			number ccmax = -1
			number defocus = 0
			for(number ii=0;ii<m;ii++)
			{
				image CTF2 := CTFList[ii,0,ii+1,n]
				image nodes := NodesList[ii,0,ii+1,nr+1]
				number cc = LHC_CompareCTFs(CTF1,CTF2,nodes)
				if(ccmax<cc)
				{
					ccmax = cc
					defocus = DefocusMin+DefocusStep*ii
				}
			}
			number defocus1 = max(DefocusMin,defocus-DefocusStep)
			number defocus2 = min(DefocusMax,defocus+DefocusStep)
			defocus = CTF1.LHC_FitCTF(nr,k,V,Cs,AC,defocus1,defocus2,DefocusAccuracy)
			DefocusMap.SetPixel(j,i,defocus)
		}
	return DefocusMap
}
