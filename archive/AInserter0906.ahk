#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#include console_class_sendust.ahk
#include mediainfo.ahk
#NoTrayIcon
#SingleInstance, Ignore

/*  commandline example
ffmpeg -i 0212.mxf -i "Z:\temp\생투 빵 음악.mp3" -filter_complex "[1:a]aresample=48000[ar];[ar]channelsplit=channel_layout=stereo[left][right]" -map 0:v -c:v copy -map 0:a:0 -map 0:a:1 -map [left] -map [right] -map 0:a:4 -map 0:a:5 -map 0:a:5 -map 0:a:7 -c:a pcm_s24le -ac 1 test.mxf

Stream mapping:
  Stream #1:0 (mp3) -> aresample (graph 0)
  Stream #0:0 -> #0:0 (copy)
  Stream #0:1 -> #0:1 (pcm_s24le (native) -> pcm_s24le (native))
  Stream #0:2 -> #0:2 (pcm_s24le (native) -> pcm_s24le (native))
  channelsplit:FL (graph 0) -> Stream #0:3 (pcm_s24le)
  channelsplit:FR (graph 0) -> Stream #0:4 (pcm_s24le)
  Stream #0:5 -> #0:5 (pcm_s24le (native) -> pcm_s24le (native))
  Stream #0:6 -> #0:6 (pcm_s24le (native) -> pcm_s24le (native))
  Stream #0:6 -> #0:7 (pcm_s24le (native) -> pcm_s24le (native))
  Stream #0:8 -> #0:8 (pcm_s24le (native) -> pcm_s24le (native))
  
*/


title = SBS Audio Inserter by sendust 2019/9/6
ffmpeg := Object()
  ffmpeg.linewidth_initial := 120       ; initial value for console read
  
ffmpeg.path_dst := read_regi("HKEY_CURRENT_USER\SOFTWARE\sendust\ainserter", "outfolder",  A_MyDocuments)

media1 := Object()
media2 := Object()

mi := new mediainfo()

mpv := Object()
	mpv.binary := A_WorkingDir . "\bin\mpv.com"
	mpv.pid := -1
    mpv.script := ""

mpv_filter := Object()
audio_monitor := Object()

param_map := Object()
param_map_alt := Object()

button_control := Object()

ffmpeg.pid := -1
ffmpeg.binary := A_WorkingDir . "\bin\ffmpeg2018.exe"


Gui, margin, 15, 15
Gui, add, edit, w500 h50 hwndhmedia1 Center -VScroll ReadOnly, VIDEO (MXF,MOV)
Gui, add, Button, w120 h50 xp+550 yp gplay_media1, 재생(비디오)
Gui, add, edit, w500 h50 xm  hwndhmedia2 Center -VScroll  ReadOnly, AUDIO (WAV,MP3,MP2,FLAC,OGG)
Gui, add, Button, w120 h50 xp+550 yp gplay_media2, 재생(오디오)
Gui, add, text, xm, Audio Monitor Select
Gui, add, DDL, xp+150 yp-5 hwndhaudiomonl vaudiomonl choose9 gaudiomonsel, CH1|CH2|CH3|CH4|CH5|CH6|CH7|CH8|CH1+CH3
Gui, add, DDL, xp+200 yp hwndhaudiomonr vaudiomonr choose9 gaudiomonsel, CH1|CH2|CH3|CH4|CH5|CH6|CH7|CH8|CH2+CH4
Gui, add, edit, xm w500 h400 hwndheditbox VScroll -HScroll readonly, Application Started
Gui, add, Button, xp+550 yp+20 w120 h80 hwndhjob1 gstart_job1 , 더빙시작`r`n(CH2)
Gui, add, Button, xp yp+100 w120 h80 hwndhjob2 gstart_job2, 믹싱시작`r`n(CH3,CH4)
Gui, add, button, xp yp+120 w120 h50 gstop_ffmpeg, 취소
Gui, add, button, xp yp+70 w120 h50 gsel_target, 폴더선택
Gui, add, button, xp yp+70 w120 h50 ghelpbutton, 도움말
Gui, add, Progress, xm w500 hwndhprogress, 100
;Gui, add, Text, xp+550 w120 h30, 남은시간
Gui, add, StatusBar, hwndhstatus, Status Bar
Gui, show,, %title%

Gui, font, s9
GuiControl, font, %heditbox%

Gui, font, s12 bold
GuiControl, font, %hmedia1%
GuiControl, font, %hmedia2%

