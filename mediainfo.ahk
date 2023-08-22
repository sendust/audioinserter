; lastedit 2019/4/1     
; 4/1 gettimecode



class MediaInfo
{
    static handle
    
    __new()
   {
      DllCall("LoadLibrary", str, "MediaInfo.dll", ptr)
       this.handle := DllCall("MediaInfo.dll\MediaInfo_New" , uint)
    }
      
   __Delete()
   {
      if this.handle
      DllCall( "MediaInfo.dll\MediaInfo_Close", UInt, this.handle )
   }
   
   info_parameter()
   {
      return DllCall("MediaInfo.dll\MediaInfo_Option", Uint, 0, Str, "Info_Parameters", str, "", str)
   }
   
   open(mediafile)
   {
      result := DllCall( "MediaInfo.dll\MediaInfo_Open", UInt,this.handle, Str, mediafile, UInt )
   }
   
   getgeneral(property)
   {
      return DllCall( "MediaInfo.dll\MediaInfo_Get", UInt, this.handle, int, 0, Int, 0, Str, property, Int, 1, Str )
   }
   
   getvideo(property)
   {
      ; mediainfo_get(handle, stream kind, stream number, interest parameter, information kind, information type)
      return DllCall( "MediaInfo.dll\MediaInfo_Get", UInt, this.handle, int, 1, Int, 0, Str, property, Int, 1, Str )
   }

   getaudio(property)
   {
      return DllCall( "MediaInfo.dll\MediaInfo_Get", UInt, this.handle, int, 2, Int, 0, Str, property, Int, 1, Str )
   }
   
   gettext(property)
   {
      return DllCall( "MediaInfo.dll\MediaInfo_Get", UInt, this.handle, int, 3, Int, 0, Str, property, Int, 1, Str )
   }
   
   getother(property)
   {
      return DllCall( "MediaInfo.dll\MediaInfo_Get", UInt, this.handle, int, 4, Int, 0, Str, property, Int, 1, Str )
   }
   
   getimage(property)
   {
      return DllCall( "MediaInfo.dll\MediaInfo_Get", UInt, this.handle, int, 5, Int, 0, Str, property, Int, 1, Str )
   }
   
   
   gettimecode()
   {
      tc1 := this.getother("TimeCode_FirstFrame")           ; mxf, mov  tc
      tc2 := this.getvideo("TimeCode_FirstFrame")              ; some mp4
      tc3 := this.getvideo("Delay/String3")                         ; mts tc
      tc4 := this.getvideo("Encoded_Date")                  ; get from mp4, encoded date
      tc4 := tc4? SubStr(tc4, -7) . ".000" : ""             ; format of Encoded date    : UTC 2018-12-10 18:34:54
      ;ToolTip, %tc1% - %tc2% - %tc3% - %tc4%
     if tc1
      return tc1
      else
         if tc2
            return tc2
         else
            if tc3
               return tc3
            else
               if tc4
                  return tc4
               else
                  return "00:00:00.000"
      ;return (!tc1 and !tc2 and !tc3 )? "00:00:00.000"
   }    
   

   getaudiocount()
   {
      audiostreamcount := DllCall("MediaInfo.dll\MediaInfo_Get", UInt, this.handle, Int, 2, Int, 0, Str, "StreamCount", Int, 1, Int, 0, Str)
      audiochannel := DllCall("MediaInfo.dll\MediaInfo_Get", UInt, this.handle, Int, 2, Int, 0, Str, "Channel(s)/String", Int, 1, Int, 0, Str)
      audiochannel := (audiochannel = "1 channel")? "mono" : audiochannel  ; convert "1 channel" to "mono"
      result := audiochannel . "-" .  audiostreamcount  
      result := (result = "-") ? "NOAUDIO" : result              ; no audio case
      return result
   }

   getsummary()
   {
      DllCall("MediaInfo.dll\MediaInfo_Option", uint, this.handle, wstr, "Complete", wstr, "")    ;Inform with Complete=false
      return DllCall("MediaInfo.dll\MediaInfo_Inform", UInt, this.handle, str)
   }
   
   getsummaryfull()
   {
      DllCall("MediaInfo.dll\MediaInfo_Option", uint, this.handle, wstr, "Complete", wstr, "1")    ;Inform with Complete=false
      return DllCall("MediaInfo.dll\MediaInfo_Inform", UInt, this.handle, str)
   }
   

}



/*
Stream_General  StreamKind = General. 
Stream_Video  StreamKind = Video. 
Stream_Audio  StreamKind = Audio. 
Stream_Text  StreamKind = Text. 
Stream_Other  StreamKind = Chapters. 
Stream_Image  StreamKind = Image. 
Stream_Menu  StreamKind = Menu. 


Enumerations 

enum   stream_t { 
   Stream_General, Stream_Video, Stream_Audio, Stream_Text, 
   Stream_Other, Stream_Image, Stream_Menu, Stream_Max 
 } 

   
enum   info_t { 
   Info_Name, Info_Text, Info_Measure, Info_Options, 
   Info_Name_Text, Info_Measure_Text, Info_Info, Info_HowTo, 
   Info_Domain, Info_Max 
 } 
 
enum   infooptions_t { 
   InfoOption_ShowInInform, InfoOption_Reserved, InfoOption_ShowInSupported, InfoOption_TypeOfValue, 
   InfoOption_ShowInXml, InfoOption_Max 
 } 
  Option if InfoKind = Info_Options. More...
 
  
enum   fileoptions_t { FileOption_Nothing =0x00, FileOption_NoRecursive =0x01, FileOption_CloseAll =0x02, FileOption_Max =0x04 } 
*/
