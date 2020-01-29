SetWorkingDir, %A_ScriptDir%
CoordMode, pixel, Screen
CoordMode, mouse, Screen
SetWinDelay, 500
SetKeyDelay, 10
sendmode input
#include <Vis2>
#include <gdip_imagesearch>
#NoEnv
OnExit("onExitFunc")

Random, , %a_now%
global pics := new Images
global but := new Buttons

global quitWithoutClosingVysor := false
global fileDirectory := A_ScriptDir . "\files\"
global numberString
global AccountChoice
global quitAfterCurrentAcc = 0
global vysorTitle := "SM J710F"
global vysorHandle
global continueRunning := 0

global vysorBackX := 68
global vysorBackY := 733
global vysorWidth := 378
global vysorHeight := 767
global 1x := 0
global 1y := 0
global GEx := 83
global GEy := 183
global menuButtonX := 26
global menuButtonY := 110
global homeButtonX := 188
global homeButtonY := 734
global firstSlot := 0
global secondSlot := 0
global thirdSlot := 0
global mainIndex = 1 ;start from # acc
global accNumber := 10
global hOutput
global timeCounter = 0
global DontPlaySound
global tempGP
iniRead, DontPlaySound, %filedirectory%reload.ini, reload, DontPlaySound

;gui part-----
#include GolemGui.ahk

IniRead, wasReloaded, %fileDirectory%reload.ini, reload, reloadTime
if(wasReloaded)
{
	goto buttonStart
}
return
;-----GUI part-----
ButtonTest:
	winactivate, %vysorTitle%
	sleep 1000
	imagesearch, 1x, 1y, 0, 0, %a_screenWidth%, %a_screenHeight%, *30 %filedirectory%searchBar.bmp
	if(errorlevel)
	{
		msgbox, didnt find
	}
	else
	{
		mousemove, %1x%, %1y%
		msgbox, found
	}
return

buttonTest2:
	profit := 123454768
	GuiControlGet, ProfitEdit
	ProfitEdit += profit
	GuiControl, , ProfitEdit, %ProfitEdit%
return

buttonStart:
Gui, Submit, NoHide
SB_SetText("Running")
SetTimer, updateTime, 60000
stringPos = 1
if(MyRadioYes)
{
	global fsend := Func("cSend")
	global fclick := Func("cClick")
	global fIsearch := func("imgSearchWait")
	global fIsearchFast := func("imgSearchFast")
}
else
{
	global fsend := Func("nSend")
	global fclick := Func("mClick")
	global fIsearch := func("imgSearchWait")
	global fIsearchFast := func("imgSearchFast")
}

r := 1

loop ;main loop
{
	determineAccOrder(stringPos, a_index)
	updateGui(a_index)
	
	runRsCompanion:
	if(r)
	{
		loop
		{
			if(a_index > 1)
				sleep 5000
			
			if(a:=runRsCompanion())
			{
				fileName := "runRSError" . a
				makeImage(fileName, , 0, 0, 784, 907)
				quitVysor()
				sleep 5000
			}
			else if(a_index > 2)
			{
				GuiControl, , % hOutput, RS companion did not start 3 times in a row
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				Gui, Submit, NoHide
				if(DontPlaySound)
				{
					msgbox, program failed
					exitapp
				}
				else
				{
					SoundSet, 100 
					loop
					{
						SoundPlay, %fileDirectory%audio1.wav, 1
						sleep 3000
					}
				}
			}
			
		} until (!a)
	}
	
	restart:
	loop ;restart loop
	{
		GuiControl, , % hOutput, starting to login
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		
		if(a := logIn())
		{
			GuiControl, , % hOutput, login unsuccessful a is: %a%
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			a := "loginError " . a
			if(r:=restart(a))
				goto runRsCompanion
			else
				continue restart
		}
		
		if(goBackGE())
		{
			a := "goBackGE error at top"
			if(r:=restart(a))
				goto runRsCompanion
			else
				continue restart
		}
		
		GuiControl, , % hOutput, login successful
		GuiControl, , % hOutput, starting to check offers done
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		
		;---opening app done, start trading---
		
		trader := false
		dontTrade1 := 0
		dontTrade2 := 0
		dontTrade3 := 0
		trading:
		loop ;trading loop
		{
			a := checkOfferDone()
			if(a > 1)
			{
				GuiControl, , % hOutput, checkOfferDone failed at main loop
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				a := "checkOfferDone: " . a
				if(r:=restart(a))
					goto runRsCompanion
				else
					continue restart
			}
			else if(firstSlot||secondSlot||thirdSlot)
			{
				GuiControl, , % hOutput, found offers done
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				loop 3
				{
					if(a_index = 1)
						slot := firstSlot
					else if(a_index = 2)
						slot := secondSlot
					else if(a_index = 3)
						slot := thirdSlot
						
					if(slot)
					{
						if(a:=endOffer(a_index))
						{
							GuiControl, , % hOutput, first endOffer unsuccessful a is: %a%
							sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
							a := "endOffer error at " . a_index . " slot"
							if(r:=restart(a))
								goto runRsCompanion
							else
								continue restart
						}
					}
				}
			}
		
			GuiControl, , % hOutput, starting to check if margin update needed
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			
			if(a := updateMargin())
			{
				GuiControl, , % hOutput, updateMargin unsuccesful a is: %a%
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				a := "updateMargin: " . a
				if(r:=restart(a))
					goto runRsCompanion
				else
					continue restart
			}
			
			GuiControl, , % hOutput, starting to look for free slots
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			
			a := checkFreeSlots()
			if(a > 1) ;error occured
			{
				GuiControl, , % hOutput, check free slots failed at main loop
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				a := "checkFreeSlots: " . a
				if(r:=restart(a))
					goto runRsCompanion
				else
					continue restart
			}
			else if(firstSlot||secondSlot||thirdSlot)
			{
				GuiControl, , % hOutput, found free slots
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				loop 3
				{
					if(a_index = 1)
					{
						if(dontTrade1)
							continue
						
						slot := firstSlot
					}
					else if(a_index = 2)
					{
						if(dontTrade2)
							continue
						
						slot := secondSlot
					}
					else if(a_index = 3)
					{
						if(dontTrade3)
							continue
						
						slot := thirdSlot
					}
					
					if(slot)
					{
						alternate := determineTradeSection(a_index)
						if(alternate = -1)
						{
							GuiControl, , % hOutput, failed margin or limit reached
							sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
							continue
						}
						
						sec := sectionFinder(a_index, alternate)
						ini := new AccountIni(sec)
						
						if(ini.FailedToUpdate) ;failed to update margin so dont buy or sell
						{
							GuiControl, , % hOutput, found failedToUpdate in %sec%
							GuiControl, , % hOutput, not going to buy/sell
							sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
							continue
						}
						
						if(ini.buy = 1) ;will sell
						{
							GuiControl, , % hOutput, going to sell on %a_index% slot
							sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
							
							a := sellItem(a_index, , , , alternate)
							if(a && (a != 69) && (a != 70))
							{
								GuiControl, , % hOutput, selling unsuccessful a is: %a%
								sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
								a := "sellitem error: " . a
								if(r:=restart(a))
									goto runRsCompanion
								else
									continue restart
							}
							
							GuiControl, , % hOutput, selling done
							sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
							
							if(a = 70) ;offer done instantly
								continue trading
							
							if(a = 69) ;could not sell, no items
							{
								trader := true
								continue trading
							}	
						}
						else ;will buy
						{
							GuiControl, , % hOutput, going to buy on %a_index% slot
							sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
							
							if(trader)
							{
								a := buyItem(a_index, , , , 1, ,alternate)
								if(a=71) ;quantity adjust error
								{
									if(a_index = 1)
										dontTrade1 := 1
									else if(a_index = 2)
										dontTrade2 := 1
									else if(a_index = 3)
										dontTrade3 := 1
									
									continue
								}
							}
							else
							{
								a := buyItem(a_index, , , , , , alternate)
							}
							
							if(a && (a != 69) && (a != 70))
							{
								GuiControl, , % hOutput, buying unsuccessful a is: %a%
								sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
								a := "buyitem error: " . a
								if(r:=restart(a))
									goto runRsCompanion
								else
									continue restart
							}
							
							GuiControl, , % hOutput, done buying
							sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
							
							if(a = 70) ;bought instantly
								continue trading
							
							if(a = 69) ;could not buy
							{
								trader := true
								continue trading
							}
						}
					}
				}
				
			}
	
			GuiControl, , % hOutput, checking if offers done last time
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			
			a := checkOfferDone()
			if(a > 1)
			{
				GuiControl, , % hOutput, checkOfferDone failed at main loop
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				a := "checkOfferDone: " . a
				if(r:=restart(a))
					goto runRsCompanion
				else
					continue restart
			}
			else if(firstSlot||secondSlot||thirdSlot)
			{
				GuiControl, , % hOutput, found offers done
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				loop 3
				{
					if(a_index = 1)
						slot := firstSlot
					else if(a_index = 2)
						slot := secondSlot
					else if(a_index = 3)
						slot := thirdSlot
						
					if(slot)
					{
						if(a:=endOffer(a_index))
						{
							GuiControl, , % hOutput, second endOffer unsuccesful a is: %a%
							sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
							a := "endOffer error at " . a_index . " slot"
							if(r:=restart(a))
								goto runRsCompanion
							else
								continue restart
						}
					}
				}
			}
		
		} until (!firstSlot && !secondSlot && !thirdSlot)
		
		break
	}
	
	updateQuantity()
	averageQuantities()
	
	restart(0, 1)
	r := 0

	IniWrite, 0, %fileDirectory%reload.ini, reload, reloadTime
	
	
	GuiControl, , % hOutput, switching account
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	
	if(quitAfterCurrentAcc)
	{
		SetTimer, checkWindow, off
		SetTimer, checkLoading, off
		msgbox, done
		quitVysor()
		exitapp
	}
	
	if(a:=logOut())
	{
		a := "logoutReturn " . a
		r := restart(a)
	}
	
	remainder := mod(a_index, accNumber)
	if(!remainder)
	{
		numberString := ""
		stringPos = 0
	}
	
	++stringPos ;next acc
}


;-------------***********STARTING******-------------
runRsCompanion(again:=0)
{
	if(!again)
	{
		IfWinExist, Vysor
		{
			winclose, Vysor
			sleep 1000
		}
		
		IfWinExist, %vysorTitle%
		{
			winclose, %vysorTitle%
			sleep 1000
		}
		
		run, Vysor.exe, C:\Users\pulks\AppData\Local\Vysor
		WinWait, %vysorTitle%, , 20
		if(errorlevel) ;timed out
		{
			IfWinNotExist, Vysor
			{
				GuiControl, , % hOutput, failed to run vysor
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				return 4
			}
			
			WinActivate, Vysor
			WinMove, Vysor, , -8, 0, 784, 907
			fIsearch.call(pics.view, 1x, 1y, 0, 0, 784, 907, 2, 20)
			if(errorlevel)
				return 1
			
			fIsearchFast.call(pics.wireless, 2x, 2y, 0, 0, 784, 907, 20)
			if(!errorlevel)
			{
				2x += 5
				2y += 5
				ControlClick, x%2x% y%2y%, Vysor, , , , NA pos ;clicks on wireless button
			}
			else
			{
				1x += 5
				1y += 5
				ControlClick, x%1x% y%1y%, Vysor, , , , NA pos ;clicks on view button
			}
			
			WinWait, %vysorTitle%, , 20
			if(errorlevel)
				return 2
		}
		
		WinMove, %vysorTitle%, , 500, 500, 378, 767
		WinMove, %vysorTitle%, , -8, 0, 378, 767
		WinGetPos, , , vysorWidth, vysorHeight, %vysorTitle%
		WinGet, vysorHandle, ID, %vysorTitle%
		WinActivate, %vysorTitle%
		winclose, Vysor
	}
	
	SetTimer, checkWindow, 3000
	
	loop
	{
		if(a_index > 3)
			return 3
		
		fIsearch.call(pics.RSicon, 1x, 1y, 0, 0, 0, 0, 5, 20)
		if(!errorlevel)
		{
			GuiControl, , % hOutput, found RS icon
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			1x += 10
			1y += 10
			fclick.call(1x, 1y)
			SetTimer, checkLoading, 1000
			fIsearch.call(pics.Login, 1x, 1y, 0, 0, 0, 0, 15, 20)
			if(!errorlevel)
				break
			else
			{
				SetTimer, checkLoading, off
				closeApp()
				continue
			}
		}
		else
		{
			fclick.call(homeButtonX, homeButtonY) ;clicks phones home button
		}
	}
	
	SetTimer, checkLoading, 1000
	WinGet, vysorHandle, ID, %vysorTitle%
}