Gui, font, s14 bold
GuiControl, font, %hjob1%
GuiControl, font, %hjob2%


button_control := [hjob1, hjob2]

if !FileExist(ffmpeg.binary)
{
  MsgBox,, 주의, 인코더 실행 파일이 존재하지 않습니다. 종료합니다
  ExitApp
}

if !FileExist(mpv.binary)
{
  MsgBox,, 주의, 뷰어 실행 파일이 존재하지 않습니다. 종료합니다
  ExitApp
}

if !FileExist("mediainfo.dll")
{
  MsgBox,, 주의, mediainfo.dll 파일이 존재하지 않습니다. 종료합니다
  ExitApp
}


mpv_filter["noaudio"] := ""
mpv_filter["mono-1"] := "--lavfi-complex=[aid1]asplit[as1][as2];[as2]showvolume=r=29.97[vvolume];[vid1]format=pix_fmts=yuv420p[vf];[vf][vvolume]overlay=x=20:y=20[vo]"
mpv_filter["mono-2"] := "--lavfi-complex=[aid1][aid2]amerge=inputs=2[a1];[a1]asplit[as1][as2];[as2]showvolume=r=29.97[vvolume];[vid1]format=pix_fmts=yuv420p[vf];[vf][vvolume]overlay=x=20:y=20[vo]"
mpv_filter["mono-4"] := "--lavfi-complex=[aid1][aid2][aid3][aid4]amerge=inputs=4[a1];[a1]asplit[as1][as2];[as2]showvolume=r=29.97[vvolume];[vid1]format=pix_fmts=yuv420p[vf];[vf][vvolume]overlay=x=20:y=20[vo]"
mpv_filter["mono-8"] := "--lavfi-complex=[aid1][aid2][aid3][aid4][aid5][aid6][aid7][aid8]amerge=inputs=8[a1];[a1]asplit[as1][as2];[as2]showvolume=r=29.97[vvolume];[vid1]format=pix_fmts=yuv420p[vf];[vf][vvolume]overlay=x=20:y=20[vo]"
mpv_filter["stereo-1"] := "--lavfi-complex=[aid1]asplit[as1][as2];[as2]showvolume=r=29.97[vvolume];[vid1]format=pix_fmts=yuv420p[vf];[vf][vvolume]overlay=x=20:y=20[vo]"
mpv_filter["stereo-2"] := "--lavfi-complex=[aid1][aid2]amerge=inputs=2[a1];[a1]asplit[as1][as2];[as2]showvolume=r=29.97[vvolume];[vid1]format=pix_fmts=yuv420p[vf];[vf][vvolume]overlay=x=20:y=20[vo]"
mpv_filter["stereo-3"] := "--lavfi-complex=[aid1][aid2][aid3]amerge=inputs=3[a1];[a1]asplit[as1][as2];[as2]showvolume=r=29.97[vvolume];[vid1]format=pix_fmts=yuv420p[vf];[vf][vvolume]overlay=x=20:y=20[vo]"

audio_monitor["CH1"] := "c0"
audio_monitor["CH2"] := "c1"
audio_monitor["CH3"] := "c2"
audio_monitor["CH4"] := "c3"
audio_monitor["CH5"] := "c4"
audio_monitor["CH6"] := "c5"
audio_monitor["CH7"] := "c6"
audio_monitor["CH8"] := "c7"
audio_monitor["CH1+CH3"] := "c0+c2"
audio_monitor["CH2+CH4"] := "c1+c3"



mpv_filter["stereo-4"] := mpv_filter["mono-4"]
mpv_filter["5.1-1"] := mpv_filter["stereo-1"]
mpv_filter["7.1-1"] := mpv_filter["stereo-1"]
mpv_filter["8-1"] := mpv_filter["stereo-1"]
mpv_filter["16-1"] := mpv_filter["stereo-1"]

mpv_filter["2 channels-1"] := mpv_filter["stereo-1"]
mpv_filter["2 channels-2"] := mpv_filter["stereo-2"]
mpv_filter["2 channels-3"] := mpv_filter["stereo-3"]
mpv_filter["2 channels-4"] := mpv_filter["stereo-4"]

mpv_filter["4 channels-1"] := mpv_filter["stereo-1"]
mpv_filter["5 channels-1"] := mpv_filter["stereo-1"]
mpv_filter["6 channels-1"] := mpv_filter["stereo-1"]
mpv_filter["7 channels-1"] := mpv_filter["stereo-1"]
mpv_filter["8 channels-1"] := mpv_filter["stereo-1"]
mpv_filter["16 channels-1"] := mpv_filter["stereo-1"]
mpv_filter["32 channels-1"] := mpv_filter["stereo-1"]


