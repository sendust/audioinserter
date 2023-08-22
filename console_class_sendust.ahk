; command line interface class, based on stdouttovar sean code and others ; v1.0, by segalion
; Code Modified by sendust 2019/4/8


class consolerun 
{
   pid := -1
   
    __New(sCmd, sDir="",codepage="") {
      DllCall("CreatePipe","Ptr*",hStdInRd,"Ptr*",hStdInWr,"Uint",0,"Uint",0)
      DllCall("CreatePipe","Ptr*",hStdOutRd,"Ptr*",hStdOutWr,"Uint",0,"Uint",0)
      DllCall("SetHandleInformation","Ptr",hStdInRd,"Uint",1,"Uint",1)
      DllCall("SetHandleInformation","Ptr",hStdOutWr,"Uint",1,"Uint",1)
      
      if (A_PtrSize=4) {
         VarSetCapacity(pi, 16, 0)
         VarSetCapacity(si,68,0)
         NumPut(68, si,  0)
         NumPut(0x100, si, 44)
         NumPut(hStdInRd , si, 56)
         NumPut(hStdOutWr, si, 60)
         NumPut(hStdOutWr, si, 64)
         }
      else if (A_PtrSize=8) {
         VarSetCapacity(pi, 24, 0)    ; PROCESS_INFORMATION  ;  http://goo.gl/b9BaI
         VarSetCapacity(si,104,0)           ; startupinfo      ;  http://goo.gl/fZf24
         NumPut(68, si,  0)         ; cbSize
         NumPut(0x100, si, 60)        ; dwFlags    =>  STARTF_USESTDHANDLES = 0x100
         NumPut(hStdInRd , si, 80)
         NumPut(hStdOutWr, si, 88)     ; hStdOutput
         NumPut(hStdOutWr, si, 96)    ; hStdError
         }
      result :=DllCall("CreateProcess", "Uint", 0, "Ptr", &sCmd, "Uint", 0, "Uint", 0, "Int", True, "Uint", 0x08000000, "Uint", 0, "Ptr", sDir ? &sDir : 0, "Ptr", &si, "Ptr", &pi)
      this.pid := NumGet( pi, A_PtrSize*2, "UInt" )         ; read 4 byte
      DllCall("CloseHandle","Ptr",NumGet(pi, 0, "Uint64"))
      DllCall("CloseHandle","Ptr",NumGet(pi, A_PtrSize, "Uint64"))
      DllCall("CloseHandle","Ptr",hStdOutWr)
      DllCall("CloseHandle","Ptr",hStdInRd)
         ; Create an object.
		this.hStdInWr:= hStdInWr, this.hStdOutRd:= hStdOutRd
		this.codepage:=(codepage="")?A_FileEncoding:codepage
	}
    __Delete() {
        this.close()
    }
    close() {
       hStdInWr:=this.hStdInWr
       hStdOutRd:=this.hStdOutRd
       DllCall("CloseHandle","Ptr",hStdInWr)
       DllCall("CloseHandle","Ptr",hStdOutRd)
      }
   write(sInput="")  {
		If   sInput <>
			FileOpen(this.hStdInWr, "h", this.codepage).Write(sInput)
      }
      
	readline() {
       fout:=FileOpen(this.hStdOutRd, "h", this.codepage)
	   this.AtEOF:=fout.AtEOF
       if (IsObject(fout) and fout.AtEOF=0)
         return fout.ReadLine()
      return ""
      }
      
      
   	read(chars="") {
       fout:=FileOpen(this.hStdOutRd, "h", this.codepage)
       this.AtEOF:=fout.AtEOF
	   if (IsObject(fout) and fout.AtEOF=0)
         return chars=""?fout.Read():fout.Read(chars)
      return ""
      }


   /*
	read(chars="")          ; Modified by sendust 209/4/8
    {
       fout:=FileOpen(this.hStdOutRd, "h", this.codepage)
      VarSetCapacity( Buffer, 4096, 0 ), nSz := 0 
      ;While 
      DllCall( "ReadFile", UInt,this.hStdOutRd, UInt,&Buffer, UInt,4094, UIntP,nSz, Int,0 ) 
      NumPut( 0, Buffer, nSz, "Char" )
      VarSetCapacity( Buffer,-1 )
      tOutput := StrGet( &Buffer, nSz, "CP850" )
      ToolTip % tOutput
      FileAppend, % tOutput, mpvoutput.txt
   }
   */


}



