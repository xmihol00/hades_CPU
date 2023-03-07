#!/bin/bash

input=$1  
reqList=

function help {
  echo   Compiles a module into the work library.
  echo
  echo  "<parameter>:= <module>"
  echo  "<module>   := pmemory"
  echo  "            | haregs"
  echo  "            | alu"
  echo  "            | datapath"
  echo  "            | control"
  echo  "            | indec"
  echo  "            | isralogic"
  echo  "            | isrrlogic"
  echo  "            | checkirq"
  echo  "            | irqlogic"
  echo  "            | pclogic"
  echo  "            | pcblock"
  echo  "            | cpu"
  echo  "            | mcu"  
  echo
  exit 0
}


function build {
  for i in $reqList 
  do
    bash build.sh $i || {
      exit 1
   }
  done
  echo "== work <= "$input

  ../_bin/ghdl-0.33-x86_64-linux/bin/ghdl -a --ieee=synopsys --workdir=../_lib -P../_lib rtl/$input.vhd   
  exit $?
}

     
#Liste der Module, die für das angegebene Modul verausgesetzt werden                      
if [[ $1 = "pmemory" ]]; then build; fi
if [[ $1 = "haregs" ]]; then build; fi
if [[ $1 = "alu" ]]; then build; fi
if [[ $1 = "datapath" ]]; then
    reqList=alu
    build
fi
if [[ $1 = "control" ]]; then build; fi
if [[ $1 = "indec" ]]; then build; fi
if [[ $1 = "isralogic" ]]; then build; fi
if [[ $1 = "isrrlogic" ]]; then build; fi
if [[ $1 = "checkirq" ]]; then build; fi                   
if [[ $1 = "irqlogic" ]]; then  
  reqList="isralogic isrrlogic checkirq"
  build
fi
if [[ $1 = "pclogic" ]]; then build; fi                   
if [[ $1 = "pcblock" ]]; then   
  reqList="irqlogic pclogic"
  build
fi                  
if [[ $1 = "cpu" ]]; then 
   reqList="pmemory haregs datapath control indec pcblock"
   build
fi
if [[ $1 = "mcu" ]]; then    
  reqList="cpu"
  build
fi                 

help