/*
param_map["mono-2"] := " -filter_complex ""[1:a]aresample=48000[ar];[ar]apad[ap];[ap]channelsplit=channel_layout=stereo[left][right]"" -map 0:v -c:v copy -map 0:a:0 -map 0:a:1 -map [left] -map [right]  -c:a pcm_s24le -ac 1 "
param_map["mono-4"] := param_map["mono-2"]
param_map["mono-8"] := " -filter_complex ""[1:a]aresample=48000[ar];[ar]apad[ap];[ap]channelsplit=channel_layout=stereo[left][right]"" -map 0:v -c:v copy -map 0:a:0 -map 0:a:1 -map [left] -map [right] -map 0:a:4 -map 0:a:5 -map 0:a:5 -map 0:a:7 -c:a pcm_s24le -ac 1 "

param_map["2 channels-1"] := " -filter_complex ""[1:a]aresample=48000[ar]"" -map 0:v -c:v copy -map 0:a:0 -map [ar]  -c:a pcm_s24le -ac 2 "
param_map["2 channels-2"] := param_map["2 channels-1"]
param_map["2 channels-4"] := " -filter_complex ""[1:a]aresample=48000[ar]"" -map 0:v -c:v copy -map 0:a:0 -map [ar] -map 0:a:2 -map 0:a:3  -c:a pcm_s24le -ac 2 "
*/


; --- new ver. 2019/9/4     --------------------------------------------------------------------------
param_map["noaudio"] := " -filter_complex ""[1:a]aresample=48000[ar];[ar]apad[ap];[ap]channelsplit=channel_layout=stereo[left][right]""  -map 0:v -c:v copy  -map [left] -map [right]  -c:a pcm_s24le -ac 1 "
param_map["mono-2"] := " -filter_complex ""[0:a:0][0:a:1]amerge=inputs=2[am];[am]aresample=48000[are];[are]channelsplit=channel_layout=stereo[a1][a2];[1:a]aresample=48000[ar];[ar]apad[ap];[ap]channelsplit=channel_layout=stereo[left][right]"" -map 0:v -c:v copy -map [a1] -map [a2] -map [left] -map [right]  -c:a pcm_s24le -ac 1 "
param_map["mono-4"] := " -filter_complex ""[0:a:0][0:a:1][0:a:2][0:a:3]amerge=inputs=4[am];[am]aresample=48000[are];[are]channelsplit=channel_layout=4.0[a1][a2][a3][a4];[a3]anullsink;[a4]anullsink;[1:a]aresample=48000[ar];[ar]apad[ap];[ap]channelsplit=channel_layout=stereo[left][right]"" -map 0:v -c:v copy -map [a1] -map [a2] -map [left] -map [right] -c:a pcm_s24le -ac 1 "
param_map["mono-8"] := " -filter_complex ""[0:a:0][0:a:1][0:a:2][0:a:3][0:a:4][0:a:5][0:a:6][0:a:7]amerge=inputs=8[am];[am]aresample=48000[are];[are]channelsplit=channel_layout=7.1[a1][a2][a3][a4][a5][a6][a7][a8];[a3]anullsink;[a4]anullsink;[1:a]aresample=48000[ar];[ar]apad[ap];[ap]channelsplit=channel_layout=stereo[left][right]"" -map 0:v -c:v copy -map [a1] -map [a2] -map [left] -map [right] -map [a5] -map [a6] -map [a7] -map [a8] -c:a pcm_s24le -ac 1 "

param_map["2 channels-1"] := " -filter_complex ""[0:a:0]aresample=48000[are];[1:a]aresample=48000[ar];[ar]apad[ap]"" -map 0:v -c:v copy -map [are] -map [ap]  -c:a pcm_s24le -ac 2 "
param_map["2 channels-2"] := " -filter_complex ""[0:a:0]aresample=48000[are];[0:a:1]anullsink;[1:a]aresample=48000[ar];[ar]apad[ap]"" -map 0:v -c:v copy -map [are] -map [ap]  -c:a pcm_s24le -ac 2 "
param_map["2 channels-4"] := " -filter_complex ""[0:a:0]aresample=48000[are1];[0:a:2]aresample=48000[are3];[0:a:3]aresample=48000[are4];[1:a]aresample=48000[ar];[ar]apad[ap]"" -map 0:v -c:v copy -map [are1] -map [ap] -map [are3] -map [are4]  -c:a pcm_s24le -ac 2 "