logIn(again:=0)
{
	fIsearch.call(pics.Login, 1x, 1y, 0, 0, 0, 0, 10, 30)
	if(!errorlevel)
	{
		IniRead, username, %filedirectory%RSandroid.ini, %mainIndex%other, login
		username := StrSplit(username,"@")
		
		tempCoords2 := rClick(but.login) ;clicks on login
		fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(errorlevel)
		{
			name := "Login1kbdNotFound" . tempCoords2
			makeImage(name, ,2)
			
			loop
			{
				if(a_index > 3)
				{
					makeImage("logInError6")
					return 6
				}
				
				rClick(but.login, , , , 1) ;clicks on login middle
				fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
			} until (!errorlevel)
		}
		
		rSleep(800, 1200)
		fsend.call(username[1])
		SetKeyDelay, 500, 50
		rSleep(800, 1200)
		fsend.call("@")
		rSleep(400, 600)
		SetKeyDelay, 10
		rSleep(400, 600)
		fsend.call(username[2])
		rSleep(1800, 2200)
		fsend.call("tab", , 1)
		rSleep(1800, 2200)
		fsend.call("Trium21")
		rSleep(2800, 3200)
		fsend.call("enter", , 1)
	}
	else 
	{
		makeImage("loginError1")
		return 1
	}
	
	loop
	{
		fIsearch.call(pics.GELoginErrorAuthenticator, 1x, 1y, 0, 0, 0, 0, 10, 20)
		if(!errorlevel)
		{
			fIsearchFast.call(pics.authenticator, 1x, 1y, 0, 0, 0, 0, 20)
			if(!errorlevel)
			{
				GuiControl, , % hOutput, authenticator detected
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				if(a:=inputAuthenticator())
				{
					if(a=69) ;room for improvements
					{
						if(again)
						{
							a := "inputAuthenticator Error " . a
							return a
						}
					
						GuiControl, , % hOutput, loggin in again
						sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
						
						closeApp()
						openApp()
						return logIn(1)
					}
					
					a := "inputAuthenticator Error " . a
					return a
				}
			}
		}
		else
		{
			fIsearchFast.call(pics.GrandExchangeTitle, 1x, 1y, 0, 0, 0, 0, 20)
			if(!errorlevel)
			{
				if(goBackGE())
					return 10
				
				return 0
			}
			else
			{
				if(a_index = 1)
					fsend.call("enter", , 1)
				else
				{
					makeImage("loginError2")
					return 2
				}
			}
		}
		
		fIsearchFast.call(pics.GrandExchange, 1x, 1y, 0, 0, 0, 0, 20)
		if(!errorlevel)
			break
		
		if(a_index > 1)
		{
			makeImage("loginError3")
			return 3
		}
		
		fIsearchFast.call(pics.LoginError, 1x, 1y, 0, 0, 0, 0, 20)
		if(!errorlevel)
		{
			fileAppend, login error promt recieved %mainIndex% acc`n, %fileDirectory%statistics.txt
			
			loop
			{
				if(a_index > 2)
				{
					makeImage("loginError4")
					return 4
				}
				
				fIsearchFast.call(pics.LoginError, 1x, 1y, 0, 0, 0, 0, 20)
				if(!errorlevel)
				{
					fclick.call(vysorBackX, vysorBackY)
					sleep 2000
				}
				else if(errorlevel)
					break
			}
			
			rSleep(800, 1200)
			tempCoords2 := rClick(but.login) ;clicks on login 
			fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
			if(errorlevel)
			{
				name := "Login2kbdNotFound" . tempCoords2
				makeImage(name, ,2)
				
				loop
				{
					if(a_index > 3)
					{
						makeImage("logInError7")
						return 7
					}
					
					rClick(but.login, , , , 1) ;clicks on login middle
					fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
				} until (!errorlevel)
			}
			
			sleep 1000
			fsend.call("backspace down", , 1)
			sleep 3000
			fsend.call("backspace up", , 1)
			sleep 1000
			SetKeyDelay, 550
			fsend.call(username[1])
			sleep 1000
			fIsearchFast.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 20)
			if(errorlevel)
			{
				makeImage("kbdNotFound", , 2)
				1x := 38
				1y := 676
			}
			else
			{
				1x += 3
				1y += 3
			}
			
			fclick.call(1x, 1y) ;clicks on symbols button on keyboard
			fIsearch.call(pics.atSymbol, 1x, 1y, 0, 0, 0, 0, 3, 20)
			if(errorlevel)
			{
				makeImage("atSymbolNotFound", , 2)
				1x := 65
				1y := 577
			}
			else
			{
				1x += 3
				1y += 3
			}
			
			fclick.call(1x, 1y) ;clicks on @ button on keyboard
			sleep 1000
			fsend.call(username[2])
			sleep 1000
			fsend.call("tab", , 1)
			sleep 1000
			fsend.call("backspace down", , 1)
			sleep 2000
			fsend.call("backspace up", , 1)
			sleep 1000
			fsend.call("Trium21")
			sleep 2000
			fsend.call("enter", , 1)
			SetKeyDelay, 10
		}
	}
	
	rSleep(1500, 2000)
	rClick(but.ge)
	
	fIsearch.call(pics.GrandExchangeTitle, 1x, 1y, 0, 0, 0, 0, 7, 30)
	if(errorlevel)
	{
		makeImage("loginError5")
		return 5
	}
}

inputAuthenticator() ;returns 0 if successful, anything else if unsuccessful
{
	sec := sectionFinder(1)
	ini := new AccountIni(sec)
	SetTimer, checkLoading, off

	loop
	{
		if(a_index > 3)
		{
			GuiControl, , % hOutput, didnt find authenticator icon
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			makeImage("inputAuthError1")
			return 1
		}
		
		fclick.call(homeButtonX, homeButtonY) ;clicks phones home button
		fIsearch.call(pics.authenticatorIcon, 1x, 1y, 0, 0, 0, 0, 4, 20)
		sleep 1000
		if(!errorlevel)
			break
	}
	
	loop
	{
		if(a_index > 2)
		{
			makeImage("inputAuthError3")
			return 3
		}
		
		1x += 5
		1y += 5
		fclick.call(1x, 1y) ;clicks on google authenticator app icon
		fIsearch.call(pics.googleAuthenticator, 2x, 2y, 0, 0, 0, 0, 5, 20)
		if(!errorlevel)
			break
		else
		{
			fIsearchFast.call(pics.authenticatorIcon, 1x, 1y, 0, 0, 0, 0, 20)
			if(errorlevel)
			{
				GuiControl, , % hOutput, didnt find google auth or auth icon
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				makeImage("inputAuthError2")
				return 2
			}
		}
	}
	
	cClick(169, 287, 10, 100, -1) ;wheel up
	
	name := ini.name
	loop
	{
		if(a_index > 6)
		{
			makeImage("inputAuthError4")
			return 4
		}
		
		
		allText := OCR([4, 175, 252, 455])
		if allText contains %name%
		{
			FoundPos := InStr(allText, name)
			FoundPos -= 18
			code := SubStr(allText, FoundPos, 7)
			code := leaveOnlyNumbers(code, 1)
			break
		}
		
		cClick(169, 287, 3, 200, 1) ;wheel down
	}
	
	GuiControl, , % hOutput, code: %code%
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	
	if(StrLen(code) != 6)
	{
		;room for improvements
		fileAppend, %mainindex%acc code:%code% failed`n, %fileDirectory%statistics.txt
		makeImage("inputAuthError5")
		return 5
	}
	
	
	fclick.call(homeButtonX, homeButtonY) ;clicks phones home button
	
	loop
	{
		if(a_index > 2)
		{
			GuiControl, , % hOutput, couldnt open RSapp
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			makeImage("inputAuthError6")
			return 6
		}
		
		fIsearch.call(pics.RSicon, 1x, 1y, 0, 0, 0, 0, 5, 20)
		if(!errorlevel)
		{
			GuiControl, , % hOutput, found RS icon
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			1x += 10
			1y += 10
			fclick.call(1x, 1y) ;clicks on RS icon
			settimer, checkLoading, 1000
			fIsearch.call(pics.authenticator, 1x, 1y, 0, 0, 0, 0, 10, 20)
			if(!errorlevel)
				break
			else
			{
				makeImage("inputAuthError7")
				return 7
			}
		}
		else
		{
			fclick.call(homeButtonX, homeButtonY) ;clicks phones home button
		}
	}
	
	sleep 1000
	fclick.call(243, 259) ;clicks to input code
	sleep 2000
	fsend.call(code)
	sleep 2000
	fclick.call(41, 339) ;clicks to trust device for 30 days
	sleep 2000
	fclick.call(187, 298) ;clicks continue
	fIsearch.call(pics.savePassword, 1x, 1y, 0, 0, 0, 0, 5, 20)
	if(errorlevel)
	{
		fIsearchFast.call(pics.authenticator, 1x, 1y, 0, 0, 0, 0, 20)
		if(errorlevel)
			makeImage("savePassNotFound", ,2)
		else
			return 69
	}
				
	fclick.call(41, 315) ;clicks dont ask me again
	sleep 1000
	fclick.call(106, 273) ;clicks NO
	fIsearch.call(pics.GrandExchange, 1x, 1y, 0, 0, 0, 0, 5, 20)
	if(!errorlevel)
		return 0
				
	fIsearchFast.call(pics.GrandExchangeTitle, 1x, 1y, 0, 0, 0, 0, 20)
	if(errorlevel)
	{
		makeImage("inputAuthError8")
		return 8
	}
	
	if(goBackGE())
		return 10
	
	return 0
}

updateGui(mIndex)
{
	iteration := ceil((mIndex / accNumber))
	
	GuiControl, Move, MainText3, W170
	GuiControl, , MainText3, Accounts played in row: %a_index%
	GuiControl, Move, MainText, W170
	GuiControl, , MainText, Current Account: %MainIndex%
	GuiControl, Move, MainText2, W170
	GuiControl, , MainText2, Current Iteration: %iteration%
	
	GuiControlGet, MyEdit
	MyEdit .=  " " . mainIndex
	GuiControl, , MyEdit, %MyEdit%
	sendmessage, 0x115, 7, 0,, % "ahk_id " hEdit
	
	loop 3
	{
		a := a_index - 1
		loop 3
		{
			sec := sectionFinder(a_index, a)
			ini := new AccountIni(sec)
			stringTrimLeft, sec, sec, 1
			
			IniItem := "IniItem" . sec
			GuiControl, Move, %IniItem%, W200
			GuiControl, , %IniItem%, % "item: " ini.item
			
			IniQuantity := "IniQuantity" . sec
			GuiControl, Move, %IniQuantity%, W200
			GuiControl, , %IniQuantity%, % "Quantity: " ini.quantity
			
			IniBuy := "IniBuy" . sec
			GuiControl, Move, %IniBuy%, W200
			GuiControl, , %IniBuy%, % "Buy: " ini.Buy
			
			year := SubStr(ini.Time, 1, 4)
			month := SubStr(ini.Time, 5, 2)
			day := SubStr(ini.Time, 7, 2)
			hour := SubStr(ini.Time, 9, 2)
			minute := SubStr(ini.Time, 11, 2)
			
			ini.Time := year "." month "." day . " " . hour . ":" . minute
			IniTime := "IniTime" . sec
			GuiControl, Move, %IniTime%, W200
			GuiControl, , %IniTime%, % "Time: " ini.Time
			
			year := SubStr(ini.BuyTime, 1, 4)
			month := SubStr(ini.BuyTime, 5, 2)
			day := SubStr(ini.BuyTime, 7, 2)
			hour := SubStr(ini.BuyTime, 9, 2)
			minute := SubStr(ini.BuyTime, 11, 2)
			
			ini.BuyTime := year "." month "." day . " " . hour . ":" . minute
			IniBuyTime := "IniBuyTime" . sec
			GuiControl, Move, %IniBuyTime%, W200
			GuiControl, , %IniBuyTime%, % "BuyTime: " ini.BuyTime
			
			year := SubStr(ini.UQuantityTime, 1, 4)
			month := SubStr(ini.UQuantityTime, 5, 2)
			day := SubStr(ini.UQuantityTime, 7, 2)
			hour := SubStr(ini.UQuantityTime, 9, 2)
			minute := SubStr(ini.UQuantityTime, 11, 2)
			
			ini.UQuantityTime := year "." month "." day . " " . hour . ":" . minute
			IniUQuantityTime := "IniUQuantityTime" . sec
			GuiControl, Move, %IniUQuantityTime%, W200
			GuiControl, , %IniUQuantityTime%, % "UQuantityTime: " ini.UQuantityTime
			
			year := SubStr(ini.limitTime, 1, 4)
			month := SubStr(ini.limitTime, 5, 2)
			day := SubStr(ini.limitTime, 7, 2)
			hour := SubStr(ini.limitTime, 9, 2)
			minute := SubStr(ini.limitTime, 11, 2)
			
			ini.limitTime := year "." month "." day . " " . hour . ":" . minute
			InilimitTime := "InilimitTime" . sec
			GuiControl, Move, %InilimitTime%, W200
			GuiControl, , %InilimitTime%, % "limitTime: " ini.limitTime
			
			IniLimitQuantity := "IniLimitQuantity" . sec
			GuiControl, Move, %IniLimitQuantity%, W200
			GuiControl, , %IniLimitQuantity%, % "LimitQuantity: " ini.LimitQuantity
			
			IniItemLimit := "IniItemLimit" . sec
			GuiControl, Move, %IniItemLimit%, W200
			GuiControl, , %IniItemLimit%, % "ItemLimit: " ini.ItemLimit
			
			InilowMargin := "InilowMargin" . sec
			GuiControl, Move, %InilowMargin%, W200
			GuiControl, , %InilowMargin%, % "lowMargin: " ini.lowMargin
			
			IniHighMargin := "IniHighMargin" . sec
			GuiControl, Move, %IniHighMargin%, W200
			GuiControl, , %IniHighMargin%, % "HighMargin: " ini.HighMargin
			
			IniFailedToUpdate := "IniFailedToUpdate" . sec
			GuiControl, Move, %IniFailedToUpdate%, W200
			GuiControl, , %IniFailedToUpdate%, % "FailedToUpdate: " ini.FailedToUpdate
			
			year := SubStr(ini.UMarginTime, 1, 4)
			month := SubStr(ini.UMarginTime, 5, 2)
			day := SubStr(ini.UMarginTime, 7, 2)
			hour := SubStr(ini.UMarginTime, 9, 2)
			minute := SubStr(ini.UMarginTime, 11, 2)
			
			ini.UMarginTime := year "." month "." day . " " . hour . ":" . minute
			IniUMarginTime := "IniUMarginTime" . sec
			GuiControl, Move, %IniUMarginTime%, W200
			GuiControl, , %IniUMarginTime%, % "UMarginTime: " ini.UMarginTime
		}
	}
}

determineAccOrder(stringPos, index)
{
	if(NoRandom)
	{
		GuiControl, , % hOutput, no random mode acc determination
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		
		if(index = 1)
			mainIndex := AccountChoice - 1
		else
		{
			++mainIndex
			if(mainIndex > accNumber)
				mainIndex = 1
		}
	}
	else
	{
		GuiControl, , % hOutput, random mode acc determination
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		
		numberStringLength := StrLen(numberString)
		if(numberStringLength = 0)
		{
			loop %accNumber%
			{
				Random, mainIndex, 1, %accNumber% ;creates a random number
				mainIndex .= ","
				If InStr(numberString, mainIndex) ;checks if the number already is in string
				{
					loop ;loop until a number that is not in the string is generated, then add it to the string
					{
						Random, mainIndex, 1, %accNumber%
						mainIndex .= ","
						If not InStr(numberString, mainIndex)
						{
							numberString .= mainIndex
							break
						}
					}
				}
				else
					numberString .= mainIndex
			}
		}
		
		
		if((index = 1) && (AccountChoice != 1)) ;first acc preselected
		{
			mainIndex := AccountChoice - 1
			mainIndex .= ","
			Position := InStr(numberString, mainIndex)
			if(position != 1)
			{
				valueIn1 := SubStr(numberString, 1, 2)
				numberString := StrReplace(numberString, mainIndex, valueIn1, , 1) ;replaces all value1 with value2
				numberString := StrReplace(numberString, valueIn1, mainIndex, , 1) ;replaces first value2 with value1
			}
		}
		
		numberString2 := StrSplit(numberString, ",")
		mainIndex := numberString2[stringPos]
	}
}

openApp()
{
	loop
	{
		if(a_index > 3)
		{
			GuiControl, , % hOutput, open app unsuccessful
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			FileAppend, openApp failed`n, %fileDirectory%statistics.txt
			makeImage("openAppError")
			SetTimer, checkLoading, off
			return 1
		}
		
		fIsearch.call(pics.RSicon, 1x, 1y, 0, 0, 0, 0, 5, 20)
		if(!errorlevel)
		{
			GuiControl, , % hOutput, found RS icon
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			1x += 10
			1y += 10
			fclick.call(1x, 1y) ;clicks on RS app icon
			SetTimer, checkLoading, 1000
			fIsearch.call(pics.GEorLogin, 1x, 1y, 0, 0, 0, 0, 15, 20)
			if(!errorlevel)
				break
			else
			{
				SetTimer, checkLoading, off
				closeApp()
				continue
			}
		}
		else
		{
			fclick.call(homeButtonX, homeButtonY) ;clicks phones home button
		}
	}
	
	SetTimer, checkLoading, 1000
}

;-------------*********STARTING END**********---------

;------------***********SECTION MANIPULATIONS*************----------------
determineTradeSection(slot, marginMode:=0) ;returns alternate value or -1 if none should trade
{
	sec0 := sectionFinder(slot, 0)
	sec1 := sectionFinder(slot, 1)
	sec2 := sectionFinder(slot, 2)
	
	isLimit0 := limitReached(sec0)
	isLimit1 := limitReached(sec1)
	isLimit2 := limitReached(sec2)
	
	ini0 := new AccountIni(sec0)
	ini1 := new AccountIni(sec1)
	ini2 := new AccountIni(sec2)
	
	if(ini0.buy = 1 || ini1.buy = 1 || ini2.buy = 1)
	{
		if(ini0.buy = 1 && ini1.buy != 1 && ini2.buy != 1)
		{
			if(!marginMode)
			{
				if(ini0.FailedToUpdate)
					return -1
			}
			
			return 0
		}
		
		if(ini0.buy != 1 && ini1.buy = 1 && ini2.buy != 1)
		{
			if(!marginMode)
			{
				if(ini1.FailedToUpdate)
					return -1
			}
			
			return 1
		}
	
		if(ini0.buy != 1 && ini1.buy != 1 && ini2.buy = 1)
		{
			if(!marginMode)
			{
				if(ini2.FailedToUpdate)
					return -1
			}
			
			return 2
		}
			
		if(ini0.buy && ini1.buy && ini2.buy)
		{
			if((ini0.time > ini1.time) && (ini0.time > ini2.time))
			{
				if(!marginMode)
				{
					if(ini0.FailedToUpdate)
						return -1
				}
				
				return 0
			}
			else if((ini1.time > ini0.time) && (ini1.time > ini2.time))
			{
				if(!marginMode)
				{
					if(ini1.FailedToUpdate)
						return -1
				}
				
				return 1
			}
			else
			{
				if(!marginMode)
				{
					if(ini2.FailedToUpdate)
						return -1
				}
				
				return 2
			}
		}
		
		if(ini0.buy && ini1.buy)
		{
			if((ini0.time > ini1.time))
			{
				if(!marginMode)
				{
					if(ini0.FailedToUpdate)
						return -1
				}
				
				return 0
			}
			else
			{
				if(!marginMode)
				{
					if(ini1.FailedToUpdate)
						return -1
				}
				
				return 1
			}
		}
		
		if(ini1.buy && ini2.buy)
		{
			if((ini1.time > ini2.time))
			{
				if(!marginMode)
				{
					if(ini1.FailedToUpdate)
						return -1
				}
				
				return 1
			}
			else
			{
				if(!marginMode)
				{
					if(ini2.FailedToUpdate)
						return -1
				}
				
				return 2
			}
		}
		
		if(ini0.buy && ini2.buy)
		{
			if((ini0.time > ini2.time))
			{
				if(!marginMode)
				{
					if(ini0.FailedToUpdate)
						return -1
				}
				
				return 0
			}
			else
			{
				if(!marginMode)
				{
					if(ini2.FailedToUpdate)
						return -1
				}
				
				return 2
			}
		}
	}
	else if(isLimit0)
	{
		if(isLimit1)
		{
			if(isLimit2)
			{
				GuiControl, , % hOutput, all items have reached limit
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				fileappend, all 3 items have reached limit for %mainIndex%. acc %slot%. slot`n, %filedirectory%statistics.txt
				return -1 ;all 3 items have reached limit
			}
			else if(ini2.failedToUpdate)
			{
				if(marginMode)
				{
					now := A_Now // 100
					EnvSub, now, % ini2.Time, minutes
					if(now > 60)
						return 2
				}
				
				return -1
			}
			else
				return 2
		}
		else if(ini1.failedToUpdate)
		{
			if(marginMode)
			{
				now := A_Now // 100
				EnvSub, now, % ini1.Time, minutes
				if(now > 60)
					return 1
			}
			
			if(isLimit2)
				return -1
			else if(ini2.failedToUpdate)
			{
				if(marginMode)
				{
					now := A_Now // 100
					EnvSub, now, % ini2.Time, minutes
					if(now > 60)
						return 2
				}
				
				return -1
			}
			else
				return 2
		}
		else
			return 1
	}
	else if(ini0.failedToUpdate)
	{
		if(marginMode)
		{
			now := A_Now // 100
			EnvSub, now, % ini0.Time, minutes
			if(now > 60)
				return 0
		}
		
		if(isLimit1)
		{
			if(isLimit2)
				return -1
			else if(ini2.failedToUpdate = 1)
			{
				if(marginMode)
				{
					now := A_Now // 100
					EnvSub, now, % ini2.Time, minutes
					if(now > 60)
						return 2
				}
				
				return -1
			}
			else
				return 2
		}
		else if(ini1.failedToUpdate = 1)
		{
			if(marginMode)
			{
				now := A_Now // 100
				EnvSub, now, % ini1.Time, minutes
				if(now > 60)
					return 1
			}
		
			if(isLimit2)
				return -1
			else if(ini2.failedToUpdate = 1)
			{
				if(marginMode)
				{
					now := A_Now // 100
					EnvSub, now, % ini2.Time, minutes
					if(now > 60)
						return 2
				}
				
				return -1
			}
			else
				return 2
		}
		else
			return 1
	}
	else
		return 0
}

