::
:: batch file to reanalyze GHDL libraries
::   - fixes any library timestamp errors caused by installer problems
::   - analyzes ieee math_real and math_complex
::
:: run this script from the ghdl install location, at the directory level with 'bin' and 'lib'
::
:: derived from the GHDL 0.25 file \translate\mcode\windows\complib.bat
::   

::
:: derive paths from batch file location, using short filenames [ ~dps0 => dRIVE pATH sHORT 0 ]
::
set BASE=%~dps0
echo %BASE%

set GHDL=%BASE%\bin\ghdl
set LIB=%BASE%\lib

::
:: library source files
::
set STD_SRCS=       textio textio_body
set IEEE_SRCS=      std_logic_1164 std_logic_1164_body numeric_std numeric_std-body numeric_bit numeric_bit-body
set VITAL95_SRCS=   vital_timing vital_timing_body vital_primitives vital_primitives_body
set VITAL2000_SRCS= timing_p timing_b prmtvs_p prmtvs_b memory_p memory_b

set SYNOPSYS_SRCS=  std_logic_arith std_logic_textio std_logic_unsigned std_logic_signed std_logic_misc std_logic_misc-body

set MATH_REAL_SRCS= math_real math_real-body math_complex math_complex-body 

:::::::::::::::::::::
::
:: VHDL-87 libraries
::
:::::::::::::::::::::

::::
echo VHDL-87 std library
cd %LIB%\v87\std

for %%F in (%STD_SRCS%)       do  %GHDL% -a --std=87 --bootstrap --work=std %%F.v87

::::
echo VHDL-87 IEEE Base and Vital 95
cd %LIB%\v87\ieee

for %%F in (%IEEE_SRCS%)      do %GHDL% -a --std=87 -P..\std --work=ieee %%F.v87
for %%F in (%VITAL95_SRCS%)   do %GHDL% -a --std=87 -P..\std --work=ieee %%F.vhd

::::
echo  VHDL-87 Synopsys libs
cd %LIB%\v87\synopsys

for %%F in (%IEEE_SRCS%)      do %GHDL% -a --std=87 -P..\std --work=ieee ..\ieee\%%F.v87
for %%F in (%VITAL95_SRCS%)   do %GHDL% -a --std=87 -P..\std --work=ieee ..\ieee\%%F.vhd
for %%F in (%SYNOPSYS_SRCS%)  do %GHDL% -a --std=87 -P..\std --work=ieee %%F.vhd

:::::::::::::::::::::
::
:: VHDL-93 libraries
::
:::::::::::::::::::::

::::
echo VHDL-93 std library
cd %LIB%\v93\std

for %%F in (%STD_SRCS%)       do %GHDL% -a --std=93 --bootstrap --work=std %%F.v93

::::
echo VHDL-93 IEEE Base and Vital 95
cd  %LIB%\v93\ieee

for %%F in (%IEEE_SRCS%)      do %GHDL% -a --std=93 -P..\std --work=ieee %%F.v93
for %%F in (%VITAL2000_SRCS%) do %GHDL% -a --std=93 -P..\std --work=ieee %%F.vhd

::
:: need to first download these from http://standards.ieee.org/downloads/1076/1076.2-1996/
::
echo  VHDL-93 MATH.REAL libs (must be downloaded by user)

:: note .vhdl extension as-downloaded from ieee
for %%F in (%MATH_REAL_SRCS%)  do %GHDL% -a --std=93 -P..\std --work=ieee ..\ieee\%%F.vhdl

::::
echo  VHDL-93 Synopsys libs
cd  %LIB%\v93\synopsys

for %%F in (%IEEE_SRCS%)      do %GHDL% -a --std=93 -P..\std --work=ieee ..\ieee\%%F.v93
for %%F in (%VITAL2000_SRCS%) do %GHDL% -a --std=93 -P..\std --work=ieee ..\ieee\%%F.vhd
for %%F in (%SYNOPSYS_SRCS%)  do %GHDL% -a --std=93 -P..\std --work=ieee ..\..\v87\synopsys\%%F.vhd

:: note .vhdl extension as-downloaded from ieee
for %%F in (%MATH_REAL_SRCS%) do %GHDL% -a --std=93 -P..\std --work=ieee ..\ieee\%%F.vhdl

cd %BASE%