param_map["8 channels-1"] := " -filter_complex ""[0:a]aresample=48000[are];[are]channelsplit=channel_layout=7.1[a1][a2][a3][a4][a5][a6][a7][a8];[a3]anullsink;[a4]anullsink;[1:a]aresample=48000[ar];[ar]apad[ap];[ap]channelsplit=channel_layout=stereo[left][right]"" -map 0:v -c:v copy -map [a1] -map [a2] -map [left] -map [right] -map [a5] -map [a6] -map [a7] -map [a8] -c:a pcm_s24le -ac 1 "


param_map_alt["noaudio"] := " -filter_complex ""[1:a]aresample=48000[ar];[ar]apad[ap];[ap]channelsplit=channel_layout=stereo[left][right]""  -map 0:v -c:v copy  -map [left] -map [right]  -c:a pcm_s24le -ac 1 "
param_map_alt["mono-2"] := " -filter_complex ""[0:a:0][0:a:1]amerge=inputs=2[am];[am]aresample=48000[are];[are]channelsplit=channel_layout=stereo[a1][a2];[a2]anullsink;[1:a]aresample=48000[ar];[ar]apad[ap]"" -map 0:v -c:v copy -map [a1] -map [ap]  -c:a pcm_s24le -ac 1 "
param_map_alt["mono-4"] := " -filter_complex ""[0:a:0][0:a:1][0:a:2][0:a:3]amerge=inputs=4[am];[am]aresample=48000[are];[are]channelsplit=channel_layout=4.0[a1][a2][a3][a4];[a2]anullsink;[1:a]aresample=48000[ar];[ar]apad[ap]"" -map 0:v -c:v copy -map [a1] -map [ap] -map [a3] -map [a4] -c:a pcm_s24le -ac 1 "
param_map_alt["mono-8"] := " -filter_complex ""[0:a:0][0:a:1][0:a:2][0:a:3][0:a:4][0:a:5][0:a:6][0:a:7]amerge=inputs=8[am];[am]aresample=48000[are];[are]channelsplit=channel_layout=7.1[a1][a2][a3][a4][a5][a6][a7][a8];[a2]anullsink;[1:a]aresample=48000[ar];[ar]apad[ap]"" -map 0:v -c:v copy -map [a1] -map [ap] -map [a3] -map [a4] -map [a5] -map [a6] -map [a7] -map [a8] -c:a pcm_s24le -ac 1 "

param_map_alt["2 channels-1"] := " -filter_complex ""[0:a:0]pan=1c|c0=c0[amov];[1:a]pan=1c|c0=c0[adub];[adub]apad[pad];[amov][pad]amerge=inputs=2[ao]"" -map 0:v -c:v copy -map [ao]  -c:a pcm_s24le -ac 2 "
param_map_alt["2 channels-2"] := " -filter_complex ""[0:a:0]pan=1c|c0=c0[amov];[1:a]pan=1c|c0=c0[adub];[adub]apad[pad];[amov][pad]amerge=inputs=2[ao];[0:a:1]aresample=48000[ao2]"" -map 0:v -c:v copy -map [ao]  -map [ao2] -c:a pcm_s24le -ac 2 "
param_map_alt["2 channels-4"] := " -filter_complex ""[0:a:0]pan=1c|c0=c0[amov];[1:a]pan=1c|c0=c0[adub];[adub]apad[pad];[amov][pad]amerge=inputs=2[ao];[0:a:1]aresample=48000[ao2];[0:a:2]aresample=48000[ao3];[0:a:3]aresample=48000[ao4]"" -map 0:v -c:v copy -map [ao]  -map [ao2]  -map [ao3]  -map [ao4]  -c:a pcm_s24le -ac 2 "

param_map_alt["8 channels-1"] := " -filter_complex ""[0:a]aresample=48000[are];[are]channelsplit=channel_layout=7.1[a1][a2][a3][a4][a5][a6][a7][a8];[a2]anullsink;[1:a]aresample=48000[are2];[are2]apad[ap];[a1][ap][a3][a4][a5][a6][a7][a8]amerge=inputs=8[ao]"" -map 0:v -c:v copy   -map [a1] -map [ap] -map [a3] -map [a4] -map [a5] -map [a6] -map [a7] -map [a8] -c:a pcm_s24le -ac 1 "


