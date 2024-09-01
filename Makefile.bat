echo on
call Make-Settings.bat

cd %BASE_DIR%

rem Clean main directory
if exist *-Test.lab   del /Q *-Test.lab
if exist *-Test.lst   del /Q *-Test.lst
if exist *-Test.xex   del /Q *-Test.xex
if exist *-Test.atdbg del /Q *-Test.atdbg


rem Make main file
call :make REBBSTAR.XEX

set ATR=%RELEASE%.atr
atr\hias\dir2atr.exe -m -b MyDos4534 %ATR% atr\files

rem To compile the loader along, the .xex files must not be deleted.
goto keepXEXfiles
if exist RebbStars-Main.xex        del RebbStars-Main.xex
if exist RebbStars-Main-Packed.xex del RebbStars-Main-Packed.xex
if exist RebbStars.xex             del RebbStars.xex
:keepXEXfiles

if NOT X%1==XSTART goto :EOF
start %ATR%
goto :eof

:make
if exist atr\files\%1 del atr\files\%1
C:\jac\system\Atari800\Tools\ASM\MADS\mads.exe RebbStars-Main.asm -o:RebbStars-Main.xex %2 %3
if ERRORLEVEL 1 goto :mads_error
C:\jac\system\Atari800\Tools\PAK\SuperPacker\exomizer sfx $2000 RebbStars-Main.xex -t 168 -o RebbStars-Main-Packed.xex -X "jsr $1e60"
C:\jac\system\Atari800\Tools\ASM\MADS\mads.exe RebbStars.asm -l -o:RebbStars.xex
copy RebbStars.xex atr\files\%1
if ERRORLEVEL 1 goto :mads_error

goto :eof

:mads_error
echo ERROR: MADS compilation errors occurred. Check error messages above.
pause
exit

