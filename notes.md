# Notes related to HW design
* **Orthogonal instruction set** - all instruction types can use all addressing modes, e.g. ADD can sum 2 operands from memory or 1 operand from memory and the other from register or both operands from registers. The result could be, I assume, stored as well either into memory or a register.
* **Non-orthogonal instruction set** - all instructions have the same addressing mode, registers are usually addressed (apart from LOAD and STORE instructions).
* **Harvard architecture** - data and program memory are logically and physically separated from each other.
* **Von-Neumann architecture** - data and program are stored in a single physical memory and accessed via single logical memory.
* **Moore machine** - finite-state machine whose current output values are determined only by its current state.
* **Mealy machine** - finite-state machine whose output values are determined both by its current state and the current inputs.
* **ALU (arithmetic logic unit)** - the computation unit of the CPU, it performs various calculations like arithmetic (ADD, SUB, MUL), logic (AND, OR, XOR, XNOR) or shifts (SHL, SHR, CSHL, CSHR).