gosub, audiomonsel		; get audio monitor selection

consoleout("`r`nOutput folder is " . ffmpeg.path_dst)
return



read_regi(regpath, valuename, default_var)
{
	RegRead, outputvar, %regpath%, %valuename%
	if ErrorLevel
		outputvar := default_var
	return outputvar
}



audiomonsel:
GuiControlGet, audiomonl
GuiControlGet, audiomonr

audio_monitor_filter := ";[as1]pan=stereo|c0=" . audio_monitor[audiomonl] . "|c1=" . audio_monitor[audiomonr] . "[ao]"
;[as1]pan=stereo|c0=c0+c2|c1=c1+c3[ao]

return


helpbutton:
MsgBox,, 도움말 - Product of sendust (문의 010-3136-0264), % showtextfile("help.txt")
return

showtextfile(infile)
{
  FileRead, outputvar, %infile%
  return outputvar
  
}


GuiDropFiles:
consoleout("-------------------------------------`r`nDrag and drop file __________ " . A_GuiEvent . "`r`n")

if InStr("mxf|mov", splitpath_extension(A_GuiEvent))
{
  media1.fullpath := A_GuiEvent
  GuiControl,, %hmedia1%, % splitpath_name(A_GuiEvent)
  consoleout("<<<< Video File detected >>>>")
  analyse_media(media1, mi)
  consoleout("Audio format is " . media1.audio_format)
  consoleout("Duration is " . media1.duration . " [" . secondtotc(media1.duration) . "]")
  GuiControl,, %hmedia1%, % splitpath_name(A_GuiEvent) . " [" . secondtotc(media1.duration) . "]"
  showobjectlist(media1)
}


if InStr("mp3|mp2|wav|wave|flac|ogg", splitpath_extension(A_GuiEvent))
{
  media2.fullpath := A_GuiEvent
  GuiControl,, %hmedia2%, % splitpath_name(A_GuiEvent)
  consoleout("<<<< Audio File detected >>>>")
  analyse_media(media2, mi)
  consoleout("Audio format is " . media2.audio_format)
  consoleout("Duration is " . media2.duration . " [" . secondtotc(media2.duration) . "]")
  GuiControl,, %hmedia2%, % splitpath_name(A_GuiEvent) . " [" . secondtotc(media2.duration) . "]"
  showobjectlist(media2)
}

return


play_media1:

runpreview(media1, mpv)
SetTimer, mpvchk_once, -100

return


play_media2:

runpreview_audio(media2, mpv)
SetTimer, mpvchk_once, -100

return



mpvchk_once:
Process, Exist, % mpv.pid
If !ErrorLevel			; There is no mpv console process, there is problem
{
	GuiControl,, %hstatus%, % "Error Opening Preview window, PID " . mpv.pid
	mpv.pid := -1
}
else
	GuiControl,, %hstatus%, % "Preparing for Preview window, PID " . mpv.pid

mpv.tickcount := A_TickCount
SetTimer, mpvchk_title, -50			; check if mpv run fails
return



mpvchk_title:

Process, Exist, % mpv.pid
If !ErrorLevel			; There is no mpv console process, there is problem
{
	GuiControl,, %hstatus%, % "Error Opening Preview window, PID " . mpv.pid
	mpv.pid := -1
	SetTimer, mpvchk_title, off
	return
}

if WinExist("Preview play...")
{
	WinSet, Style, -0x20000, Preview play...					; remove minimize button
	WinSet, Style, -0x30000, Preview play...					; remove maximize button
	GuiControl,, %hstatus%, % "Preview window Opened "  . (A_TickCount - mpv.tickcount) / 1000 . " sec"
}
else
{
	GuiControl,, %hstatus%, % "Preparing for Preview window  --- " . (A_TickCount - mpv.tickcount) / 1000 . " sec"
	SetTimer, mpvchk_title, -50
}

if (((A_TickCount - mpv.tickcount) / 1000) > 60)					; no more waiting preview window (30 second)
{
	SetTimer, mpvchk_title, off
	GuiControl,, %hstatus%, % "Preparing for Preview window  --- Please wait more time"
}
return


