echo off
IF EXIST warden.exe  del warden.exe 
IF EXIST warden.obj  del warden.obj 
yasm -f win32 warden.asm

IF EXIST warden.obj  link.exe /subsystem:console /defaultlib:user32.lib /defaultlib:kernel32.lib /entry:main warden.obj

IF EXIST warden.exe cls
IF EXIST warden.exe warden.exe
pause