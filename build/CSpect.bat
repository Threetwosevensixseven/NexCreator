:: Set current directory
::@echo off
C:
CD %~dp0

..\tools\pskill.exe -t cspect.exe

"C:\Program Files (x86)\CSpect1_14\CSpect.exe" -s14 -w2 -zxnext -exit -zx128 -brk -mmc=..\sd\ ..\sd\NexTest.nex

:: pause