/* example  ------------  from https://autohotkey.com/board/topic/82732-class-command-line-interface/
netsh:= new cli("netsh.exe","","CP850")
msgbox % "hStdInWr=" netsh.hStdInWr "`thStdOutRd=" netsh.hStdOutRd
sleep 300
netsh.write("firewall`r`n")
sleep 100
netsh.write("show config`r`n")
sleep 1000
out:=netsh.read()
msgbox,, FIREWALL CONFIGURATION:, %out%
netsh.write("bye`r`n")
netsh.close()
*/



 ;Tip for struct calculation
  ; Any member should be aligned to multiples of its size
  ; Full size of structure should be multiples of the largest member size
  ;============================================================================
  ;
  ; x64
  ; STARTUPINFO
  ;                             offset    size                    comment
  ;DWORD  cb;                   0         4
  ;LPTSTR lpReserved;           8         8(A_PtrSize)            aligned to 8-byte boundary (4 + 4)
  ;LPTSTR lpDesktop;            16        8(A_PtrSize)
  ;LPTSTR lpTitle;              24        8(A_PtrSize)
  ;DWORD  dwX;                  32        4
  ;DWORD  dwY;                  36        4
  ;DWORD  dwXSize;              40        4
  ;DWORD  dwYSize;              44        4
  ;DWORD  dwXCountChars;        48        4
  ;DWORD  dwYCountChars;        52        4
  ;DWORD  dwFillAttribute;      56        4
  ;DWORD  dwFlags;              60        4
  ;WORD   wShowWindow;          64        2
  ;WORD   cbReserved2;          66        2
  ;LPBYTE lpReserved2;          72        8(A_PtrSize)           aligned to 8-byte boundary (2 + 4)
  ;HANDLE hStdInput;            80        8(A_PtrSize) 
  ;HANDLE hStdOutput;           88        8(A_PtrSize) 
  ;HANDLE hStdError;            96        8(A_PtrSize) 
  ;
  ;ALL : 96+8=104=8*13
  ;
  ; PROCESS_INFORMATION
  ;
  ;HANDLE hProcess              0         8(A_PtrSize)
  ;HANDLE hThread               8         8(A_PtrSize)
  ;DWORD  dwProcessId           16        4
  ;DWORD  dwThreadId            20        4
  ;
  ;ALL : 20+4=24=8*3
  ;============================================================================
  ; x86
  ; STARTUPINFO
  ;                             offset     size
  ;DWORD  cb;                   0          4
  ;LPTSTR lpReserved;           4          4(A_PtrSize)            
  ;LPTSTR lpDesktop;            8          4(A_PtrSize)
  ;LPTSTR lpTitle;              12         4(A_PtrSize)
  ;DWORD  dwX;                  16         4
  ;DWORD  dwY;                  20         4
  ;DWORD  dwXSize;              24         4
  ;DWORD  dwYSize;              28         4
  ;DWORD  dwXCountChars;        32         4
  ;DWORD  dwYCountChars;        36         4
  ;DWORD  dwFillAttribute;      40         4
  ;DWORD  dwFlags;              44         4
  ;WORD   wShowWindow;          48         2
  ;WORD   cbReserved2;          50         2
  ;LPBYTE lpReserved2;          52         4(A_PtrSize)           
  ;HANDLE hStdInput;            56         4(A_PtrSize) 
  ;HANDLE hStdOutput;           60         4(A_PtrSize) 
  ;HANDLE hStdError;            64         4(A_PtrSize) 
  ;
  ;ALL : 64+4=68=4*17
  ;
  ; PROCESS_INFORMATION
  ;
  ;HANDLE hProcess              0         4(A_PtrSize)
  ;HANDLE hThread               4         4(A_PtrSize)
  ;DWORD  dwProcessId           8         4
  ;DWORD  dwThreadId            12        4
  ;
  ;ALL : 12+4=16=4*4
  
  
  