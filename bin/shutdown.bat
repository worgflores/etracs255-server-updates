@echo off
rem Setup the java command 
set JAVA=java
if not "%JAVA_HOME%" == "" set JAVA=%JAVA_HOME%\bin\java

rem This will be the run directory
set RUN_DIR=%cd%

rem Move up...
cd ..

rem This will be the base directory
set BASE_DIR=%cd%

set JAVA_OPT="-Xmx256m -Dosiris.run.dir=%RUN_DIR% -Dosiris.base.dir=%BASE_DIR%"

"%JAVA%" "%JAVA_OPT%" -cp lib/*;. com.rameses.server.Shutdown
pause
