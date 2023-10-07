echo off
REM You must alter the commands to include the path to your dasm.exe file.
cls

if not exist assembled md assembled

echo Assembling NTSC...
dasm\dasm.exe "8blit-s03e04-Regions-final.asm" -f3 -v0 -oassembled\8Blit-s03e04-NTSC.rom -MREGIONPARAM=1
if %errorlevel% neq 0 goto error
echo Assembling PAL...
dasm\dasm.exe "8blit-s03e04-Regions-final.asm" -f3 -v0 -oassembled\8Blit-s03e04-PAL.rom -MREGIONPARAM=2
if %errorlevel% neq 0 goto error
echo Assembling PAL_SECAM...
dasm\dasm.exe "8blit-s03e04-Regions-final.asm" -f3 -v0 -oassembled\8Blit-s03e04-PAL-SECAM.rom -MREGIONPARAM=3
if %errorlevel% neq 0 goto error
echo Assembling SECAM...
dasm\dasm.exe "8blit-s03e04-Regions-final.asm" -f3 -v0 -oassembled\8Blit-s03e04-SECAM.rom -MREGIONPARAM=4
if %errorlevel% neq 0 goto error

echo Assembled ROM(s) are located in the "assembled" folder
goto eof

:error
echo Compilation stopped due to an error detected

:eof
pause






