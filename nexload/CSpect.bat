:: Set current directory
::@echo off
C:
CD %~dp0

..\build\pskill.exe -t cspect.exe
hdfmonkey.exe put C:\spec\cspect-next-2gb.img nexload dot

cd C:\spec\CSpect2_13_01
::CSpect.exe -w2 -zxnext -nextrom -basickeys -exit -brk -major=48 -minor=5 -mmc=..\cspect-next-2gb.img
CSpect.exe -w2 -tv -zxnext -nextrom -basickeys -exit -brk -mmc=..\cspect-next-2gb.img

::pause