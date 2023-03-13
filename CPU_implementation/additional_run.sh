#/!bin/bash

param1=$1
param2=$2
param3=$3

function help {
  echo   "Simulates a testbench of a module (or all modules),"
  echo   and generates a waveform
  echo
  echo  "<parameter>= {all | {<module> [show]}}"
  echo  "<module>   = pmemory"
  echo	"           | haregs"
  echo  "           | alu"
  echo  "           | datapath"
  echo  "           | control"
  echo  "           | indec"
  echo  "           | isralogic"
  echo  "           | isrrlogic"
  echo  "           | checkirq"
  echo  "           | irqlogic"
  echo  "           | pclogic"
  echo  "           | pcblock"
  echo  "           | cpu <num>"
  echo  "<num>      = 1 | 2 | 3 | 4 | 5 "
  echo
  exit 2
}

function laufzeit {
  echo No runtime found in the testbench
  echo Please add a comment with  "-- runtime: <value>ns" into the testbench.
  echo
  exit 2
}

function cpu {
  s=$param3 
  if [[ $param2 = show ]]; then s=show; fi
  if [[ $param2 = 2 ]]; then    n=2; fi
  if [[ $param2 = 3 ]]; then    n=3; fi
  if [[ $param2 = 4 ]]; then    n=4; fi
  if [[ $param2 = 5 ]]; then    n=5; fi
  if [ -z $n ]; then  n=1; fi
                   
  echo $n >> ./additional_testbenches/cpu_tb.num
  
  stoptime=`cat $source$n.mif | grep runtime --binary-files=text \
		| sed -r 's/% runtime @50MHz: ([0-9]+..).*/\1/g'`
  run
}

#::Ermittlung der Laufzeit der Tests aus dem Kommentar in der Testbench 
#:: -- Laufzeit: ###ns
function stoptime {
  stoptime=`cat $source.vhd | grep runtime --binary-files=text | sed -r 's/-- runtime: ([0-9]+..).*/\1/g'`
  if [ -z stoptime ]; then laufzeit; fi
  run
}


#TestBench compilieren und ausführen und ggf. Waveform anzeigen
# workaround, because GHDL uses the windows paths for the hex file
function run {
  ghdl -a --workdir=../_lib -P../_lib $source.vhd

  #Waveforms der CPU-Tests werden explizit im Gruppenordner abgelegt
  wave=$source
  if [[ $param1 = cpu ]]; then 
    wave=./additional_testbenches/cpu_tb$n
    source=$source$n
  fi
   
  ghdl -e --workdir=../_lib -P../_lib $param1"_tb"

  echo "== simulation: ${param1}_tb for $stoptime"
  ghdl -r --workdir=../_lib -P../_lib $param1"_tb" \
			--wave=$wave.ghw --stop-time=$stoptime
  
  #remove tmp cpu test file  
  if [[ $param1 = cpu ]]; then rm ./additional_testbenches/cpu_tb.num ; fi
   
  #show the waveform
  if [[ $s = show ]]; then
    echo "== show waveform =="
    gtkwave $wave.ghw $wave.sav
  fi


  # clean up 
  rm -rf "e~"$param1"_tb.o"
  rm -rf $param1"_tb"

  exit 0
}


function all {
  mods="pmemory haregs alu datapath control indec isralogic isrrlogic checkirq irqlogic pclogic pcblock cpu"
  for i in $mods
   do
    bash run.sh $i
  done
  exit 0
}



#::Name der Testbench des Moduls
source=./additional_testbenches/$1_tb

#::Show-Flag: wenn s=show => waveform mit gtkwave anzeigen
s=$2

#::Nummer des CPU-Tests, der ausgeführt werden soll
n=


#::Prüfen, welches Modul getestet werden soll
if [[ $1 = all ]]; then	       all; fi
if [[ $1 = pmemory ]]; then    stoptime; fi
if [[ $1 = haregs ]]; then     stoptime; fi
if [[ $1 = alu ]]; then        stoptime; fi
if [[ $1 = datapath ]]; then   stoptime; fi
if [[ $1 = control ]]; then    stoptime; fi
if [[ $1 = indec ]]; then      stoptime; fi
if [[ $1 = isralogic ]]; then  stoptime; fi
if [[ $1 = isrrlogic ]]; then  stoptime; fi
if [[ $1 = checkirq ]]; then   stoptime; fi                   
if [[ $1 = irqlogic ]]; then   stoptime; fi
if [[ $1 = pclogic ]]; then    stoptime; fi                   
if [[ $1 = pcblock ]]; then    stoptime; fi                   
if [[ $1 = cpu ]]; then        cpu; fi
                                     
help

#::Abfrage der Nummer des CPU-Tests, der gestartet werden soll





