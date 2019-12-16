:: Set current directory
::@echo off
C:
CD %~dp0

..\build\pskill.exe -t cspect.exe
hdfmonkey.exe put C:\spec\cspect-next-2gb.img nexload dot

cd C:\spec\CSpect2_12_0
::"C:\Program Files (x86)\CSpect1_14\CSpect.exe" -s14 -w2 -zxnext -exit -zx128 -brk -mmc=..\sd\ ..\sd\NexTest.nex
CSpect.exe -w2 -zxnext -nextrom -basickeys -exit -brk -tv -mmc=..\cspect-next-2gb.img

::pause