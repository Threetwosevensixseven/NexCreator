:: Set current directory
::@echo off
C:
CD %~dp0

..\vs\Debug\NexCreator.exe ..\nex\NexTest5.txt ..\sd\NexTest.nex

::pause