#/!bin/bash


function help {
  echo   Compiles and links the bootloader assembler.
  echo
  exit 0
}


  wine ../_bin/hoasm.exe -I ../_assembler/inc "../_assembler/bootloader/boot.has"
  wine ../_bin/hlink.exe -L ../_assembler/inc -o "../_assembler/bootloader/boot.hix" "../_assembler/bootloader/boot.ho" -vhdl
