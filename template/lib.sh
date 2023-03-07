#!/bin/bash

param1=$1
param2=$2

function help {
	echo "Create, delete, or show the library."
	echo
	echo \<parameter\>	:= \<lib\> \[build \| clean\]
	echo \<lib\>			:= all \| work \| xbus_sim \| xbus_common \| xbus_synth \| unisim
	echo
	exit 2
}



#Aktion für alle Librarys ausführen
function all {
	for i in $list; do 
		bash lib.sh $i $param2 || {
			echo "lib call for $i $param2 failed"
			exit 1
		}
	done
	exit 0
}
#Prüfen, ob angegebene Library angezeigt, gebaut oder gelöscht werden soll 
function lib {
	if [ -z $param2 ] || [[ $param2 = show ]]; then show; fi
	if [[ $param2 = build ]]; then build; fi
	if [[ $param2 = clean ]]; then clean; fi
	help
}

  
#Inhalt der Library anzeigen  
function show {
	echo "== show $param1 =="
	../_bin/ghdl-0.33-x86_64-linux/bin/ghdl -d --workdir=../_lib --work=$param1
	exit 0
}
  
#Library löschen 
function clean {
	echo "== clean $param1 =="
	rm -rf ../_lib/$param1*.cf
	for i in $list; do
		rm -rf ../_lib/$i.o
	done
	exit 0
}
  
#Library bauen
function build {
	for i in $list; do
		echo "== build $param1 <= $i =="
		../_bin/ghdl-0.33-x86_64-linux/bin/ghdl	-a --workdir=../_lib \
		-P../_lib --work=$param1 ../_lib/$param1/$i.vhd 
	done
	exit 0
}


#Liste der Module, die in die angegebene Library aufgenommen werden sollen
if [[ $1 = work ]]; then       
	list="hadescomponents hades_addsub hades_compare hades_mul hades_shift hades_ram_dp irqreceiver"; 
	lib; 
fi
if [[ $1 = xbus_sim ]]; then   
	list="xdmemory_sim xbus_sim"; 
	lib; 
fi                  
if [[ $1 = xbus_common ]]; then   
	list="xreset xtoolbox xtimerxt"; 
	lib; 
fi      
if [[ $1 = xbus_synth ]]; then 
	list="xdmemory_dcache xvga_out xvga xconsole xps2 xuart xsevenseg xbus_syn"; 
	lib; 
fi                     
if [[ $1 = unisim ]]; then     
	list="unisim_VCOMP unisim_VPKG"; 
	lib; 
fi
if [[ $1 = all ]]; then        
	list="unisim xbus_common xbus_sim xbus_synth work"; 
	all;
fi                     
             
help
