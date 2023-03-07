#!/bin/bash



function help {
  echo
  echo   Compiles and links the assembler files.
  echo   No assembler files found. 
  echo   Please put them into the folder \"assembler\"
  echo
  exit 1
}

function compile_link {
  wine ../_bin/hoasm.exe -I ../_assembler/inc "$1.has"
  wine ../_bin/hlink.exe -L ../_assembler/inc -o "$1.hix" "$1.ho"
}

files=$(ls assembler/*.has 2> /dev/null | wc -l)
if [ "$files" == "0" ]
then
	help
fi

for i in assembler/*.has
do
	echo "== compile $i =="
	compile_link ${i%*.has}
	echo
done
