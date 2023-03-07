echo off
setlocal
goto _start_

:help
  echo   executes a testbench of one (or all) modules,
  echo   creates the waveform and shows is if you wish
  echo.
  echo   ^<parameter^>^:= ^{all ^| ^{^<module^> ^[show^]^}^}
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
  echo              ^|  cpu ^<num^>
  echo   ^<num^>      ^:= 1 ^| 2 ^| 3 ^| 4 ^| 5
  echo.
goto fin

:laufzeit
  echo In the testbench no runtime comment was found.
  echo Please add a comment line with "-- runtime: <value>ns" into the testbench.
  echo.
goto fin

:_start_

:: Checks if all testbenches should be executed
if .%1==.all        goto all

::set source of the module
set source=..\_testbench\%1_tb

::show-flag: if s=show => waveform is shown with gtkwave
set s=%2

::the number of the cpu test
set n=

::checks which module will be tested
if .%1==.pmemory    goto stoptime
if .%1==.haregs     goto stoptime
if .%1==.alu        goto stoptime
if .%1==.datapath   goto stoptime
if .%1==.control    goto stoptime
if .%1==.indec      goto stoptime
if .%1==.isralogic  goto stoptime
if .%1==.isrrlogic  goto stoptime
if .%1==.checkirq   goto stoptime                   
if .%1==.irqlogic   goto stoptime
if .%1==.pclogic    goto stoptime                   
if .%1==.pcblock    goto stoptime                   
if .%1==.cpu        goto cpu
                                     
::abort, if no modules is selected
goto help

::selection of the cpu test
:cpu  
  set s=%3  
  if .%2==.show set s=show
  if .%2==.2    set n=2
  if .%2==.3    set n=3
  if .%2==.4    set n=4
  if .%2==.5    set n=5
  if .%n%==.    set n=1
                   
  echo %n% >> ..\_testbench\cpu_tb.num
 
::detect the runtime of the cpu tests in the .mif file
:: % runtime @25MHz: ###ns
  for /F "tokens=1-4" %%a in ('C:\Windows\System32\find.exe "runtime @50MHz:" %source%%n%.mif') do (    
    if .%%b==.runtime set stoptime=%%d
  )
goto run


::detect the runtime of a testbench
:: -- runtime: ###ns
:stoptime
  for /F "tokens=1-3" %%a in ('C:\Windows\System32\find.exe "-- runtime:" %source%.vhd') do (
    if .%%b==.runtime: set stoptime=%%c
  )
  if "%stoptime%"=="" goto laufzeit
goto run


::compile the testbench, execute it and, if required, shows the waveform
:run
  
  echo == work ^<= %source% ==
  ..\_bin\ghdl-0.29.1-windows\bin\ghdl -a --workdir=../_lib -P../_lib %source%.vhd

::handling of the cpu tests
  set wave=%source%
  if .%1==.cpu (
    set wave=..\_testbench\cpu_tb%n%
    set source=%source%%n%
  )
    
  echo == run %1_tb for %stoptime% ==    
  ..\_bin\ghdl-0.29.1-windows\bin\ghdl -r --workdir=../_lib -P../_lib %1_tb --stop-time=%stoptime% --wave=%wave%.ghw --stack-max-size=1000000kb

  echo "============================================================"
  echo "== ATTENTION: This testbenches does NOT check everything! =="
  echo "============================================================"

::remove cpu help file
  if .%1==.cpu del ..\_testbench\cpu_tb.num 
    
  if .%s%==.show (
    echo == show waveform ==
    gtkwave %wave%.ghw %wave%.sav
  )
goto fin  
  
::test all modules 
:all
  for %%i in (pmemory haregs alu datapath control indec isralogic isrrlogic checkirq irqlogic pclogic pcblock cpu) do (
    call run %%i
  )
goto fin
  
:fin
endlocal