runpreview_audio(media, byref mpv)
{

  mpvpath := mpv.binary
  mediapath := media.fullpath
  title := "Preview play... " . splitpath_name(media.fullpath)
  
  Process, Exist, % mpv.pid
  if ErrorLevel
  {
      WinClose, Preview play...
      Process, Close, % mpv.pid
      ;updatelog("Send term signal to pid " . mpv.pid)
  }
    
    
  lavfilter := "--lavfi-complex=[aid1]asplit=3[as1][as2][ao];[as1]showvolume=r=29.97:w=600[avolume];[as2]avectorscope=s=640x400:zoom=2:r=29.97:rc=2:gc=200:bc=10:rf=1:gf=8:bf=7[vascope];[vascope][avolume]overlay=x=20:y=50[vo]"

  runtext = %mpvpath% %lavfilter%  --keep-open  --osd-level=3 --osd-fractions --alpha=no "%mediapath%" --title "%title%"
  Run, %runtext%,, Minimize, pid
  WinWait, ahk_pid %pid%
  WinSetTitle, ahk_pid %pid%, , MPV Control Console
  FileAppend, `r`n%runtext%, *
  mpv.pid := pid
  consoleout("MPV launched with PID " . mpv.pid)
  
  
}

runpreview(media, byref mpv)                ; run mpv with media information (without console object, 2019/9/2)
{
	global mpv_filter, audio_monitor_filter
	key := media.audio_format
	lavfilter := mpv_filter[key] . audio_monitor_filter
	geometry := ""
	 
	Process, Exist, % mpv.pid
	if ErrorLevel
	{
		WinClose, Preview play...
		Process, Close, % mpv.pid
		;updatelog("Send term signal to pid " . mpv.pid)
	}
	
	geometry := "--geometry=" . mpv.xpos . ":" . mpv.ypos			; restore last windows position
	if !mpv.xpos																					; There is no position info. (first run)
		geometry := ""
	
	mpvpath := mpv.binary
	mediapath := media.fullpath
	start := mpv.start
	
	;IfWinExist, MPV Control Console
	;	WinClose, MPV Control Console

	title := "Preview play... " . splitpath_name(media.fullpath)
	mpv.title := title
	if mpv.script
	{
		script := mpv.script
		script = "%script%"
		script = --script=%script%
	}
	else
		script := ""

	runtext = %mpvpath% %lavfilter%  %geometry%  %script%   --pause --keep-open --force-window=yes --window-scale=0.5 --hr-seek=yes --osd-level=3 --osd-fractions  "%mediapath%" --title "%title%"
	Run, %runtext%,, Minimize, pid
    WinWait, ahk_pid %pid%
    WinSetTitle, ahk_pid %pid%, , MPV Control Console
    FileAppend, `r`n%runtext%, *
	mpv.pid := pid
	consoleout("MPV launched with PID " . mpv.pid)
}



splitpath_name(infile)
{
  SplitPath, infile, outfilename, outdir, outextension, outnamenoext, outdirve
  return outfilename
}

splitpath_extension(infile)
{
  SplitPath, infile, outfilename, outdir, outextension, outnamenoext, outdirve
  return outextension
}


start_job1:

ffmpeg.jobtype := "CH2"
SetTimer, transcoder_start, -1
return

start_job2:

ffmpeg.jobtype := "CH3,CH4"
SetTimer, transcoder_start, -1
return

transcoder_start:

;runstring = ffmpeg2018.exe -re -i rtmp://210.216.76.120/live/sbsonair -hide_banner -f sdl out
;runstring = ffmpeg2016.exe -f lavfi -i testsrc=duration=99999999:size=1280x720:rate=30 -f sdl out
;runstring = ffmpeg2016.exe  -f lavfi -i testsrc=duration=99999999:size=720x576:rate=25 -pix_fmt yuv420p -c:v mpeg2video -an -y testsignal.mp4
runstring = ffmpeg2016.exe  -f lavfi -i testsrc=duration=99999999:size=720x576:rate=25 -pix_fmt yuv420p  -hide_banner -f null -

runstring := get_runstring(ffmpeg, media1, media2)

ffmpeg.linewidth := ffmpeg.linewidth_initial
buttoncontrol("disable", button_control)


EnvSet, FFREPORT, file=encoder.log:level=32
consoleout("`r`nStart Mixing ----------------------------------`r`n")
console_ffmpeg := Object()              ; Must declare here !!!
console_ffmpeg := new consolerun(runstring, A_WorkingDir, "CP850")

ffmpeg.pid := console_ffmpeg.pid
ffmpeg.frame := 0				; reset frame number
GuiControl,, %hprogress%, 0
SetTimer, checkonce, -1000

return


