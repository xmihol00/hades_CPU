echo off
setlocal
goto _start_

:help
  echo   Compiles a module into the work library.
  echo.
  echo   ^<parameter^>^:= ^<module^>
  echo   ^<module^>   ^:= pmemory
  echo              ^|  haregs
  echo              ^|  alu
  echo              ^|  datapath
  echo              ^|  control
  echo              ^|  indec
  echo              ^|  isralogic
  echo              ^|  isrrlogic
  echo              ^|  checkirq
  echo              ^|  irqlogic
  echo              ^|  pclogic
  echo              ^|  pcblock
  echo              ^|  cpu
  echo              ^|  mcu  
  echo.
goto fin


:_start_

     
::Liste der Module, die für das angegebene Modul verausgesetzt werden 
set reqList=                                                          
if .%1==.pmemory    goto build
if .%1==.haregs     goto build
if .%1==.alu        goto build
if .%1==.datapath  (set reqList=alu
                    goto build)
if .%1==.control    goto build
if .%1==.indec      goto build
if .%1==.isralogic  goto build
if .%1==.isrrlogic  goto build
if .%1==.checkirq   goto build                   
if .%1==.irqlogic  (set reqList=isralogic isrrlogic checkirq
                    goto build)
if .%1==.pclogic    goto build                   
if .%1==.pcblock   (set reqList=irqlogic pclogic
                    goto build)                   
if .%1==.cpu       (set reqList=pmemory haregs datapath control indec pcblock
                    goto build)
if .%1==.mcu	   (set reqList=cpu
                    goto build)                    

::Abbruch, falls keins dieser Module angegeben wurde
goto help


::Module in die work-Library compilieren
:build      
  for %%i in (%reqList%) do call build %%i    
  echo == work ^<= %1 ==
  ..\_bin\ghdl-0.29.1-windows\bin\ghdl -a --ieee=synopsys --workdir=..\_lib -P..\_lib rtl\%1.vhd   
goto fin



:fin
endlocal
