REM this is the absolute simplest way to automatically download and install ANT on a Windows machine.
REM this script uses hard paths and file names, update as needed.

@echo off
setlocal
cd /d %~dp0
set antpath

mkdir C:\ops\temp
mkdir C:\ops\bin
bitsadmin.exe /transfer "ANT" /download /priority normal https://www.apache.org/dist/ant/binaries/apache-ant-1.9.7-bin.zip C:\ops\temp\apache-ant-1.9.7-bin.zip

Call :UnZipFile "C:\ops\bin\" "C:\ops\temp\apache-ant-1.9.7-bin.zip"
Call :EnvSet
exit /b

:UnZipFile <ExtractTo> <newzipfile>
set vbs="%temp%\_.vbs"
if exist %vbs% del /f /q %vbs%
>%vbs%  echo Set fso = CreateObject("Scripting.FileSystemObject")
>>%vbs% echo If NOT fso.FolderExists(%1) Then
>>%vbs% echo fso.CreateFolder(%1)
>>%vbs% echo End If
>>%vbs% echo set objShell = CreateObject("Shell.Application")
>>%vbs% echo set FilesInZip=objShell.NameSpace(%2).items
>>%vbs% echo objShell.NameSpace(%1).CopyHere(FilesInZip)
>>%vbs% echo Set fso = Nothing
>>%vbs% echo Set objShell = Nothing
cscript //nologo %vbs%
if exist %vbs% del /f /q %vbs%

:EnvSet
if defined ANT_HOME (
  echo "Doing nothing because another ANT installation is already on this system."
  ) else (
  setx ANT_HOME "C:\ops\bin\apache-ant-1.9.7" /m
  setx PATH "%PATH%;C:\ops\bin\apache-ant-1.9.7\bin" /m
  )