buttoncontrol(action, arry)
{
	if (action = "enable")
		for key, val in arry
			GuiControl, enable, % val
	
	if (action = "disable")
		for key, val in arry
			GuiControl, Disable, % val
}

get_runstring(ffmpeg, media1, media2)
{
  global param_map, param_map_alt, hstatus
  
  SplitPath, % media1.fullpath, outfilename, outdir, outextension, outnamenoext, outdrive
  
  if (ffmpeg.jobtype = "CH2")
{
	map := param_map_alt[media1.audio_format]
	outname_noext = %outnamenoext%_mixing2
}
  
  if (ffmpeg.jobtype = "CH3,CH4")
{
	map := param_map[media1.audio_format]
	outname_noext = %outnamenoext%_mixing34
}

	binary := ffmpeg.binary
	
  in1 := media1.fullpath
  in2 := media2.fullpath
  path_dst := ffmpeg.path_dst
  outfile = %path_dst%\%outname_noext%.%outextension%
  runstring = %binary% -i "%in1%" -i "%in2%" %map% -y  -hide_banner -shortest  "%outfile%"
  consoleout(runstring)
  GuiControl,, %hstatus%, Output file is %outfile%
  return runstring
}


sel_target:
consoleout("Select Target Button pressed")
ffmpeg.path_dst := selectfolder(ffmpeg.path_dst)
RegWrite, REG_EXPAND_SZ, HKEY_CURRENT_USER\SOFTWARE\sendust\ainserter, outfolder, % ffmpeg.path_dst
consoleout("Selected target is " . ffmpeg.path_dst)
return

selectfolder(folder)
{
	folder_old := folder
	FileSelectFolder, OutputVar, *%folder%, 3, Select Target Folder          ; option 3 = create new folder, paste text path is possible  2018/1/15

	if OutputVar =                       ; Select cancel
		return folder_old
	else
	{
		path_dst :=RegExReplace(OutputVar, "\\$")  ; Removes the trailing backslash, if present.
		return path_dst
	}
}


checkonce:
text := console_ffmpeg.read()
consoleout(text)

SetTimer, updateconsole, -200
return

updateconsole:
Critical
text := console_ffmpeg.read(ffmpeg.linewidth)         ; 80~120 is good number for ffmpeg console capture
if (StrLen(text) > 2)
{
  consoleout(text)
  ;Scroll to bottom
  ;SendMessage, 0x0115, 7, 0,, ahk_id %heditbox%           ;WM_VSCROLL
 get_ffmpeg_progress(text, ffmpeg)
}

showobjectlist(ffmpeg)

Process, exist, % ffmpeg.pid
if !errorlevel              ; there is no ffmpeg process (finish encoding or there is error)
{
  consoleout("FFMPEG Process Finished (Encoder check routine)")
  ;FileRead, text_last, %A_WorkingDir%\encoder.log
  ;consoleout(StrReplace(SubStr(text_last, -500), "`r", "`r`n"))            ; show last few lines again
  ffmpeg.pid := -1
  ffmpeg.frame := media1.durationframe
  buttoncontrol("enable", button_control)
  SetTimer, updateconsole, off
}
else
  SetTimer, updateconsole, -200

GuiControl,, %hprogress%, % (ffmpeg.frame / media1.durationframe) * 100
return


stop_ffmpeg:
consoleout("Sending 'q' signal")
console_ffmpeg.write("q")
console_ffmpeg.close()
SetTimer, chk_ffpid, -2000
return



chk_ffpid:
Process, exist, % ffmpeg.pid
if !ErrorLevel
 consoleout("Encoder finished (Last check routine)")
else
 consoleout("Encoder is still live !!!")
 
return



