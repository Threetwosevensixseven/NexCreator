:: Set current directory
::@echo off
C:
CD %~dp0

..\vs\Debug\NexCreator.exe ..\nex\5Only.txt ..\sd\5Only.nex

::pause