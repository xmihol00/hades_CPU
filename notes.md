# Notes related to HW design
* **Orthogonal instruction set** - all instruction types can use all addressing modes, e.g. ADD can sum 2 operands from memory or 1 operand from memory and the other from register or both operands from registers. The result could be, I assume, stored as well either into memory or a register.
* **Non-orthogonal instruction set** - all instructions have the same addressing mode, registers are usually addressed (apart from LOAD and STORE instructions).
* **Harvard architecture** - data and program memory are logically and physically separated from each other.
* **Von-Neumann architecture** - data and program are stored in a single physical memory and accessed via single logical memory.
* **Moore machine** - finite-state machine whose current output values are determined only by its current state.
* **Mealy machine** - finite-state machine whose output values are determined both by its current state and the current inputs.
* **ALU (arithmetic logic unit)** - the computation unit of the CPU, it performs various calculations like arithmetic (ADD, SUB, MUL), logic (AND, OR, XOR, XNOR) or shifts (SHL, SHR, CSHL, CSHR).
* **FLAGS** - CF (carry flag), PF (parity flag), SF (signed flag), DF (direction flag).
* **Program Counter** - must be manipulated to allow jumps (branching, subroutines calls, interrupts), i.e. the program can react to external events and it reduces the program size and increases maintainability. (BEQZ, BNEZ, JAL, JREG, SWI).
* **Interrupts** - alow to react to to events of internal/external components (UART, memory interrupts, invalid peripheral, SWI, ...). ISR - Interrupt Service Routine handles the interrupt and then uses RETI to jump back to the next instruction of the normal program flow or lower level interrupt. 