secondtotc(sec)
{
	sec := format("{:10.3f}", sec)
	sec_out := Floor(sec)
	frame_out := format("{:0.3f}", sec - sec_out)
	hour_out := format("{:02d}", sec_out // 3600)
	minute_out := format("{:02d}",  Mod(sec_out // 60, 60))
	second_out := format("{:02d}", Mod(sec_out, 60))

	return % hour_out . ":" . minute_out . ":" . second_out . "." . SubStr(frame_out, -2)
}




analyse_media(ByRef media, o_mi)			; new, 2019/4/3 from mediainfo.dll
{
	global hstatus
	GuiControl,, %hstatus%, Analysing Media...Please wait
	audio_extension := "3gp|aa|aac|aax|ac3|act|aiff|amr|ape|au|awb|dct|dss|dvf|flac|gsm|ivs|m4a|mmf|mp2|mp3|mpc|msv|nsf|ogg|oga|ra|sin|voc|vox|wav|wma"
	
	o_mi.open(media.fullpath)
	
	media.imediatype := o_mi.getgeneral("InternetMediaType")
	media.extension := o_mi.getgeneral("FileExtension")
	;media.duration := o_mi.getvideo("Duration") / 1000	
	media.duration := o_mi.getgeneral("Duration") / 1000			; Modified 2019/7/11 for audio only media
	media.start := o_mi.gettimecode()	
	media.resolution := o_mi.getvideo("Width") . "x" . o_mi.getvideo("Height")
	media.resolution := StrLen(media.resolution) < 3 ? o_mi.getimage("Width") . "x" . o_mi.getimage("Height") : media.resolution
	media.framerate := o_mi.getvideo("FrameRate")
	media.audio_format := o_mi.getaudiocount()
	media.codecv := o_mi.getvideo("Format")
	media.codeca := o_mi.getaudio("Format")
	media.durationframe :=  o_mi.getvideo("FrameCount")	
	media.scantype := o_mi.getvideo("ScanType")	
	if (!media.scantype)
		media.scantype := "Progressive"
	media.titlev := o_mi.getvideo("Title")
	media.titlea := o_mi.getaudio("Title")
	
	if ((SubStr(media.imediatype, 1, 5) = "audio") or (InStr(audio_extension, media.extension)))				; added 2019/7/11 for audio only media
	{
		media.resolution := "audio"
		media.framerate := 9999
		media.codecv := "audio"
	}
	
	media.movie_more := o_mi.getgeneral("Movie_More")			; Transcent Bodycam detection,   added 2019/7/30
	
	GuiControl,, %hstatus%, Finish Analysing Media
	
}






get_ffmpeg_progress(text, ByRef ffmpeg)
{
  foundpos := RegExMatch(text, "frame=[\s\d]+", strInterest)
  if foundpos
  {
    RegExMatch(strInterest, "\d+", temp)
    ffmpeg.frame := temp
  }
  
  foundpos := RegExMatch(text, "fps=[\s\d]+", strInterest)
  if foundpos
  {
    RegExMatch(strInterest, "\d+", temp)
    ffmpeg.fps := temp
  }    
  
foundpos := RegExMatch(text, "time=\d\d:\d\d:\d\d.\d\d", strInterest)
  if foundpos
  {
    RegExMatch(strInterest, "\d\d:\d\d:\d\d.\d\d", temp)
    ffmpeg.time := temp
  }
  
foundpos := RegExMatch(text, "speed=[\s\d.]+", strInterest)
  if foundpos
  {
    RegExMatch(strInterest, "[\d+.]+", temp)
    ffmpeg.speed := temp
  }
  
  foundpos := RegExMatch(text, "\r",, 2 )           ; search 'carriage return' from second character
  if foundpos
  {
   ffmpeg.linewidth := foundpos
      ffmpeg.linewidth := ffmpeg.linewidth < 80 ? ffmpeg.linewidth_initial : ffmpeg.linewidth            ; Prevent too small value
  }
  else
   ffmpeg.linewidth := ffmpeg.linewidth_initial
}


showobjectlist(myobject)
{
	temp := ""
	for key, val in myobject
		temp .= key . " ---->  " . val . "`r`n"
	;ToolTip % temp
	FileAppend, ----------------------------------`r`n%temp%, *
}


consoleout(text)
{
 global heditbox
 Appendtext(heditbox, "`r`n" . text) 
}

AppendText(hEdit, Text)
{
  SendMessage, 0x000E, 0, 0,, ahk_id %hEdit% ;WM_GETTEXTLENGTH
  SendMessage, 0x00B1, ErrorLevel, ErrorLevel,, ahk_id %hEdit% ;EM_SETSEL
  SendMessage, 0x00C2, False, &Text,, ahk_id %hEdit% ;EM_REPLACESEL
}

AppendTextLine(hEdit, Text) 
{
  Text := "`r`n" . Text
  SendMessage, 0x000E, 0, 0,, ahk_id %hEdit% ;WM_GETTEXTLENGTH
  SendMessage, 0x00B1, ErrorLevel, ErrorLevel,, ahk_id %hEdit% ;EM_SETSEL
  SendMessage, 0x00C2, False, &Text,, ahk_id %hEdit% ;EM_REPLACESEL
}


GuiClose:
console_ffmpeg.write("q")
console_ffmpeg.close()
ExitApp
