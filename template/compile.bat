@echo off
setlocal
goto _start_


:_start_    
::Pfade zu Programm-Dateien
set p=assembler

::Prfen, ob Pfad existiert 
if not exist %p% goto help  

::Hauptdatei suchen
for /r %p% %%f in (*.has) do (
  for /f "tokens=1" %%a in ('C:\Windows\System32\find.exe "__init" "%%f"') do (    
    if .%%a==.@code (
      set file=%%f
	  echo.
      call :hoasm
    )    
  )  
)
goto fin

::Aufruf von Assembler und Linker
:hoasm
  echo "%file%"
  ..\_bin\hoasm -I ..\_assembler\inc "%file%"
  ..\_bin\hlink -L ..\_assembler\inc -o "%file:.has=.hix%" "%file:.has=.ho%"

  
:fin
endlocal
