@echo off
setlocal
goto _start_

:help
  echo   Compiles and links the bootloader assembler.
  echo.
  echo   ^<group^>    ^:= group's folder
  echo.
goto fin


:_start_
::Aufruf von Assembler und Linker
:hoasm
  ..\_bin\hoasm -I ..\_assembler\inc "..\_assembler\bootloader\boot.has"
  ..\_bin\hlink -L ..\_assembler\inc -o "..\_assembler\bootloader\boot.hix" "..\_assembler\bootloader\boot.ho" -vhdl

  
:fin
endlocal