limitReached(sec) ;returns 1 if limit reached, 0 if not reached
{
	ini := new AccountIni(sec)
	
	now := A_Now // 100
	EnvSub, now, % ini.LimitTime, hours
	if(now < 4) ;4 hours have not passed
	{
		if(ini.limitQuantity >= ini.itemLimit) ;limit reached?
		{
			return 1
		}
	}
	
	return 0
}

sectionFinder(slot, alternate:=0, account:=0)
{
	if(!account)
		account := mainIndex
	
	if(slot = 1)
		sec := account . "first" . alternate
	else if(slot = 2)
		sec := account . "second" . alternate
	else if(slot = 3)
		sec := account . "third" . alternate
	
	return sec
}

;------------*************SECTION MANIPULATIONS END***********------------

;------------**********TRADING***********------------------
buyItem(slot, custom:=0, cPrice:=0, cQuantity:=0, alreadyTriedToSell:=0, again:=0, alternate:=0)
{
	if(slot > 3 || slot <= 0)
		return 1
	
	sec := sectionFinder(slot, alternate)
	ini := new AccountIni(sec)
	if(!custom)
	{
		if(ini.lowMargin <= 0 || ini.highMargin <= 0)
		{
			GuiControl, , % hOutput, wrong lowmargin/highmargin detected before buying
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			fileAppend, wrong lowmargin/highmargin detected before buying %sec%
			iniwrite, 1, %filedirectory%margins.ini, % ini.item, failedToUpdate
			return 0
		}
	
	
		GuiControl, , % hOutput, Checking limit
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	
		now := a_now // 100
		
		if(ini.quantity > ini.itemLimit)
		{
			ini.quantity := ini.itemLimit
			iniwrite, % ini.quantity, %filedirectory%RSandroid.ini, %sec%, quantity
		}
		
		isLimit := limitReached(sec)
		if(isLimit)
		{
			GuiControl, , % hOutput, limit reached, will not buy
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			return 0
		}
		else
		{
			EnvSub, now, % ini.limitTime, hours
			if(now >= 4) ;4 hours have passed
			{
				GuiControl, , % hOutput, Last buy was more than 4h ago|buy as usual
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				updateLimitTime = 1
			}
			else
			{
				if((ini.itemLimit - ini.limitQuantity) < ini.quantity && (ini.itemLimit - ini.limitQuantity) > 0)
				{
					GuiControl, , % hOutput, adjusted quantity to not reach limit
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
					ini.quantity := ini.itemLimit - ini.limitQuantity
					DontUpdateBuyTime = 1
				}
				else if((ini.itemLimit - ini.limitQuantity) <= 0)
				{
					GuiControl, , % hOutput, limit reached, will not buy
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
					return 0
				}
				else
				{
					GuiControl, , % hOutput, limit has not reached | will buy full quantity
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				}
			}
		}
	}
	else
	{
		ini.quantity := cQuantity
		ini.lowMargin := cPrice
	}
	
	rSleep(800, 1200)
	
	if(goBackGE())
		return 10
	
	if(slot = 1)
	{
		2y := 134
		3y := 212
		bb := but.buy1
	}
	else if(slot = 2)
	{
		2y := 218
		3y := 293
		bb := but.buy2
	}
	else if(slot = 3)
	{
		2y := 305
		3y := 381
		bb := but.buy3
	}
	
	loop
	{
		if(a_index > 2)
		{
			makeImage("buyItemError2")
			if(goBackGE())
				return 10
			else
				return 2
		}
		
		fIsearch.call(pics.buyButton, 1x, 1y, 90, 2y, 230, 3y, 5, 40)
		if(!errorlevel)
		{
			tempCoords2 := rClick(bb) ;clicks on buy button
			break
		}
		
		if(goBackGE())
			return 10
	}
	
	fIsearch.call(pics.GEbuy, 1x, 1y, 0, 0, 0, 0, 7, 20)
	if(errorlevel)
	{
		if(goBackGE())
			return 10
		
		fIsearch.call(pics.buyButton, 1x, 1y, 0, 0, 0, 0, 7, 30)
		if(!errorlevel)
		{
			rClick(bb, , , , 1) ;clicks on buy button middle
			fIsearch.call(pics.GEbuy, 1x, 1y, 0, 0, 0, 0, 7, 20)
			if(errorlevel)
			{
				makeImage("buyItemError4")
				if(goBackGE())
					return 10
				else
					return 4
			}
			else
				fileAppend, rclick didnt work on %slot% buy button: %tempCoords2%`n, files\statistics.txt
		}
		else
		{
			makeImage("buyItemError3")
			if(goBackGE())
				return 10
			else
				return 3
		}
	}
	
	rSleep(400, 600)
	
	fIsearch.call(pics.searchBar, 1x, 1y, 0, 0, 0, 0, 7, 10)
	if(errorlevel)
	{
		makeImage("buyItemError5")
		if(goBackGE())
			return 10
		else
			return 5
	}
	
	tempCoords2 := rClick(but.searchBar) ;clicks on search bar
	fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
	if(errorlevel)
	{
		rClick(but.searchBar, , , , 1) ;clicks on search bar middle
		fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(errorlevel)
		{
			makeImage("buyItemError14")
			return 14
		}
		else
			fileAppend, rclick didnt work on searchBar: %tempCoords2%`n, files\statistics.txt
	}
	
	rSleep(400, 600)
	fsend.call(ini.item)
	rSleep(3500, 4500)
	
	match:="Dragon bones,swordfish,coal,clay,rune scimitar"
	iname := ini.item
	if iname in %match%
	{
		a := itemPictureSearch(ini.item, 2, , , 0) ;searches 2nd item spot
		bb := but.buyItem2
	}
	else
	{
		a := itemPictureSearch(ini.item, 1, , , 0) ;searches 1st item spot
		bb := but.buyItem1
	}
	
	if(a) ;found item picture
	{
		loop
		{
			if(a_index > 1)
			{
				rClick(bb, , , , 1) ;clicks on item middle
			}
			else
				tempCoords2 := rClick(bb) ;clicks on item
			
			fIsearch.call(pics.offerInputScreen, 1x, 1y, 0, 0, 0, 0, 7, 20)
			if(!errorlevel)
			{
				if(a_index > 1)
					fileAppend, rclick didnt work on (buy) item: %tempCoords2%`n, files\statistics.txt
				
				break
			}
			
			if(a_index > 1)
			{
				if(!again)
				{
					if(goBackGE())
						return 10
					
					return buyItem(slot, custom, cPrice, cQuantity, alreadyTriedToSell, 1)
				}
				else
				{
					makeImage("buyItemError6")
					if(goBackGE())
						return 10
					else
						return 6
				}
			}
		}
	}
	else ;didnt find item picture
	{
		GuiControl, , % hOutput, didnt find item picture
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput	
		
		if(!again)
		{
			GuiControl, , % hOutput, restarting buyItem
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			if(goBackGE())
				return 10
			
			return buyItem(slot, custom, cPrice, cQuantity, alreadyTriedToSell, 1, alternate)
		}
		else
		{
			if iname in %match%
			{
				GuiControl, , % hOutput, % ini.item " is in 2nd position"
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				a := OCR([75, 248, 215, 23]) ;checks item name in 2nd pos
			}
			else
			{
				GuiControl, , % hOutput, % ini.item " is in 1st position"
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput		
				a := OCR([75, 180, 215, 23]) ;checks item name in 1st pos
			}
			
			if(a != ini.item)
			{
				GuiControl, , % hOutput, % ini.item " not found" | "instead found " a
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				makeImage("buyItemNotUpdatePicError7")
				
				if(goBackGE())
					return 10
				else
					return 7
			}
			
			if iname in %match%
				itemPictureSearch(ini.item, 2) ;updates item pic #2 pos
			else
				itemPictureSearch(ini.item, 1) ;updates item pic #1 pos
			
			loop
			{
				if(a_index > 1)
					rClick(bb, , , , 1) ;clicks on item middle
				else
					tempCoords2 := rClick(bb) ;clicks on item
				
				fIsearch.call(pics.offerInputScreen, 1x, 1y, 0, 0, 0, 0, 5, 20)
				if(!errorlevel)
				{
					if(a_index > 1)
						fileAppend, rclick didnt work on (buy) item: %tempCoords2%`n, files\statistics.txt
					
					break
				}
				
				if(a_index > 1)
				{
					makeImage("buyItemError8")
					return 8
				}
			}
		}
	}
	
	rsleep(400, 600)
	tempCoords2 := rClick(but.quantity) ;clicks to input quantity
	fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
	if(errorlevel)
	{
		rClick(but.quantity, , , , 1) ;clicks on quantity middle
		fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(errorlevel)
		{
			makeImage("buyItemError15")
			return 15
		}
		else
			fileAppend, rclick didnt work on (buy) quantity: %tempCoords2%`n, files\statistics.txt
	}
	
	rSleep(400, 600)
	fsend.call(ini.quantity)
	rSleep(1800, 2200)
	customAdjustment:
	tempCoords2 := rClick(but.price) ;clicks to input price
	rSleep(400, 600)
	fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
	if(errorlevel)
	{
		rClick(but.price, , , , 1) ;clicks on price middle
		fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(errorlevel)
		{
			makeImage("buyItemError16")
			return 16
		}
		else
			fileAppend, rclick didnt work on (buy) price: %tempCoords2%`n, files\statistics.txt
	}
	
	rSleep(400, 600)
	fsend.call("BackSpace", 5, 1)
	rSleep(800, 1200)
	fsend.call(ini.lowMargin)
	rSleep(800, 1200)
	
	
	
	rClick(but.away) ;clicks away to minimize keyboard
	fIsearch.call(pics.confirmOffer, 1x, 1y, 0, 0, 0, 0, 2, 20)
	if(errorlevel)
	{
		GuiControl, , % hOutput, didnt find confirm offer button
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		
		fIsearch.call(pics.offerInputScreen, 2x, 2y, 0, 0, 0, 0, 1, 20)
		if(!errorlevel)
		{
			tempCoords2 := rClick(but.price) ;clicks on price
			fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
			if(errorlevel)
			{
				rClick(but.price, , , , 1) ;clicks on price middle
				fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
				if(errorlevel)
				{
					makeImage("buyItemError17")
					return 17
				}
				else
					fileAppend, rclick didnt work on (buy) price: %tempCoords2%`n, files\statistics.txt
			}
			
			rSleep(400, 600)
			fsend.call("enter", , 1)
		}
		else
		{
			if(!again)
			{
				if(goBackGE())
					return 10
				
				return buyItem(slot, custom, cPrice, cQuantity, alreadyTriedToSell, 1, alternate)
			}
			else
			{
				makeImage("buyItemError13")
				if(goBackGE())
					return 10
				else
					return 13
			}
		}
	}
	else
	{
		GuiControl, , % hOutput, found confirm offer button
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		rClick(but.cOffer) ;clicks on confirm offer
	}
	
	;either bot has clicked on confirm offer or bot has sent "enter"
	
	fIsearch.call(pics.confirmOK, 2x, 2y, 0, 0, 0, 0, 3, 30)
	if(errorlevel)
	{
		QuantityCorrection:
		loop
		{
			tempCoords2 := rClick(but.price) ;clicks to input price
			fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
			if(errorlevel)
			{
				rClick(but.price, , , , 1) ;clicks on price middle
				fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
				if(errorlevel)
				{
					makeImage("buyItemError18")
					return 18
				}
				else
					fileAppend, rclick didnt work on (buy) price: %tempCoords2%`n, files\statistics.txt
			}
			
			rSleep(400, 600)
			fsend.call("enter", , 1)
			
			fIsearch.call(pics.confirmOK, 2x, 2y, 0, 0, 0, 0, 3, 30)
			if(!errorlevel)
				break
			
			if(a_index > 1) ;cant click on confirm offer
			{
				if(custom) ;at margin update start
				{
					if(!customAdjustmentVAR)
					{
						rSleep(800, 1200)
						rClick(but.away) ;clicks away to minimize keyboard
						rSleep(800, 1200)
						money := scanMoney(1)
						if(!money)
						{
							makeImage("buyItemError9")
							if(goBackGE())
								return 10
							else
								return 9
						}
						
						ini.lowMargin := money - 20
						customAdjustmentVAR := 1
						goto customAdjustment
					}
					else
					{
						name := "couldNotBuyCustom_" . ini.lowMargin
						makeImage(name)
						if(goBackGE())
							return 10
						else
							return 69
					}
				}
				
				loop
				{
					if(a_index = 2)
						ini.quantity := tempQuantity
					
					if(a_index = 1)
					{
						rSleep(800, 1200)
						rClick(but.away) ;clicks away to minimize keyboard
						rSleep(800, 1200)
						money := scanMoney(1)
						tempQuantity := ini.quantity
						if(!money)
							continue
						
						if(!alreadyTriedToSell)
						{
							neededMoney := ini.quantity * ini.lowMargin
							if(money < (neededMoney // 2))
							{
								if(goBackGE())
									return 10
								
								IniWrite, 1, %filedirectory%RSandroid.ini, %sec%, buy
								return 69
							}
						}
							
						ini.quantity := (money - 50000) // ini.lowmargin
						if(ini.quantity < 11 || ini.quantity >= tempQuantity)
							continue
						
					}
					else if(a_index > 10)
						ini.quantity := ini.quantity // 2
					else
						ini.quantity := ini.quantity - (ini.quantity // 10)
					
					if(ini.quantity < 11 || (a_index > 15)) ;tried to lessen quantity but reached dead end
					{
						name := "buyItemQAdjustError_" . sec
						makeImage(name)
						ini.quantity := (tempQuantity // 10) + 1
						iniwrite, % ini.quantity, files\RSandroid.ini, %sec%, quantity
						
						if(goBackGE())
							return 10
						else
							return 71
					}
						
					tempCoords2 := rClick(but.quantity) ;clicks on quantity
					fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
					if(errorlevel)
					{
						rClick(but.quantity, , , , 1) ;clicks on quantity middle
						fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
						if(errorlevel)
						{
							makeImage("buyItemError19")
							return 19
						}
						else
							fileAppend, rclick didnt work on (buy) quantity: %tempCoords2%`n, files\statistics.txt
					}
						
					rSleep(400, 600)
					fsend.call("BackSpace", 7, 1)
					rSleep(800, 1200)
					fsend.call(ini.quantity)
					rSleep(800, 1200)
					rClick(but.away) ;clicks away to minimize keyboard
					fIsearch.call(pics.confirmOffer, 1x, 1y, 0, 0, 0, 0, 3, 40)
					if(!errorlevel)
					{
						rSleep(800, 1200)
						tempCoords2 := rClick(but.cOffer) ;clicks on confirm offer
						
						loop
						{
							fIsearch.call(pics.confirmOK, 2x, 2y, 0, 0, 0, 0, 3, 30)
							if(!errorlevel)
							{
								if(a_index > 1)
									fileAppend, rclick didnt work on (buy) confirm Offer: %tempCoords2%`n, files\statistics.txt
								
								if(ini.quantity = 0)
								{
									fileAppend, % "buyItem quantity correction made " ini.item " 0`n", files\statistics.txt
									makeImage("buyItemError21")
									return 21
								}
								
								IniWrite, % ini.quantity, %filedirectory%RSandroid.ini, %sec%, quantity
								fileAppend, % "buyItem corrected " sec " " ini.item " quantity from " tempQuantity " to " ini.quantity "`n", files\statistics.txt
								break QuantityCorrection
							}
							else
							{
								if(a_index > 1)
								{
									makeImage("buyItemError12")
									if(goBackGE())
										return 10
									else
										return 12
								}
								
								rClick(but.cOffer, , , , 1) ;clicks on confirm offer middle
								continue
							}
						}
					}
				}
			}
		}
	}
	
	rSleep(800, 1200)
	tempCoords2 := rClick([2x, 2y, 2x+140, 2y+20]) ;clicks on confirm ok
	sleep 1500
	fIsearchFast.call(pics.confirmOK, 2x, 2y, 0, 0, 0, 0, 30)
	if(!errorlevel)
	{
		rClick([2x, 2y, 2x+140, 2y+20], , , , 1) ;clicks on confirm ok middle
		sleep 1500
		fIsearchFast.call(pics.confirmOK, 2x, 2y, 0, 0, 0, 0, 30)
		if(!errorlevel)
		{
			makeImage("buyItemError20")
			return 20
		}
		else
			fileAppend, rclick didnt work on (buy) confirm ok: %tempCoords2%`n, files\statistics.txt
	}
	
	if(!custom)
	{
		now := A_now // 100
		IniWrite, %now%, %filedirectory%RSandroid.ini, %sec%, time
		
		if(!DontUpdateBuyTime)
		{
			sec2 := sectionFinder(slot)
			IniWrite, %now%, %filedirectory%RSandroid.ini, %sec2%, buyTime
		}
		
		if(updateLimitTime)
		{
			iniWrite, %now%, %fileDirectory%RSandroid.ini, %sec%, limitTime
			iniWrite, 0, %fileDirectory%RSandroid.ini, %sec%, limitQuantity
			ini.limitQuantity := 0
			GuiControl, , % hOutput, updated limit time and reset limit quantity
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		}
		
		ini.limitQuantity += ini.quantity
		iniWrite, % ini.limitQuantity, %fileDirectory%RSandroid.ini, %sec%, limitQuantity
		GuiControl, , % hOutput, updated limit quantity
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		IniWrite, 1, %filedirectory%RSandroid.ini, %sec%, buy
		iniwrite, % ini.lowMargin, files/RSandroid.ini, %sec%, boughtFor
		iniwrite, 0, files/RSandroid.ini, %sec%, counter
	}
	
	fIsearch.call(pics.offerDoneInstantly, 1x, 1y, 0, 0, 0, 0, 3, 30)
	if(!errorlevel)
	{
		if(!custom)
			detProfit(slot, , sec)
		else
			tempGP := scanTotalGP()
		
		tempCoords2 := rClick([20, 1y, 53, 1y+28]) ;clicks to get items or money
		
		rSleep(500, 1000)
		fIsearchFast.call(pics.offerDoneInstantly, 1x, 1y, 0, 0, 0, 0, 30)
		if(!errorlevel)
			tempCoords3 := rClick([20, 1y, 53, 1y+28]) ;clicks to get items or money
		
		loop
		{
			if(a_index > 5)
			{
				fileAppend, rclick didnt work on (buy) collect items: %tempCoords2% or %tempCoords3%`n, files\statistics.txt
				rClick([20, 1y, 53, 1y+28], , , , 1) ;clicks on item middle
				rSleep(1000, 1500)
				
				fIsearchFast.call(pics.offerDoneInstantly, 1x, 1y, 0, 0, 0, 0, 20)
				if(!errorlevel)
				{
					fileAppend, rclick didnt work on (buy) collect items: %tempCoords2% or %tempCoords3%`n, files\statistics.txt
					rClick([20, 1y, 53, 1y+28], , , , 1) ;clicks on item middle
					rSleep(400, 600)
					if(goBackGE())
						return 10
				}
				
				break
			}
			
			sleep 1000
			fIsearchFast.call(pics.offerDoneInstantly, 1x, 1y, 0, 0, 0, 0, 20)
		} until (errorlevel)
		
		if(goBackGE())
			return 10
		else
			return 70
	}
	
	if(goBackGE())
		return 10
}

sellItem(slot, custom := 0, cPrice := 0, cQuantity := 0, alternate:=0, again:=0)
{
	if(slot > 3 || slot <= 0)
		return 1
	
	rSleep(800, 1200)
	
	if(goBackGE())
		return 10
	
	if(slot = 1)
	{
		2y := 140
		3y := 195
		ss := but.sell1
	}
	else if(slot = 2)
	{
		2y := 221
		3y := 280
		ss := but.sell2
	}
	else if(slot = 3)
	{
		2y := 310
		3y := 365
		ss := but.sell3
	}
	
	fIsearch.call(pics.sellButton, 1x, 1y, 227, 2y, 360, 3y, 5, 40)
	if(errorlevel)
	{
		if(goBackGE())
			return 10
		
		fIsearch.call(pics.sellButton, 1x, 1y, 227, 2y, 360, 3y, 5, 40)
		if(errorlevel)
		{
			makeImage("sellItemReturn2")
			return 2
		}
	}

	sec := sectionFinder(slot, alternate)
	ini := new AccountIni(sec)
	
	if(custom)
	{
		ini.highMargin := cPrice
		ini.quantity := cQuantity
	}
	else
	{
		iniread, boughtFor, files\RSandroid.ini, %sec%, boughtFor, 0
		if(boughtFor > ini.highMargin && boughtFor)
		{
			iniread, counter, files\RSandroid.ini, %sec%, counter, 0
			tt := a_now // 100
			stringTrimLeft, tt, tt, 6
			if(counter > 3)
			{
				fileappend, % mainIndex "acc " ini.item " counter is 4, ignoring that boughfor is " boughtfor " and selling for " ini.highmargin " (" tt ")`n", files\statistics.txt
			}
			else
			{
				boughtFor += 1
				ini.highMargin := boughtFor
				++counter
			}
		}
	}
	
	if(again)
		rClick(ss, , , , 1) ;clicks on sell button middle
	else
		rClick(ss) ;clicks on sell button
	
	fIsearch.call(pics.GEsell, 1x, 1y, 0, 0, 0, 0, 5, 20)
	if(errorlevel)
	{
		if(!again)
		{
			if(goBackGE())
				return 10
			
			return sellItem(slot, custom, cPrice, cQuantity, alternate, 1)
		}
		else
		{
			makeImage("sellItemReturn3")
			return 3
		}
	}
	
	rSleep(800, 1200)
	
	a := itemPictureSearch(ini.item, 1, 1, pics.noResults, 0)
	if(a = 1) ;found item before typing in search bar
	{
		loop
		{
			if(a_index > 1)
				rClick([1x, 1y, 1x+45, 1y+45], , , , 1) ;clicks on item middle
			else
				tempCoords2 := rClick([1x, 1y, 1x+45, 1y+45]) ;clicks on item
			
			fIsearch.call(pics.sellBottomButton, 2x, 2y, 0, 0, 0, 0, 3, 20)
			if(!errorlevel)
			{
				if(a_index > 1)
					fileAppend, rclick didnt work on (sell) item(1): %tempCoords2%`n, files\statistics.txt
				
				break
			}
			
			if(a_index > 1)
			{
				name := "sellItemError4_" . ini.item
				makeImage(name)
				return 4
			}
		}
		goto FoundInstantly
	}
	else if(a = 2) ;found no results image
	{
		GuiControl, , % hOutput, found no results image
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		
		if(custom)
		{
			makeImage("sellItemCustomError")
			if(goBackGE())
				return 10 
			else
				return 6 
		}
		
		IniWrite, 0, %filedirectory%RSandroid.ini, %sec%, buy
		if(goBackGE())
			return 10
		else
			return 69
	}
	else ;did not find item before typing
	{
		GuiControl, , % hOutput, % "didnt find " ini.item " saving image for later"
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		
		doNotUpdate := false
		loop, files, files\info\*.bmp
		{
			picName := A_LoopFileName
			item := ini.Item
			StringReplace, item, item, %A_SPACE%, , All
			if picName contains %item%
			{
				doNotUpdate := true
				break
			}
		}
		
		if(!doNotUpdate)
		{
			GuiControl, , % hOutput, saving image for later
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			makeImage(item, , "temp\")
		}
	}
	
	fIsearch.call(pics.searchBar, 1x, 1y, 0, 0, 0, 0, 7, 10)
	if(errorlevel)
	{
		makeImage("sellItemError5")
		return 5 
	}
	
	tempCoords2 := rClick(but.searchBar) ;clicks on search bar
	fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
	if(errorlevel)
	{
		rClick(but.searchBar, , , , 1) ;clicks on searchBar middle
		fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(errorlevel)
		{
			makeImage("sellItemError12")
			return 12
		}
		else
			fileAppend, rclick didnt work on (sell) searchbar: %tempCoords2%`n, files\statistics.txt
	}
	
	rSleep(400, 600)
	fsend.call(ini.item)
	rSleep(1800, 2200)
	
	GuiControl, , % hOutput, starting to find no results image or item
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	
	a := itemPictureSearch(ini.item, 1, 1, pics.noResults)
	if(a = 2) ;found no results image
	{
		GuiControl, , % hOutput, found no results image
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		item := ini.item
		StringReplace, item, item, %A_SPACE%, , All
		FileDelete, temp\%item%*.bmp
		
		if(custom)
		{
			makeImage("sellItemCustomError")
			if(goBackGE())
				return 10 
			else
				return 6 
		}
		
		IniWrite, 0, %filedirectory%RSandroid.ini, %sec%, buy
		if(goBackGE())
			return 10
		else
			return 69
	}
	else if(a = 1) ;found item image
	{
		GuiControl, , % hOutput, found item image
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		item := ini.item
		StringReplace, item, item, %A_SPACE%, , All
		FileMove, temp\%item%*.bmp, files\info\
		
		loop
		{
			if(a_index > 1)
				rClick([1x+5, 1y, 1x+45, 1y+45], , , , 1) ;clicks on item middle
			else
				tempCoords2 := rClick([1x+5, 1y, 1x+45, 1y+45]) ;clicks on item
			
			fIsearch.call(pics.sellBottomButton, 2x, 2y, 0, 0, 0, 0, 3, 20)
			if(!errorlevel)
			{
				if(a_index > 1)
					fileAppend, rclick didnt work on (sell) item(2): %tempCoords2%`n, files\statistics.txt
				
				break
			}
			
			if(a_index > 1)
			{
				makeImage("sellItemError7")
				return 7
			}
		}
	}
	else ;didnt find either
	{
		GuiControl, , % hOutput, didnt find item or no results image
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		
		loop
		{
			if(a_index > 1)
				rClick(but.sellItem, , , , 1) ;clicks on item middle
			else
				tempCoords2 := rClick(but.sellItem) ;clicks on item
			
			fIsearch.call(pics.sellBottomButton, 1x, 1y, 0, 0, 0, 0, 3, 20)
			if(!errorlevel)
			{
				if(a_index > 1)
					fileAppend, rclick didnt work on (sell) item(3): %tempCoords2%`n, files\statistics.txt
				
				break
			}
			
			if(a_index > 1)
			{
				makeImage("sellItemError8")
				return 8
			}
		}
	}
	
	
	FoundInstantly:
	rSleep(800, 1200)
	
	loop
	{
		if(a_index > 1)
			rClick(but.sellBottom, , , , 1) ;clicks on item middle
		else
			tempCoords2 := rClick(but.sellBottom) ;clicks on sell bottom button
		
		fIsearch.call(pics.offerInputScreen, 1x, 1y, 0, 0, 0, 0, 5, 20)
		if(!errorlevel)
		{
			if(a_index > 1)
				fileAppend, rclick didnt work on sell bottom: %tempCoords2%`n, files\statistics.txt
			
			break
		}
		
		if(a_index > 1)
		{
			makeImage("sellItemError9")
			return 9
		}
	}
	
	rSleep(800, 1200)
	if(custom)
	{ 
		tempCoords2 := rClick(but.quantity) ;clicks on quantity
		fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(errorlevel)
		{
			rClick(but.quantity, , , , 1) ;clicks on item middle
			fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
			if(errorlevel)
			{
				makeImage("sellItemError14")
				return 14
			}
			else
				fileAppend, rclick didnt work on (sell) quantity: %tempCoords2%`n, files\statistics.txt
		}
		
		rSleep(400, 600)
		fsend.call("BackSpace", 7, 1)
		rSleep(800, 1200)
		fsend.call(ini.quantity)
		rSleep(800, 1200)
	}
	
	tempCoords2 := rClick(but.price) ;clicks on price
	rSleep(400, 600)
	fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
	if(errorlevel)
	{
		rClick(but.price, , , , 1) ;clicks on price middle
		fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(errorlevel)
		{
			makeImage("sellItemError15")
			return 15
		}
		else
			fileAppend, rclick didnt work on (sell) price: %tempCoords2%`n, files\statistics.txt
	}
	
	rSleep(400, 600)
	fsend.call("BackSpace", 5, 1)
	rSleep(800, 1200)
	fsend.call(ini.highMargin)
	rSleep(800, 1200)
	rClick(but.away) ;clicks away to minimize keyboard
	fIsearch.call(pics.confirmOffer, 1x, 1y, 0, 0, 0, 0, 4, 20)
	if(errorlevel)
	{
		tempCoords2 := rClick(but.price) ;clicks on price
		fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(errorlevel)
		{
			rClick(but.price, , , , 1) ;clicks on item middle
			fIsearch.call(pics.keyboard, 1x, 1y, 0, 0, 0, 0, 3, 20)
			if(errorlevel)
			{
				makeImage("sellItemError16")
				return 16
			}
			else
				fileAppend, rclick didnt work on (sell) price: %tempCoords2%`n, files\statistics.txt
		}
		
		rSleep(400, 600)
		fsend.call("enter", , 1)
	}
	else
	{
		rSleep(800, 1200)
		tempCoords4 := rClick(but.cOffer) ;clicks on confirm offer
	}
	
	fIsearch.call(pics.confirmOK, 1x, 1y, 0, 0, 0, 0, 3, 20)
	if(errorlevel)
	{
		rClick(but.away) ;clicks away to minimize keyboard
		rSleep(800, 1200)
		rClick(but.cOffer, , , , 1) ;clicks on confirm offer middle
		fIsearch.call(pics.confirmOK, 1x, 1y, 0, 0, 0, 0, 2, 20)
		if(errorlevel)
		{
			makeImage("sellItemError11")
			return 11
		}
		else if(tempCoords4)
			fileAppend, rclick didnt work on (sell) confirm offer: %tempCoords4%`n, files\statistics.txt
	}
	
	rSleep(400, 600)
	rClick([1x, 1y, 1x+140, 1y+24]) ;clicks confirm ok
	
	if(!custom)
	{
		now := A_now // 100
		IniWrite, %now%, %filedirectory%RSandroid.ini, %sec%, time
		IniWrite, 0, %filedirectory%RSandroid.ini, %sec%, buy
		iniwrite, % ini.highMargin, files\RSandroid.ini, %sec%, soldFor
		if(counter)
			iniwrite, %counter%, files\RSandroid.ini, %sec%, counter
	}
	
	fIsearch.call(pics.offerDoneInstantly, 2x, 2y, 0, 0, 0, 0, 3, 30)
	if(!errorlevel)
	{
		if(!custom)
			detProfit(slot, , sec)
		else
			tempGP := scanTotalGP()
		
		tempCoords2 := rClick([20, 2y, 53, 2y+28]) ;clicks to get items or money
		
		rSleep(500, 1000)
		fIsearchFast.call(pics.offerDoneInstantly, 2x, 2y, 0, 0, 0, 0, 30)
		if(!errorlevel)
			tempCoords3 := rClick([20, 2y, 53, 2y+28]) ;clicks to get items or money
		
		loop
		{
			if(a_index > 5)
			{
				fileAppend, rclick didnt work on (endOffer) collect items: %tempCoords2% of %tempCoords3%`n, files\statistics.txt
				rClick([20, 2y, 53, 2y+28], , , , 1) ;clicks on item middle
				rSleep(1000, 1500)
				
				fIsearchFast.call(pics.offerDoneInstantly, 2x, 2y, 0, 0, 0, 0, 20)
				if(!errorlevel)
				{
					fileAppend, rclick didnt work on (endOffer) collect items: %tempCoords2% of %tempCoords3%`n, files\statistics.txt
					rClick([20, 2y, 53, 2y+28], , , , 1) ;clicks on item middle
					rSleep(400, 600)
					if(goBackGE())
						return 10
				}
				
				break
			}
			
			sleep 1000
			fIsearchFast.call(pics.offerDoneInstantly, 2x, 2y, 0, 0, 0, 0, 20)
		} until (errorlevel)
		
		if(goBackGE())
			return 10
		else
			return 70
	}
	
	if(goBackGE())
		return 10
}

checkOfferDone(slot:=0) ;returns 1 if slot is done buying/selling, 0 if slot is not done, 2or10 if error occured
{
	if(goBackGE())
	{
		GuiControl, , % hOutput, checkOfferDone failed to go back GE
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		return 10
	}
	
	fIsearchFast.call(pics.offerDone, 1x, 1y, 290, 132, 365, 201, 20) ;checks #1 slot
	if(!ErrorLevel)
		s1 := 1
	Else
		s1 := 0
	
	fIsearchFast.call(pics.offerDone, 1x, 1y, 290, 218, 365, 288, 20) ;checks #2 slot
	if(!ErrorLevel)
		s2 := 1
	Else
		s2 := 0
	
	fIsearchFast.call(pics.offerDone, 1x, 1y, 290, 303, 365, 374, 20) ;checks #3 slot
	if(!ErrorLevel)
		s3 := 1
	Else
		s3 := 0
	
	if(!slot)
	{
		firstSlot := s1
		secondSlot := s2
		thirdSlot := s3
	}
	else
	{
		if(slot=1)
			return s1
		else if(slot=2)
			return s2
		else
			return s3
	}
}

checkFreeSlots(slot:=0) ;returns 1 if slot is free, 0 if slot is occuppied, 10 if error occured
{
	if(goBackGE())
	{
		GuiControl, , % hOutput, checkOfferDone failed to go back GE
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		return 10
	}
	
	fIsearchFast.call(pics.buyButton, 1x, 1y, 90, 134, 230, 212, 40) ;checks #1 slot
	if(!errorlevel)
		s1 := 1
	else 
		s1 := 0
		
	fIsearchFast.call(pics.buyButton, 1x, 1y, 90, 218, 230, 293, 40) ;checks #2 slot
	if(!errorlevel)
		s2 := 1
	else 
		s2 := 0
	
	fIsearchFast.call(pics.buyButton, 1x, 1y, 90, 305, 230, 381, 40) ;checks #3 slot
	if(!errorlevel)
		s3 := 1
	else 
		s3 := 0
	
	if(!slot) ;needed to check all offers
	{
		firstSlot := s1
		secondSlot := s2
		thirdSlot := s3
	}
	else
	{
		if(slot=1)
			return s1
		else if(slot=2)
			return s2
		else
			return s3
	}
}

endOffer(slot, notUpdateProf:=0, checkMoney:=0, again:=0) ;returns 0 if offer was free or done, 1 if offer was aborted, 2,3,4,5,6,10 if error
{
	if(slot < 0 || slot > 3)
		return 2
	
	if(goBackGE())
		return 10
	
	if(isFree:=checkFreeSlots(slot)) ;check free slots error
	{
		if(isFree = 1)
			return 0
		Else
			return 3
	}
	
	2x := 44
	if(slot = 1)
	{
		2y := 170
		ss := but.slot1
	}
	else if(slot = 2)
	{
		2y := 260
		ss := but.slot2
	}
	else if(slot = 3)
	{
		2y := 340
		ss := but.slot3
	}
	
	loop
	{
		if(a_index > 1)
			rClick(ss, , , , 1) ;clicks on # slot middle
		else
			tempCoords2 := rClick(ss) ;clicks on # slot
		
		fIsearch.call(pics.offerInputScreen, 1x, 1y, 0, 0, 0, 0, 6, 20)
		if(!errorlevel)
		{
			if(a_index > 1)
				fileAppend, rclick didnt work on endoffer slot%slot%: %tempCoords2%`n, files\statistics.txt
			
			break
		}
		
		if(a_index > 1)
		{
			if(again)
			{
				makeImage("endOfferReturn4")
				return 4
			}
			
			return endOffer(slot, notUpdateProf, checkMoney, 1)
		}
	}
	
	offerDoneInstantly:
	fIsearchFast.call(pics.offerDoneInstantly, 2x, 2y, 0, 0, 0, 0, 30)
	if(!errorlevel)
	{
		if(!notUpdateProf)
		{
			if(a:=detProfit(slot, checkMoney))
				fileAppend, detProfit error %a%`n, files\statistics.txt
		}
		else if(checkMoney)
			tempGP := scanTotalGP()
		
		tempCoords2 := rClick([20, 2y, 53, 2y+28]) ;clicks to get items or money
		
		rSleep(1000, 1500)
		fIsearchFast.call(pics.offerDoneInstantly, 2x, 2y, 0, 0, 0, 0, 20)
		if(!errorlevel)
		{
			tempCoords3 := rClick([20, 2y, 53, 2y+28]) ;clicks to get items or money
		}
		
		loop
		{
			if(a_index > 5)
			{
				fileAppend, rclick didnt work on (endOffer) collect items: %tempCoords2% or %tempCoords3%`n, files\statistics.txt
				rClick([20, 2y, 53, 2y+28], , , , 1) ;clicks on item middle
				rSleep(1500, 2000)
				
				fIsearchFast.call(pics.offerDoneInstantly, 1x, 1y, 0, 0, 0, 0, 20)
				if(!errorlevel)
				{
					fileAppend, rclick didnt work on (endOffer) collect items: %tempCoords2% or %tempCoords3%`n, files\statistics.txt
					rClick([20, 2y, 53, 2y+28], , , , 1) ;clicks on item middle
					rSleep(400, 600)
					if(goBackGE())
						return 10
				}
				
				break
			}
			
			sleep 1000
			fIsearchFast.call(pics.offerDoneInstantly, 2x, 2y, 0, 0, 0, 0, 20)
		} until (errorlevel)
		
		return goBackGE()
	}
	
	fIsearchFast.call(pics.aborted, 1x, 1y, 0, 0, 0, 0, 20)
	if(!errorlevel)
		goto collect
	
	fIsearchFast.call(pics.abortOfferButton, 1x, 1y, 0, 0, 0, 0, 20)
	if(errorlevel)
	{
		fIsearchFast.call(pics.offerDoneInstantly, 1x, 1y, 0, 0, 0, 0, 30)
		if(!errorlevel)
			goto offerDoneInstantly
		
		makeImage("endOfferReturn5")
		return 5
	}
	
	rSleep(400, 600)
	tempCoords2 := rClick([1x, 1y, 1x+30, 1y+30]) ;clicks on abort offer button
	fIsearch.call(pics.confirmOK, 1x, 1y, 0, 0, 0, 0, 3, 20)
	if(errorlevel)
	{
		fIsearchFast.call(pics.offerDoneInstantly, 1x, 1y, 0, 0, 0, 0, 30)
		if(!errorlevel)
			goto offerDoneInstantly
		
		rClick([1x, 1y, 1x+30, 1y+30], , , , 1) ;clicks on abort offer button middle
		fIsearch.call(pics.confirmOK, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(errorlevel)
		{
			makeImage("endOfferReturn6")
			return 6
		}
		else
			fileAppend, rclick didnt work on abort offer button: %tempCoords2%`n, files\statistics.txt
	}
	
	sleep 500
	tempCoords2 := rClick([1x, 1y, 1x+140, 1y+24]) ;clicks on confirm OK
	fIsearch.call(pics.abortACK, 1x, 1y, 0, 0, 0, 0, 3, 20)
	if(errorlevel)
	{
		rClick([1x, 1y, 1x+140, 1y+24], , , , 1) ;clicks on confirm OK middle
		fIsearch.call(pics.abortACK, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(errorlevel)
		{
			makeImage("endOfferReturn7")
			return 7
		}
		else
			fileAppend, rclick didnt work on (endOffer) confirm OK: %tempCoords2%`n, files\statistics.txt
	}
	
	tempCoords2 := rClick(but.abortAck) ;clicks on abort ACK
	fIsearch.call(pics.aborted, 1x, 1y, 0, 0, 0, 0, 3, 20)
	if(errorlevel)
	{
		rClick(but.abortAck, , , , 1) ;clicks on abort ACK middle
		fIsearch.call(pics.aborted, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(errorlevel)
		{
			makeImage("endOfferReturn8")
			return 8
		}
		else
			fileAppend, rclick didnt work on abortACK: %tempCoords2%`n, files\statistics.txt
	}
	
	collect:
	if(!notUpdateProf)
	{
		if(a:=detProfit(slot))
			fileAppend, detProfit error %a%`n, files\statistics.txt
	}
			
	rsleep(400, 600)
	tempCoords2 := rClick([20, 1y, 53, 1y+28]) ;clicks to get items or money
	
	rSleep(1000, 1500)
	
	fIsearchFast.call(pics.aborted, 2x, 2y, 0, 0, 0, 0, 20)
	if(!errorlevel)
	{
		tempCoords3 := rClick([20, 2y, 53, 2y+28]) ;clicks to get items or money
		
		loop
		{
			if(a_index > 5)
			{
				fileAppend, rclick didnt work on (endOffer) collect items: %tempCoords2% or %tempCoords3%`n, files\statistics.txt
				rClick([20, 2y, 53, 2y+28], , , , 1) ;clicks on item middle
				rSleep(1000, 1500)
				
				fIsearchFast.call(pics.aborted, 2x, 2y, 0, 0, 0, 0, 20)
				if(!errorlevel)
				{
					fileAppend, rclick didnt work on (endOffer) collect items: %tempCoords2% or %tempCoords3%`n, files\statistics.txt
					rClick([20, 2y, 53, 2y+28], , , , 1) ;clicks on item middle
					rSleep(400, 600)
					if(goBackGE())
						return 10
				}
				
				break
			}
			
			sleep 1000
			fIsearchFast.call(pics.aborted, 2x, 2y, 0, 0, 0, 0, 20)
		} until (errorlevel)
	}
	
	if(goBackGE())
		return 10
	else
		return 1
}

goBackGE() ;returns 0 if all good, returns 1 if failed
{
	loop
	{
		if(a_index > 2)
			timeToWait := 4
		else
			timeToWait := 6
		
		fIsearch.call(pics.GrandExchangeTitle, 1x, 1y, 0, 0, 0, 0, timeToWait, 20)
		if(!errorlevel)
		{
			fIsearchFast.call(pics.offerInputScreen, 1x, 1y, 0, 0, 0, 0, 20)
			if(errorlevel)
				return 0
		}
		
		fIsearchFast.call(pics.confirmOK, 1x, 1y, 0, 0, 0, 0, 20)
		if(!errorlevel)
			fClick.call(vysorBackX, vysorBackY)
		else if(a_index > 2)
			rClick(but.menuButton, , , , 1)
		else
			rClick(but.menuButton)
		
		fIsearch.call(pics.GrandExchange, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(!errorlevel)
		{
			if(a_index > 3)
				rClick(but.ge, , , , 1)
			else
				rClick(but.ge)
		}
		
		if(a_index > 4)
			rClick(but.menuButton2)
		
		if(a_index > 5)
		{
			makeImage("GobackGEerror")
			return 10
		}
	}
}

detProfit(slot, checkMoney:=0, sec:=0)
{
	total := scanTotalGP()
	if(checkMoney)
		tempGP := total
	
	if(!total)
		return 0
	
	if(!sec)
	{
		alt := detCurrentTrade(slot)
		if(alt < 0)
			return 4
		
		sec := sectionFinder(slot, alt)
	}
	
	ini := new AccountIni(sec)
	
	tt := a_now // 100
	stringTrimLeft, tt, tt, 6 ;removes year and month
	
	if(ini.buy = 1) ;current offer is bought
	{
		iniread, boughtFor, files\RSandroid.ini, %sec%, boughtFor, 0
		if(!boughtFor)
		{
			fileAppend, % "|UNDOCUMENTED| " mainIndex "acc " ini.item " boughtFor is not documented (" tt ")`n", files\statistics2.txt
			return 0
		}
		
		quantity := total / boughtFor
		qLen := strLen(quantity)
		Loop % qLen
		{
			num := SubStr(quantity, a_index, 1)
			if(num = "," or num = ".")
				break
			
			totNum .= num
		}
		
		if(totNum != quantity)
		{
			fileAppend, % mainIndex "acc bought " quantity " " ini.item " for " boughtFor "each, totalspend: " total " (" tt ")`n", files\statistics2.txt
			quantity := total // boughtFor
		}
		else 
		{
			quantity := total // boughtFor
			fileAppend, % mainIndex "acc bought " quantity " " ini.item " for " boughtFor "each, totalspend: " total " (" tt ")`n", files\statistics2.txt
		}
		
		iniwrite, %total%, files\RSandroid.ini, %sec%, spent
		iniwrite, %quantity%, files\RSandroid.ini, %sec%, bought
	}
	else ;current offer is sold
	{
		iniread, soldFor, files\RSandroid.ini, %sec%, soldFor, 0
		if(!soldFor)
		{
			fileAppend, % "|UNDOCUMENTED| " mainIndex "acc " ini.item " soldFor is not documented (" tt ")`n", files\statistics2.txt
			return 0
		}
		
		if(ini.spent = 0)
		{
			fileAppend, % "|UNDOCUMENTED| " mainIndex "acc sold " quantity " " ini.item " for " soldFor "each, totalearn: " total " (" tt ")`n", files\statistics2.txt
			return 0
		}
		
		quantity := total / soldFor
		qLen := strLen(quantity)
		Loop % qLen
		{
			num := SubStr(quantity, a_index, 1)
			if(num = "," or num = ".")
				break
			
			totNum .= num
		}
		
		if(totNum != quantity)
		{
			fileAppend, % mainIndex "acc sold " quantity " " ini.item " for " soldFor "each, totalearn: " total " (" tt ")`n", files\statistics2.txt
			quantity := total // soldFor
		}
		else 
		{
			quantity := total // soldFor
			fileAppend, % mainIndex "acc sold " quantity " " ini.item " for " soldFor "each, totalearn: " total " (" tt ")`n", files\statistics2.txt
		}
		
		iniwrite, %total%, files\RSandroid.ini, %sec%, earned
		iniwrite, %quantity%, files\RSandroid.ini, %sec%, sold
		
		iniread, bought, files\RSandroid.ini, %sec%, bought, 0
		iniread, boughtFor, files\RSandroid.ini, %sec%, boughtFor, 0
		
		if(!bought)
			return 0
		
		if(!boughtFor)
			return 0
			
		if(quantity = bought)
		{
			profit := total - ini.spent
		}
		else
		{
			profit := total - (quantity * boughtFor)
		}
		
		GuiControlGet, ProfitEdit
		ProfitEdit += profit
		GuiControl, , ProfitEdit, %ProfitEdit%
	}
}

detCurrentTrade(slot) ;returns alternate value, negative indicates error
{
	sec0 := sectionFinder(slot, 0)
	sec1 := sectionFinder(slot, 1)
	sec2 := sectionFinder(slot, 2)
	iniread, lTime0, files\RSandroid.ini, %sec0%, time
	iniread, lTime1, files\RSandroid.ini, %sec1%, time
	iniread, lTime2, files\RSandroid.ini, %sec2%, time
	rTime0 := a_now
	rTime1 := a_now
	rTime2 := a_now
	EnvSub, rTime0, %lTime0%, minutes
	EnvSub, rTime1, %lTime1%, minutes
	EnvSub, rTime2, %lTime2%, minutes
	
	if(rTime0 < rTime1 && rTime0 < rTime2)
	{
		return 0
	}
	else if(rTime1 < rTime0 && rTime1 < rTime2)
	{
		return 1
	}
	else if(rTime2 < rTime0 && rTime2 < rTime1)
	{
		return 2
	}
	else
		return -1
}
;-------------************TRADING END************--------------

;-------------************MARGIN UPDATE************-----------
updateMargin()
{
	loop 3
	{
		slot := a_index
		alternate := checkIfNeedToUpdate(slot)
		if(alternate = -2)
		{
			a := "checkIfNeedToUpdate Error"
			return a
		}
		
		if(alternate != -1)
		{
			GuiControl, , % hOutput, margin update needed on %slot% slot
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			
			sec := sectionFinder(slot, alternate)
			
			if(a:=endOffer(slot))
			{
				if(a = 1) ;aborted the offer
				{
					iniwrite, 1, %fileDirectory%RSandroid.ini, %sec%, buy
				}
				else
				{
					a := "endOffer return " . a
					return a
				}
			}
			
			ini := new AccountIni(sec)
			ini.highMargin *= 5
			
			GuiControl, , % hOutput, going to buy item in margin update
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			
			loop ;buyItem loop
			{
				b := buyItem(slot, 1, ini.highMargin, 1, , , alternate)
				if(b && (b != 70))
				{
					if(b = 69) ;could not buy (maybe not enough money?)
					{
						GuiControl, , % hOutput, could not buy item in margin
						sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
						
						updateMarginError(sec, 1, 1, 1)
						continue 2
					}
					
					updateMarginError(sec, 1, 1, 1)
					b := "buyItem return at top " . b
					return b
				}
				else if(b != 70) ;offer did not finish instantly
				{
					if(a_index > 1) ;already tried to buy again with increased price
					{
						updateMarginError(sec, "offer Not Finished 2 Times", ini.highMargin, -1)
						a := endOffer(slot, 1)
						if(a && a != 1) ;endOffer error
						{
							a := "first endOffer (buying) error " . a
							return a
						}
							
						if(goBackGE())
							return 10
							
						continue 2
					}
					
					if(a:=endOffer(slot, 1, 1))
					{
						if(a=1) ;offer did not finish
						{
							GuiControl, , % hOutput, offer did not finish|increasing price
							sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
							
							ini.highMargin *= 5
							b := scanMoney()
							if(!b) ;scanMoney failed
							{
								if(goBackGe())
									return 10
								
								updateMarginError(sec, 1, 1, 1)
								continue 2
							}
							else if(ini.highMargin >= b && b > 0) ;not enough money
							{
								ini.highMargin := b - (b // 100)
								if(ini.highMargin <= 0)
								{
									if(goBackGe())
										return 10
									
									updateMarginError(sec, "margin negative", ini.highMargin, -1)
									continue 2
								}
								else
									continue
							}
							else ;enough money
								continue
						}
						else ;endOffer error
						{
							a := "second endOffer (buying) error " . a
							return a
						}
					}
				}
				
				break
			}
			
			highMargin1 := tempGP
			GuiControl, , % hOutput, highMargin1: %highMargin1%
			
			GuiControl, , % hOutput, going to sell item in margin update
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			
			b := sellItem(slot, 1, 1, 1, alternate)
			if(b && (b != 70)) ;sellItem error
			{
				GuiControl, , % hOutput, sellItem error
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				b := "sellItem error on " . slot . " slot:" . b
				return b
			}
			else if(b != 70)
			{
				if(a:=endOffer(slot, 1, 1))
				{
					if(a=1) ;offer was aborted
					{
						updateMarginError(sec, "could not sell item", ini.highMargin, -1)
						continue
					}
					else
					{
						a := "endOffer(selling) error " . a
						return a
					}
				}
			}
			
			lowMargin1 := tempGP
			GuiControl, , % hOutput, lowMargin1: %lowMargin1%
			GuiControl, , % hOutput, starting to check margin price
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			
			if(slot = 1)
			{
				2y := 134
				3y := 212
				bb := but.buy1
			}
			else if(slot = 2)
			{
				2y := 218
				3y := 293
				bb := but.buy2
			}
			else if(slot = 3)
			{
				2y := 305
				3y := 381
				bb := but.buy3
			}
			
			fIsearch.call(pics.buyButton, 1x, 1y, 90, 2y, 230, 3y, 5, 40)
			if(errorlevel)
			{
				fileName := "UMarginError1_" . sec
				makeImage(fileName)
				return 1
			}
			
			rSleep(400, 600)
			tempCoords2 := rClick(bb) ;clicks on buy
			
			fIsearch.call(pics.GEbuy, 1x, 1y, 0, 0, 0, 0, 7, 20)
			if(errorlevel)
			{
				if(goBackGE())
					return 10
				
				rClick(bb, , , , 1) ;clicks on buy middle
				fIsearch.call(pics.GEbuy, 1x, 1y, 0, 0, 0, 0, 7, 20)
				if(errorlevel)
				{
					makeImage("UpdateMarginError2")
					return 2
				}
				else
					fileAppend, rclick didnt work on (updateMargin): %tempCoords2%`n, files\statistics.txt
			}
			
			sleep 1000
			
			GuiControl, , % hOutput, length of price: %lengthOfPrice%
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			
			ini.lowMargin := leaveOnlyNumbers(OCR([124, 324, 100, 20]))
			ini.highMargin := leaveOnlyNumbers(OCR([142, 389, 100, 20]))
			
			GuiControl, , % hOutput, % "lowMargin: " ini.lowMargin "| highMargin: " ini.highMargin
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			
			tempLowMargin := ini.lowMargin
			tempHighMargin := ini.highMargin
			
			if(recheckAndFixOCR(tempLowMargin, tempHighMargin, sec, lowMargin1, highMargin1))
			{
				updateMarginError(sec, 1, 1, 1)
				continue
			}
			
			ini.lowMargin := tempLowMargin
			ini.highMargin := tempHighMargin
			
			IniWrite, % ini.lowMargin, %filedirectory%margins.ini, % ini.item, lowMargin
			IniWrite, % ini.highMargin, %filedirectory%margins.ini, % ini.item, highMargin
			
			if(goBackGe())
				return 10
			
			now := A_now // 100
			IniWrite, %now%, %filedirectory%RSandroid.ini, %sec%, time
			IniWrite, %now%, %filedirectory%margins.ini, % ini.item, uMarginTime
			IniWrite, 0, %filedirectory%margins.ini, % ini.item, FailedToUpdate
			
			GuiControl, , % hOutput, done updating margin on %slot% slot
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		}
	}
}

recheckAndFixOCR(byref lowMargin, byref highMargin, sec, lowMargin1, highMargin1)
{
	ini := new AccountIni(sec)
	lengthOfPrice := StrLen(ini.highMargin)
	recheck := false
	prevLowMargin := ini.lowMargin
	prevHighMargin := ini.highMargin
	beginLowMargin := lowMargin
	beginHighMargin := highMargin
	secondOcr := 0
	prevMarginRecheck := 0
	
	if lowMargin not contains 1,2,3,4,5,6,7,8,9
		recheck := true
		
	StringLeft, leftLowMargin, lowMargin, 1
	
	loop ;checks lowmargin
	{
		if(recheck || (lowMargin < (prevLowMargin // 3)) || (lowMargin > (prevLowMargin * 3)))
		{
			GuiControl, , % hOutput, Odd lowMargin/rechecking %a_index% time
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			
			if(a_index > 3)
			{
				if(lowMargin = lowMargin1 && lowmargin && lowmargin1)
				{
					GuiControl, , % hOutput, keeping lowMargin because it matches totalGP scan
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
					break
				}
				else if(beginLowMargin = lowMargin1 && beginLowMargin && lowmargin1)
				{
					GuiControl, , % hOutput, keeping beginLowMargin because it matches totalGP scan
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
					lowMargin := beginLowMargin
					break
				}
				else if((ini.item = "maple logs") && (lowmargin = 0) && (lengthOfLowMargin < lengthOfPreviousLowMargin))
				{
					GuiControl, , % hOutput, item is maple logs/adding 9 at beginning of lowMargin
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
					lowMargin := "9" . lowMargin
					break
				}
				
				GuiControl, , % hOutput, lowMargin failed
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				updateMarginError(sec, lowMargin, HighMargin)
				return 1
			}
			
			if(a_index = 1)
			{
				StringRight, rightLowMargin, lowMargin, 1
				lengthOfLowMargin := StrLen(lowMargin)
				lengthOfPreviousLowMargin := StrLen(prevLowMargin)
				if(rightLowMargin="9" && (lengthOfLowMargin > lengthOfPreviousLowMargin))
				{
					GuiControl, , % hOutput, removing 9 from the end of lowmargin
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
					
					stringTrimRight, lowMargin, lowMargin, 1
					recheck := false
					
					GuiControl, , % hOutput, lowMargin: %lowMargin%
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
					continue
				}
			}
			
			if(!secondOcr)
			{
				GuiControl, , % hOutput, rescanning
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				lowMargin := leaveOnlyNumbers(OCR([70, 324, 200, 20]), 1)
				recheck := false
				secondOcr := 1
				
				GuiControl, , % hOutput, lowMargin: %lowMargin%
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				continue
			}
			
			if(lengthOfPreviousLowMargin > lengthOfLowMargin && !prevMarginRecheck)
			{
				GuiControl, , % hOutput, adding 9 at beginning of lowmargin
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				StringLeft, leftPrevLowMargin, prevLowMargin, 1
				if(leftPrevLowMargin = "5")
					lowMargin := "5" . lowMargin
				else if(leftPrevLowMargin = "9")
					lowMargin := "9" . lowMargin
				
				GuiControl, , % hOutput, lowMargin: %lowMargin%
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				prevMarginRecheck := 1
			}
			else if(leftLowMargin = "5" && !prevMarginRecheck)
			{
				GuiControl, , % hOutput, substituting 5 with 9 for lowmargin
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				stringTrimLeft, lowMargin, lowMargin, 1
				lowMargin := "9" . lowMargin
				
				GuiControl, , % hOutput, lowMargin: %lowMargin%
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				prevMarginRecheck := 1
			}
			else if(leftLowMargin = "9" && !prevMarginRecheck)
			{
				GuiControl, , % hOutput, substituting 5 with 9 for lowmargin
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				stringTrimLeft, lowMargin, lowMargin, 1
				lowMargin := "5" . lowMargin
				
				GuiControl, , % hOutput, lowMargin: %lowMargin%
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				prevMarginRecheck := 1
			}
		}
		else
			break
	}
	
	recheck := false
	secondOcr := 0
	prevMarginRecheck := 0
	
	if highMargin not contains 1,2,3,4,5,6,7,8,9
		recheck := true
	
	StringLeft, leftHighMargin, highMargin, 1
	
	loop ;checks highmargin
	{
		if(recheck || (highmargin < (prevHighMargin // 3)) || (highmargin > (prevHighMargin * 3)))
		{
			GuiControl, , % hOutput, Odd highMargin/rechecking %a_index% time
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			
			if(a_index > 3)
			{
				if(highmargin = highmargin1 && highMargin && highmargin1)
				{
					GuiControl, , % hOutput, keeping highMargin because it matches totalGP scan
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
					break
				}
				else if(beginHighMargin = highmargin1 && beginHighMargin && highmargin1)
				{
					GuiControl, , % hOutput, keeping beginHighMargin because it matches totalGP scan
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
					highmargin := beginHighMargin
					break
				}
				else if((ini.item = "maple logs") && (highmargin = 0) && (lengthOfHighMargin < lengthOfPrevioushighMargin))
				{
					GuiControl, , % hOutput, item is maple logs/adding 9 at beginning of highmargin
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
					highmargin := "9" . highMargin
					break
				}
				
				GuiControl, , % hOutput, highMargin failed
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				updateMarginError(sec, lowMargin, HighMargin)
				return 1
			}
			
			if(a_index = 1)
			{
				StringRight, rightHighMargin, highMargin, 1
				lengthOfHighMargin := StrLen(highMargin)
				lengthOfPrevioushighMargin := StrLen(prevhighMargin)
				if(rightHighMargin="9" && (lengthOfHighMargin > lengthOfPrevioushighMargin))
				{
					stringTrimRight, highMargin, highMargin, 1
					recheck := false
					
					GuiControl, , % hOutput, highMargin: %highMargin%
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
					continue
				}
			}
			
			if(!secondOcr)
			{
				GuiControl, , % hOutput, rescanning
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				highMargin := leaveOnlyNumbers(OCR([70, 389, 200, 20]), 1)
				recheck := false
				secondOcr := 1
				
				GuiControl, , % hOutput, highMargin: %highMargin%
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				continue
			}
			
			if((lengthOfPrevioushighMargin > lengthOfHighMargin) && !prevMarginRecheck)
			{
				GuiControl, , % hOutput, adding 9 at beginning of highmargin
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				StringLeft, leftPrevHighMargin, prevHighMargin, 1
				if(leftPrevHighMargin = "5")
					highMargin := "5" . highMargin
				else if(leftPrevHighMargin = "9")
					highMargin := "9" . highMargin
				
				GuiControl, , % hOutput, highMargin: %highMargin%
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				prevMarginRecheck := 1
			}
			else if(leftHighMargin = "5" && !prevMarginRecheck)
			{
				GuiControl, , % hOutput, substituting 5 with 9 for highmargin
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				stringTrimLeft, highmargin, highmargin, 1
				highmargin := "9" . highmargin
				
				GuiControl, , % hOutput, highMargin: %highMargin%
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				prevMarginRecheck := 1
			}
			else if(leftHighMargin = "9" && !prevMarginRecheck)
			{
				GuiControl, , % hOutput, substituting 5 with 9 for highmargin
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				stringTrimLeft, highmargin, highmargin, 1
				highmargin := "5" . highmargin
				
				GuiControl, , % hOutput, highMargin: %highMargin%
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				prevMarginRecheck := 1
			}
		}
		else
			break
	}
	
	loop 2 ;checks length
	{
		if(a_index = 1)
			lengthOfcMargin := StrLen(lowMargin)
		else
			lengthOfcMargin := StrLen(highMargin)
		
		if(a_index = 1)
			GuiControl, , % hOutput, lengthOflowMargin: %lengthOfcMargin%
		else
			GuiControl, , % hOutput, lengthOfhighMargin: %lengthOfcMargin%
		
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		
		if(a_index = 1)
			StringLeft, firstNum, lowMargin, 1
		else
			StringLeft, firstNum, highMargin, 1
		
		if(firstNum = 1 || firstNum = 2 || firstNum = 3)
			offset := -1
		else if(firstNum = 9 || firstNum = 8 || firstNum = 7)
			offset := 1
		else
			offset := 0
		
		GuiControl, , % hOutput, offset: %offset%
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		
		if(lengthOfcMargin != lengthOfPrice)
		{
			if((lengthOfcMargin + offset) != lengthOfPrice)
			{
				GuiControl, , % hOutput, length of new price does not match
				sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				
				now := a_now // 100
				EnvSub, now, % ini.uMarginTime, days
				if(now < 3)
				{
					if(a_index = 1)
					{
						if(lowMargin = lowMargin1)
						{
							GuiControl, , % hOutput, ignoring lowMargin length because it matches totalGP scan
							sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
							break
						}
						else if(beginLowMargin = lowMargin1)
						{
							GuiControl, , % hOutput, ignoring beginLowMargin length because it matches totalGP scan
							sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
							lowMargin := beginLowMargin
							break
						}
					}
					else
					{
						if(highMargin = highMargin1)
						{
							GuiControl, , % hOutput, ignoring highMargin length because it matches totalGP scan
							sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
							break
						}
						else if(beginHighMargin = highMargin1)
						{
							GuiControl, , % hOutput, ignoring beginHighMargin length because it matches totalGP scan
							sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
							highMargin := beginHighMargin
							break
						}
					}
					
					GuiControl, , % hOutput, error updating margin length of new price exceeds previous one (%a_index%)
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
					updateMarginError(sec, lowMargin, HighMargin)
					return 1
				}
				else
				{
					lastMarginTime:=ini.uMarginTime
					tempItem := ini.item
					now := a_now // 100
					FileAppend,
					(
					ocr recheck ignored length for %mainIndex%. acc %tempItem% item of magin 
					because last update was more than 3 days ago:
					last margin time: %lastMarginTime%, now: %now%`n
					), %fileDirectory%statistics.txt
					
					GuiControl, , % hOutput, ignored length / last update was more than 3 days ago
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
				}
			}
		}
	}
	
	if(HighMargin < lowMargin) 
	{
		now := a_now // 100
		stringTrimLeft, now, now, 8
		
		GuiControl, , % hOutput, highmargin lower than lowmargin|swapping
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		temp := HighMargin
		HighMargin := lowMargin
		lowMargin := temp
	}
	
	if(HighMargin = lowMargin)
	{
		GuiControl, , % hOutput, highmargin = lowmargin|++HighMargin --lowMargin
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		++HighMargin
		--lowMargin
	}
	
	if(beginLowMargin != lowMargin || beginHighMargin != highMargin)
	{
		tempItem := ini.item
		FileAppend,
		(
		ocr recheck fixed the issue for %tempItem%
			beginLowMargin: %beginLowMargin% / beginHighMargin: %beginHighMargin%
			lowMargin: %lowmargin% / highMargin: %highMargin%`n
		), %fileDirectory%statistics.txt
		
		makeImage("recheckOCR", , 2)
	}
}

updateMarginError(sec, lowMargin, HighMargin, noPicture:=0)
{
	now := A_now // 100
	IniWrite, %now%, %filedirectory%RSandroid.ini, %sec%, time
	IniRead, item, %filedirectory%RSandroid.ini, %sec%, item
	IniWrite, 1, %filedirectory%margins.ini, %item%, failedToUpdate
	stringTrimLeft, now, now, 8
	
	if(noPicture <= 0)
	{
		if(noPicture = 0)
		{
			fileName := "failedMargin_" . item . "_" . now . ".bmp"
			makeImage(fileName, 4)
		}
		else
		{
			fileName := "failedMargin_" . item
			makeImage(fileName)
		}
		
		text := "lowMargin: " . lowMargin . ", highMargin: " . highMargin . ",for " . fileName
		FileAppend, %text%`n, %fileDirectory%statistics.txt
	}
	
	rSleep(800, 1200)
	goBackGE()
}

checkIfNeedToUpdate(slot) ;returns 0,1,2 if update needed, returns -1 if update not needed, returns -2 if error occured
{
	GuiControlGet, UpdateMarginTime, , UpdateMarginTimeEdit
	free := checkFreeSlots(slot)
	if(free > 1) ;error occured
		return -2
	
	if(free) ;slot is free
	{
		alternate := determineTradeSection(slot, 1)
		if(alternate = -1)
		{
			GuiControl, , % hOutput, failed margin or limit reached
			sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
			return -1
		}
		
		
		sec := sectionFinder(slot, alternate)
		ini := new AccountIni(sec)
		now := A_Now // 100
		EnvSub, now, % ini.uMarginTime, minutes
		if(now >= UpdateMarginTime) ;checks upgrade margin time
		{
			now := A_Now // 100
			EnvSub, now, % ini.time, minutes
			if(now >= UpdateMarginTime) ;checks slot time
				return alternate
			else
				return -1
		}
		else
			return -1
	}
	else
	{
		sec0 := sectionFinder(slot, 0)
		sec1 := sectionFinder(slot, 1)
		sec2 := sectionFinder(slot, 2)
		
		ini0 := new AccountIni(sec0)
		ini1 := new AccountIni(sec1)
		ini2 := new AccountIni(sec2)
	
		if(ini0.time > ini1.time && ini0.time > ini2.time) ;last traded normal
		{
			now := A_Now // 100
			EnvSub, now, % ini0.uMarginTime, minutes
			if(now >= UpdateMarginTime) ;checks upgrade margin time
			{
				now := A_Now // 100
				EnvSub, now, % ini0.time, minutes
				if(now >= UpdateMarginTime) ;checks slot time
					return 0
				else
					return -1
			}
			else
				return -1
		}
		else if(ini1.time > ini0.time && ini1.time > ini2.time) ;last traded alt1
		{
			now := A_Now // 100
			EnvSub, now, % ini1.uMarginTime, minutes
			if(now >= UpdateMarginTime) ;checks upgrade margin time
			{
				now := A_Now // 100
				EnvSub, now, % ini1.time, minutes
				if(now >= UpdateMarginTime) ;checks slot time
					return 1
				else
					return -1
			}
			else
				return -1
		}
		else ;last traded alt2
		{
			now := A_Now // 100
			EnvSub, now, % ini2.uMarginTime, minutes
			if(now >= UpdateMarginTime) ;checks upgrade margin time
			{
				now := A_Now // 100
				EnvSub, now, % ini2.time, minutes
				if(now >= UpdateMarginTime) ;checks slot time
					return 2
				else
					return -1
			}
			else
				return -1
		}
	}
}

;-------------************MARGIN UPDATE END************--------------

;-------------************IMAGE HANDLING************-----------------

itemPictureSearch(itemName, numFromTop, sell := 0, additionalPicsArray := 0, neededToUpdate := 1) ;returns 0 if no match
{
	GuiControl, , % hOutput, starting to look for %itemName% image
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	
	StringReplace, itemName, itemName, %A_SPACE%, , All
	
	sleep 2000
	fIsearchFast.call(pics[itemName], 1x, 1y, 0, 0, 0, 0, 30)
	if(!errorlevel)
	{
		GuiControl, , % hOutput, % "found item " itemName
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		sleep 1000
		return 1 ;found
	}
	
	if(additionalPicsArray)
	{
		fIsearchFast.call(additionalPicsArray, 2x, 2y, 0, 0, 0, 0, 30)
		if(!errorlevel)
			return 2 ;found additional pic
	}
	
	if(!neededToUpdate)
		return 0
	
	
	GuiControl, , % hOutput, item picture search no results
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	
	key := pics[itemName].length()
	image := pics[itemName][key]
	
	if(key != 1)
		StringTrimRight, image, image, 5
	else
		StringTrimRight, image, image, 4
	
	++key
	image .= key . ".bmp"
	
	if(!sell)
		makeImage(image, numFromTop, 1)
	else
		makeImage(image, 3, 1)
	
	if(sell)
		FileAppend, updated %image% in sell`n, %fileDirectory%statistics.txt
	else
		FileAppend, updated %image% in buy`n, %fileDirectory%statistics.txt
	
	pics[itemName][key] := image
	
	;IniWrite, 0, %filedirectory%PictureStatistics.ini, Pictures, %image%
	
	GuiControl, , % hOutput, updated picture %image%
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	return 0
}

scanMoney(dontGoBackGE:=0) ;returns 0 if error
{
	if(!dontGoBackGE)
	{
		if(goBackGE())
			return 0
	}
	
	a := leaveOnlyNumbers(OCR([223, 678, 118, 28])) ;scans money, then leaves only numbers
	if a not contains 1,2,3,4,5,6,7,8,9 ;if the string is empty
	{
		FileAppend, Account %mainIndex% money could not be identified`n, %fileDirectory%statistics.txt
		name := mainIndex . "accountsMoney.bmp"
		makeImage(name, 5)
		return 0
	}
	
	return a
}

scanTotalGP() ;returns 0 if error, otherwise returns value of totalGP 
{
	fIsearchFast.call(pics.totalGP, 2x, 2y, 0, 0, 0, 0, 20)
	if(errorlevel)
	{
		loop, files, files\info\*.bmp
		{
			if A_LoopFileName contains totalGPNotFound ;pic already exists
			{
				return 0
			}
		}
		
		makeImage("totalGPNotFound", , 2)
		return 0
	}

	2x += 200
	total := leaveOnlyNumbers(OCR([2x, 2y, 117, 20]))
	if total not contains 1,2,3,4,5,6,7,8,9,0
	{
		if(total != "")
		{
			nameA := "totGPErrorA" . total
			nameB := "totGPErrorB" . total
			makeImage(nameA, , 2, 2x, 2y, 117, 20)
			makeImage(nameB, , 2)
		}
		return 0
	}
	
	return total
}

makeImage(fileName, preset:=0, directory:=0, cX0:=0, cY0:=0, cX1:=0, cY1:=0)
{
	if(!directory)
		directory := fileDirectory . "errors\"
	else if(directory = 1)
		directory := fileDirectory
	else if(directory = 2)
		directory := fileDirectory . "info\"
	
	If !pToken := Gdip_Startup()
	{
		MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
		ExitApp
	}
		
	if(cX0||cY0||cX1||cY1) ;custom picture
	{
		x = cX0
		y = cY0
		w = cX1 - cX0
		h = cY1 - cY0
	}
	else if(preset=1) ;first buy item picture
	{
		x = 2
		y = 174
		w = 55
		h = 55
	}
	else if(preset=2) ;second buy item picture
	{
		x = 2
		y = 238
		w = 55
		h = 55
	}
	else if(preset = 3) ;sell item picture
	{
		x = 14
		y = 223
		w = 53
		h = 47
	}
	else if(preset = 4) ;margin picture
	{
		x = 72
		y = 294
		w = 263
		h = 118
	}
	else if(preset = 5) ;money picture
	{
		x = 226
		y = 679
		w = 134
		h = 22
	}
	else ;whole bs
	{
		now := a_now
		stringTrimLeft, now, now, 8
		fileName := directory . fileName . "_" . now . ".bmp"
		pBitmap:=Gdip_BitmapFromScreen()
		pBitmap_part:=Gdip_CloneBitmapArea(pBitmap, 0, 0, 370, 767)
		Gdip_SaveBitmapToFile(pBitmap_part, filename)
		Gdip_DisposeImage(pBitmap)
		Gdip_DisposeImage(pBitmap_part)
		Gdip_Shutdown(pToken)
		return 0
	}
	
	fileName := directory . fileName
	pBitmap:=Gdip_BitmapFromScreen()
	pBitmap_part:=Gdip_CloneBitmapArea(pBitmap, x, y, w, h) 
	Gdip_SaveBitmapToFile(pBitmap_part, filename)
	Gdip_DisposeImage(pBitmap)
	Gdip_DisposeImage(pBitmap_part)
	Gdip_Shutdown(pToken)
}

leaveOnlyNumbers(string, ignoreSpaces:=0)
{
	length := StrLen(string)
	loop % length
	{
		StringMid, num, string, %a_index%, 1
		if(num = a_space && !ignoreSpaces)
			break
		If InStr("0123456789", num)
			string2 := string2 . num
	}
	return string2
}

;------------************IMAGE HANDLING END************--------------

;------------************ENDING************--------------------------
logOut()
{
	if(goBackGE())
	{
		return 10
	}
	
	loop 2
	{
		rClick(but.menuButton)
		fIsearch.call(pics.logOut, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(!errorlevel)
			break
	}
	
	if(errorlevel)
	{
		makeImage("logOutError2")
		return 2
	}
	
	rClick(but.logOut) ;clicks on logout
	
	loop
	{
		fIsearch.call(pics.confirmOK, 1x, 1y, 0, 0, 0, 0, 3, 20)
		if(!errorlevel)
		{
			if(confirmOK)
				rClick([1x, 1y, 1x+140, 1y+24], , , , 1) ;clicks on confirm ok middle
			else
			{
				confirmOK := 1
				rClick([1x, 1y, 1x+140, 1y+24]) ;clicks on confirm ok
			}
		}
		
		fIsearch.call(pics.Login, 1x, 1y, 0, 0, 0, 0, 5, 30)
		if(!errorlevel)
			return 0
		
		if(a_index > 2)
		{
			makeImage("logOutError3")
			return 3
		}
		
		if(a_index > 1)
		{
			fIsearch.call(pics.logOut, 1x, 1y, 0, 0, 0, 0, 3, 20)
			if(!errorlevel)
				rClick(but.logOut) ;clicks on logout
		}
	}
}

updateQuantity()
{
	now := a_now // 100
	
	loop 3
	{
		sec := sectionFinder(a_index)
		ini := new AccountIni(sec)
		
		if(ini.FailedToUpdate = 1)
			return 0
			
		if(ini.buyTime < ini.uQuantityTime)
			return 0
	}
	
	GuiControl, , % hOutput, updating quantity
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	goBackGE()
	rSleep(800, 1200)
	a := scanMoney()
	if(!a) ;scanMoney error
		return 0
	
	GuiControl, , % hOutput, money = %a%
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	
	if(a > 200000)
	{
		;FileAppend,	%mainIndex% account has %a% money`n, %fileDirectory%statistics.txt
		a -= 100000
		a := a // 4 ;a is money that each slot could distribute
		loop 3
		{
			index := a_index
			loop 3
			{
				if(a_index = 1)
					sec := sectionFinder(index, 0)
				else if(a_index = 2)
					sec := sectionFinder(index, 1)
				else
					sec := sectionFinder(index, 2)
				
				ini := new AccountIni(sec)
				
				b := a // ini.highMargin
				if(ini.quantity = 0)
				{
					fileAppend, % "update quantity detected " ini.item " quantity = 0, first`n", files\statistics.txt
					continue
				}
				
				if ini.quantity not contains 1,2,3,4,5,6,7,8,9
				{
					FileAppend,	Account %mainIndex% section %sec% has wrong quantity `n, %fileDirectory%statistics.txt
					continue
				}
				
				ini.quantity += b
				
				if(ini.quantity >= ini.itemLimit)
				{
					ini.quantity := ini.itemLimit
				}
				
				if(ini.quantity = 0)
				{
					fileAppend, % "update quantity detected " ini.item " quantity = 0, second`n", files\statistics.txt
					continue
				}
					
				IniWrite, % ini.quantity, %fileDirectory%RSandroid.ini, %sec%, quantity
			}
		}
		
		sec := mainIndex . "other"
		IniWrite, %now%, %fileDirectory%RSandroid.ini, %sec%, uQuantityTime
	}
}

averageQuantities()
{
	GuiControl, , % hOutput, averaging quantities
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	
	loop 3
	{
		alt := a_index - 1
		
		sec1 := sectionFinder(1, alt)
		sec2 := sectionFinder(2, alt)
		sec3 := sectionFinder(3, alt)
		ini1 := new AccountIni(sec1)
		ini2 := new AccountIni(sec2)
		ini3 := new AccountIni(sec3)
		
		sum1 := ini1.quantity * ini1.highMargin
		sum2 := ini2.quantity * ini2.highMargin
		sum3 := ini3.quantity * ini3.highMargin
		totalMoney := sum1 + sum2 + sum3
		
		average := totalMoney // 3
		ini1Permquantity := average // ini1.highMargin
		ini2Permquantity := average // ini2.highMargin
		ini3Permquantity := average // ini3.highMargin
		
		if(ini1Permquantity > ini1.itemLimit)
		{
			ini1Limit := 1
			ini1Overhead := ini1Permquantity - ini1.itemLimit
			ini1Overhead := ini1Overhead * ini1.highMargin ;money tht could be added to other slots
			ini1.quantity := ini1.itemLimit
		}
		
		if(ini2Permquantity > ini2.itemLimit)
		{
			ini2Overhead := ini2Permquantity - ini2.itemLimit
			ini2Overhead := ini2Overhead * ini2.highMargin ;money tht could be added to other slots
			ini2Limit := 1
			ini2.quantity := ini2.itemLimit
		}
		
		if(ini3Permquantity > ini3.itemLimit)
		{
			ini3Overhead := ini3Permquantity - ini3.itemLimit
			ini3Overhead := ini3Overhead * ini3.highMargin ;money tht could be added to other slots
			ini3Limit := 1
			ini3.quantity := ini3.itemLimit
		}
		
		if(ini1Limit && ini2Limit && ini3Limit)
		{
			
		}
		else if(ini1Limit && ini2Limit)
		{
			ini3.quantity := (average + ini2Overhead + ini1Overhead) // ini3.highMargin
			if(ini3.quantity > ini3.itemLimit)
				ini3.quantity := ini3.itemLimit
			
		}
		else if(ini1Limit && ini3Limit)
		{
			ini2.quantity := (average + ini1Overhead + ini3Overhead) // ini2.highMargin
			if(ini2.quantity > ini2.itemLimit)
				ini2.quantity := ini2.itemLimit
		}
		else if(ini2Limit && ini3Limit)
		{
			ini1.quantity := (average + ini2Overhead + ini3Overhead) // ini1.highMargin
			if(ini1.quantity > ini1.itemLimit)
				ini1.quantity := ini1.itemLimit
		}
		else if(ini1Limit)
		{
			ini1Overhead //= 2
			ini2.quantity := (average + ini1Overhead) // ini2.highMargin
			ini3.quantity := (average + ini1Overhead) // ini3.highMargin
			
			if(ini2.quantity > ini2.itemLimit)
			{
				ini2Overhead := ini2.quantity - ini2.itemLimit
				ini2Overhead *= ini2.highMargin
				ini2.quantity := ini2.itemLimit
				ini2Limit2 := 1
			}
			
			if(ini3.quantity > ini3.itemLimit)
			{
				ini3Overhead := ini3.quantity - ini3.itemLimit
				ini3Overhead *= ini3.highMargin
				ini3.quantity := ini3.itemLimit
				ini3Limit2 := 1
			}
			
			if(ini2Limit2 && !ini3Limit2)
			{
				ini3.quantity := ini3.quantity + (ini2Overhead // ini3.highMargin)
				if(ini3.quantity > ini3.itemLimit)
					ini3.quantity := ini3.itemLimit
			}
			else if(ini3Limit2 && !ini2Limit2)
			{
				ini2.quantity := ini2.quantity + (ini3Overhead // ini2.highMargin)
				if(ini2.quantity > ini2.itemLimit)
					ini2.quantity := ini2.itemLimit
			}
			
		}
		else if(ini2Limit)
		{
			ini2Overhead //= 2
			ini1.quantity := (average + ini2Overhead) // ini1.highMargin
			ini3.quantity := (average + ini2Overhead) // ini3.highMargin
			
			if(ini1.quantity > ini1.itemLimit)
			{
				ini1Overhead := ini1.quantity - ini1.itemLimit
				ini1Overhead *= ini1.highMargin
				ini1.quantity := ini1.itemLimit
				ini1Limit2 := 1
			}
			
			if(ini3.quantity > ini3.itemLimit)
			{
				ini3Overhead := ini3.quantity - ini3.itemLimit
				ini3Overhead *= ini3.highMargin
				ini3.quantity := ini3.itemLimit
				ini3Limit2 := 1
			}
			
			if(ini1Limit2 && !ini3Limit2)
			{
				ini3.quantity := ini3.quantity + (ini1Overhead // ini3.highMargin)
				if(ini3.quantity > ini3.itemLimit)
					ini3.quantity := ini3.itemLimit
			}
			else if(ini3Limit2 && !ini1Limit2)
			{
				ini1.quantity := ini1.quantity + (ini3Overhead // ini1.highMargin)
				if(ini1.quantity > ini1.itemLimit)
					ini1.quantity := ini1.itemLimit
			}
		}
		else if(ini3Limit)
		{
			ini3Overhead //= 2
			ini1.quantity := (average + ini3Overhead) // ini1.highMargin
			ini2.quantity := (average + ini3Overhead) // ini2.highMargin
			
			if(ini1.quantity > ini1.itemLimit)
			{
				ini1Overhead := ini1.quantity - ini1.itemLimit
				ini1Overhead *= ini1.highMargin
				ini1.quantity := ini1.itemLimit
				ini1Limit2 := 1
			}
			
			if(ini2.quantity > ini2.itemLimit)
			{
				ini2Overhead := ini2.quantity - ini2.itemLimit
				ini2Overhead *= ini2.highMargin
				ini2.quantity := ini2.itemLimit
				ini2Limit2 := 1
			}
			
			if(ini1Limit2 && !ini2Limit2)
			{
				ini2.quantity := ini2.quantity + (ini1Overhead // ini2.highMargin)
				if(ini2.quantity > ini2.itemLimit)
					ini2.quantity := ini2.itemLimit
			}
			else if(ini2Limit2 && !ini1Limit2)
			{
				ini1.quantity := ini1.quantity + (ini2Overhead // ini1.highMargin)
				if(ini1.quantity > ini1.itemLimit)
					ini1.quantity := ini1.itemLimit
			}
		}
		else ;no items have reached limit
		{
			ini1.quantity := ini1Permquantity
			ini2.quantity := ini2Permquantity
			ini3.quantity := ini3Permquantity
		}
		
		iniwrite, % ini1.quantity, files\RSandroid.ini, %sec1%, quantity
		iniwrite, % ini2.quantity, files\RSandroid.ini, %sec2%, quantity
		iniwrite, % ini3.quantity, files\RSandroid.ini, %sec3%, quantity
		
		GuiControl, , % hOutput, % ini1.item " : " ini1.quantity
		GuiControl, , % hOutput, % ini2.item " : " ini2.quantity
		GuiControl, , % hOutput, % ini3.item " : " ini3.quantity
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	}
}

restart(where, restartCount := 0)
{
	static restartTime = 0
	
	if(restartCount)
	{
		restartTime = 0
		return 0
	}
	
	loop 3
	{
		SoundBeep, 500, 1000
		sleep 1000
	}
	
	SetTimer, checkLoading, off
	++restartTime
	
	newTotalRestarts := ""
	guiControlGet, totalRestarts, , MainText4
	loop % StrLen(totalRestarts)
	{
		a := SubStr(totalRestarts, StrLen(totalRestarts)-a_index+1, 1)
		if a contains 0,1,2,3,4,5,6,7,8,9
		{
			newTotalRestarts := a . newTotalRestarts
		}
		else
			break
	}
	
	++newTotalRestarts
	GuiControl, Move, MainText4, W130
	GuiControl, , MainText4, Total restart times: %newTotalRestarts%
	
	if(restartTime > 3) ;restarted too much
	{
		GuiControl, , % hOutput, unsuccessfull restarts 3 times in a row
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		
		gui, submit, nohide
		if(DontPlaySound)
		{
			msgbox, program failed
			exitapp
		}
		else
		{
			SoundSet, 100 
			loop
			{
				SoundPlay, %fileDirectory%audio1.wav, 1
				sleep 1000
			}
		}
	}
	
	FileAppend, restarted on %mainIndex% account in %where%`n, %fileDirectory%statistics.txt
	GuiControl, , % hOutput, Restarting %restartTime%. time on this acc
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	
	if(restartTime < 3) 
	{
		closeApp()
		a := openApp()
		if(a)
		{
			quitVysor()
			sleep 10000
			return 1
		}
	}
	else
	{
		SetTimer, checkWindow, off
		quitVysor()
		sleep 10000
		return 2
	}
}

quitVysor()
{
	IfWinExist, %vysorTitle%
		fclick.call(homeButtonX, homeButtonY) ;clicks phones home button
	
	setTimer, checkWindow, Off
	WinClose, Vysor
	winclose, %vysorTitle%
}

onExitFunc()
{
	SB_SetText("Quitting")
	setTimer, checkLoading, Off
	setTimer, checkWindow, Off
	
	if(a_exitReason != "Reload")
	{
		IniWrite, 0, %fileDirectory%reload.ini, reload, reloadTime
		IniWrite, 1, %fileDirectory%reload.ini, reload, accPreselect
	}
	
	GuiControlGet, UpdateMarginTime, , UpdateMarginTimeEdit
	IniWrite, %UpdateMarginTime%, %fileDirectory%reload.ini, reload, UpdateMarginTime
	if(!quitWithoutClosingVysor)
	{
		quitVysor()
	}
}

reloadScript(reason)
{
	IniRead, reloadTime, %fileDirectory%reload.ini, reload, reloadTime
	if(reloadTime > 2)
	{
		gui, submit, nohide
		if(DontPlaySound)
		{
			msgbox, program failed
			exitapp
		}
		else
		{
			SoundSet, 100 
			loop
			{
				SoundPlay, %fileDirectory%audio1.wav, 1
				sleep 1000
			}
		}
	}
	
	FileAppend,(RELOADED script on %mainIndex%, reason: %reason%), %fileDirectory%statistics.txt
	IniWrite, %mainIndex%, %fileDirectory%reload.ini, reload, accPreselect
	++reloadTime
	IniWrite, %reloadTime%, %fileDirectory%reload.ini, reload, reloadTime
	setTimer, checkWindow, off
	quitVysor()
	
	reload
	sleep 10000
	gui, submit, nohide
	if(DontPlaySound)
	{
		msgbox, program failed
		exitapp
	}
	else
	{
		SoundSet, 100 
		loop
		{
			SoundPlay, %fileDirectory%audio1.wav, 1
			sleep 1000
		}
	}
}

closeApp()
{
	fclick.call(309, 725) ;clicks on phone's menu button
	sleep 3000
	fclick.call(190, 683) ;clicks to close all apps
	sleep 1000
}

;------------************ENDING END************----------------------

#include <GolemFunctions>

updateTime:
	++timeCounter
	GuiControl, Move, MyTime, W170
	GuiControl, , MyTime, Time working: %timeCounter% minutes
return

checkWindow:
	IfWinNotExist, %vysorTitle%
	{
		SB_SetText("vysor error")
		pause, on, 1
		GuiControl, , % hOutput, sleeping 10 seconds
		sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
		sleep 10000
		reloadScript("vysor error")
	}
	
	IfWinNotActive, %vysorTitle%
		winActivate, %vysorTitle%
return

checkLoading:
	PixelSearch, pX, pY, 146, 208, 257, 323, 0xF9A61F, ,Fast RGB
	if(!errorlevel)
	{
		SB_SetText("Loading...")
		pause, on, 1
		loop
		{
			sleep 1000
			PixelSearch, pX, pY, 146, 208, 257, 323, 0xF9A61F, ,Fast RGB
			
			if(a_index > 30)
			{
				if(a_index > 40)
				{
					GuiControl, , % hOutput, loading too long
					sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
					reloadScript(2)
				}
				
				fclick.call(vysorBackX, vysorBackY)
				
				sleep 2000
			}
			
		} until (errorlevel)
		
		sleep 1000
		pause, off
		SB_SetText("Running")
	}
return

CheckNoRandom:
	Gui, Submit, NoHide
	iniWrite, %noRandom%, %filedirectory%reload.ini, reload, noRandom
return

CheckSound:
	Gui, Submit, NoHide
	iniWrite, %dontPlaySound%, %filedirectory%reload.ini, reload, DontPlaySound
return

CheckNoMouse:
	Gui, Submit, NoHide
	iniWrite, %MyRadioYes%, %filedirectory%reload.ini, reload, noMouse
return


^g::exitapp
^h::
	pause, , 1
	
	if(A_IsPaused)
	{
		SB_SetText("Paused")
	}
	else
	{
		SB_SetText("Running")
	}
return

^f::
	quitWithoutClosingVysor := true
exitapp

^r::reload

^e::
	GuiControl, , % hOutput, will quit after this account
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
	quitAfterCurrentAcc = 1
return

^t::
	continueRunning := 1
return

GuiClose:
ExitApp

LWin::








