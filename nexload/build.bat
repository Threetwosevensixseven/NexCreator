....:: Set current directory
::@echo off
C:
CD %~dp0

sjasmplus nexload.asm --sym=nexload.sym || goto err
copy nexload.sna ..\sd\*.*
copy NEXLOAD. q:\dot\*.*
:: ..\build\pskill.exe -t cspect.exe
:: "C:\Program Files (x86)\CSpect1_14\CSpect.exe" -s14 -w3 -zxnext -exit -zx128 -brk -mmc=..\sd\ ..\sd\nexload.sna

pause

:noerr
goto end

:err
@pause Press any key to exit

:end

