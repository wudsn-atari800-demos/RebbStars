
call Makefile.bat

call Make-Settings.bat

cd %BASE_DIR%

del /q %BASE_DIR%\*.lab
del /q %BASE_DIR%\*.lst
del /q %BASE_DIR%\*.atdbg

REM Target directory
set TARGET_NAME=%USERPROFILE%\Documents\Eclipse\workspace.jac\com.wudsn.site\site\productions\atari800\%RELEASE_LOWERCASE%
if not exist %TARGET_NAME% mkdir %TARGET_NAME%

REM Target file prefix
set TARGET_NAME=%TARGET_NAME%\%RELEASE_LOWERCASE%

REM Make target files
copy %RELEASE%.gif %TARGET_NAME%.gif
copy %RELEASE%.nfo %TARGET_NAME%.nfo

REM Make target.zip
set TARGET=%TARGET_NAME%.zip

del %TARGET%
C:\jac\system\PC\Tools\DSK\WinRAR\winrar a -afzip %TARGET% %RELEASE%.xex %RELEASE%.atr %RELEASE%.nfo %RELEASE%.gif
start %TARGET%

REM Make target-source.zip
set TARGET=%TARGET_NAME%-source.zip

del %TARGET%
cd ..
C:\jac\system\PC\Tools\DSK\WinRAR\winrar a -afzip -x*.xex -x*.atr %TARGET% %RELEASE%\*.*  %RELEASE%\atr %RELEASE%\gfx %RELEASE%\java %RELEASE%\rip %RELEASE%\snd
cd %RELEASE%
start %TARGET%


