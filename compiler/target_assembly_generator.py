from enums import TargetAssemblyHelpers, TargetAssemblyInstructions, TargetAssemblyRegisters, HighAssemblyInstructions
from writer import Writer
import re

class TargetAssemblyGenerator():
    def __init__(self, high_assembly_code: str|list[str], writer: Writer, register_map: dict[str, str] = { 
                     "r0": TargetAssemblyRegisters.R0, "r1": TargetAssemblyRegisters.R1, "r2": TargetAssemblyRegisters.R2, 
                     "r3": TargetAssemblyRegisters.R3, "eax": TargetAssemblyRegisters.EAX, "edx": TargetAssemblyRegisters.EDX, 
                     "ebp": TargetAssemblyRegisters.EBP, "esp": TargetAssemblyRegisters.ESP },
                 register_definitions: dict[str, str] = { "eax": "r4", "edx": "r5", "ebp": "r6", "esp": "r7"}):
        if isinstance(high_assembly_code, list):
            self.source_code = high_assembly_code
        else:
            self.source_code = high_assembly_code.split('\n')
        self.register_map = register_map
        self.writer = writer
        self.first_function = True
        self.regex = ( # TODO: refactor
            r"(^\s*@([a-z_][a-z0-9_]*):\s*(\-*\d+)\s*(;\s*(.*))*$)|" +  # @<identifier>: <value> (5 groups)
            r"(^\s*\$([a-z_][a-z0-9_]*):\s*(;\s*(.*))*$)|" +            # $<function name>:      (4 groups)
            HighAssemblyInstructions.PUSH.to_regex() +       # push <register|constant>          (4 and groups)
            HighAssemblyInstructions.POP.to_regex() +        # pop <register>                    (4 groups)
            HighAssemblyInstructions.PUSHA.to_regex() +      # pusha                             (3 groups)
            HighAssemblyInstructions.POPA.to_regex() +       # popa                              (3 groups)
            HighAssemblyInstructions.LOAD.to_regex() +       # load <register> <memory|global variable>          (7 and 5 groups)
            HighAssemblyInstructions.MOV.to_regex() +        # move <register> <constant|register>               (5 and 5 groups)
            HighAssemblyInstructions.STORE.to_regex() +      # store <memory|global variable> <register>         (7 and 5 groups)
            HighAssemblyInstructions.ADD.to_regex() +        # add <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.SUB.to_regex() +        # sub <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.MUL.to_regex() +        # mul <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.AND.to_regex() +        # and <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.OR.to_regex() +         # or  <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.XOR.to_regex() +        # xor <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.SHL.to_regex() +        # shl <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.SHR.to_regex() +        # shr <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.ROR.to_regex() +        # ror <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.ROL.to_regex() +        # rol <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.CALL.to_regex() +       # call <function name>                              (4 groups)
            HighAssemblyInstructions.RETURN.to_regex() +     # ret [number of cleared parameters from the stack] (4 or 3 groups)
            HighAssemblyInstructions.JMP.to_regex() +        # jmp <label>                                       (4 groups)
            HighAssemblyInstructions.JZ.to_regex() +         # je  <register> <label>                            (5 groups)
            HighAssemblyInstructions.JNZ.to_regex() +        # jne <register> <label>                            (5 groups)
            HighAssemblyInstructions.EQ.to_regex() +         # eq  <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.NEQ.to_regex() +        # neq <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.LT.to_regex() +         # lt  <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.GT.to_regex() +         # gt  <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.LTE.to_regex() +        # lte <register> <register> <constant|register>     (6 and 6 groups)
            HighAssemblyInstructions.GTE.to_regex() +        # gte <register> <register> <constant|register>     (6 and 6 groups)
            r"(^\s*([a-z_][a-z0-9_\.]*):\s*(;\s*(.*))*$)|" + # <label>:                                          (4 groups)
            HighAssemblyInstructions.NOT.to_regex() +        # not <register> <constant|register>                (5 and 5 groups)
            HighAssemblyInstructions.NEG.to_regex() +        # neg <register> <constant|register>                (5 and 5 groups)
            HighAssemblyInstructions.IN.to_regex() +         # in  <register> <positive constant>                (5 groups)
            HighAssemblyInstructions.OUT.to_regex() +        # out <register> <positive constant>                (5 groups)
            r"(^\s*&([a-z_][a-z0-9_\.]*):\s*(;\s*(.*))*$)|"  # <function name without stack frame>               (4 groups)
            r"(^\s*(;\s*(.*))*$)|" +                         # line comment                                      (3 groups)
            HighAssemblyInstructions.EOF.to_regex()          # eof                                               (3 groups)
        )
        self.group_dict = { # TODO: refactor
            0: self.handle_global_variable,
            5: self.handle_function_label, 
            9: self.handle_variable_push, 
            13: self.handle_constant_push,
            17: self.handle_pop, 
            21: self.handle_pusha, 
            24: self.handle_popa, 
            27: self.handle_memory_load, 
            34: self.handle_global_variable_load, 
            39: self.handle_constant_move, 
            44: self.handle_register_move, 
            49: self.handle_memory_store, 
            56: self.handle_global_variable_store, 
            61: self.handle_constant_store, 
            68: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.ADDI), 
            74: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.ADD), 
            80: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SUBI), 
            86: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SUB), 
            92: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.MULI), 
            98: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.MUL), 
            104: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.ANDI), 
            110: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.AND), 
            116: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.ORI), 
            122: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.OR), 
            128: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.XORI), 
            134: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.XOR), 
            140: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SHLI), 
            146: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SHL), 
            152: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SHRI), 
            158: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SHR), 
            164: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.CSHLI), 
            170: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.CSHL), 
            176: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.CSHRI), 
            182: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.CSHR), 
            188: self.handle_call, 
            192: self.handle_return, 
            196: self.handle_return_without_value,
            199: self.handle_jump, 
            203: self.handle_jump_if_zero, 
            208: self.handle_jump_if_not_zero, 
            213: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SEQI), 
            219: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SEQ), 
            225: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SNEI), 
            231: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SNE), 
            237: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SLTI), 
            243: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SLT), 
            249: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SGTI), 
            255: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SGT), 
            261: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SLEI), 
            267: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SLE), 
            273: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SGRI), 
            279: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SGR), 
            285: self.handle_label, 
            289: self.handle_constant_not, 
            294: self.handle_register_not, 
            299: self.handle_constant_negate, 
            304: self.handle_register_negate, 
            309: self.handle_input, 
            314: self.handle_output, 
            319: self.handle_function_label_without_stack,
            323: self.handle_line_comment,
            326: self.handle_end_of_function,
        }
        self.register_definitions = register_definitions

    def generate(self):
        for key, value in self.register_definitions.items():
            self.writer.raw(f'{TargetAssemblyHelpers.DEFINE_PREFIX} {key} "{value}"', 'register definitions')
        self.writer.new_line()

        for line in self.source_code:
            match = re.match(self.regex, line, re.IGNORECASE)
            for i, handler in self.group_dict.items():
                if match.groups()[i]:
                    handler(match.groups()[i + 1:])
        
        if not self.first_function:
            self.writer.raw(f"{TargetAssemblyHelpers.SCOPE_CLOSE}")
        self.writer.raw(
"""
@code __init {
   DEI                                  ; disable interrupts
   DPMA                                 ; set data memory access
   XOR @eax, @eax, @eax                 ; clear eax
   OUT @eax, #98                        ; set UART to byte mode and to not generate interrupts
   LDI @esp, #0xFFF                     ; init the stack pointer
   JAL @edx, *main                      ; call main
idle:
  JMP #idle                             ; infinite loop after return from main
@}
"""            
        )
    
    def handle_global_variable(self, matches: tuple[str]):
        self.writer.raw(f"{TargetAssemblyHelpers.DATA_LABEL} {matches[0]} {TargetAssemblyHelpers.SCOPE_OPEN}")
        self.writer.instruction(f"{TargetAssemblyHelpers.CONSTANT_PREFIX}{matches[1]}", matches[3])
        self.writer.raw(f"{TargetAssemblyHelpers.SCOPE_CLOSE}")

    def handle_function_label(self, matches: tuple[str]):
        if self.first_function:
            self._function_call(matches)
            self.first_function = False
        else:
            self.writer.raw(f"{TargetAssemblyHelpers.SCOPE_CLOSE}")
            self._function_call(matches)
    
    def handle_variable_push(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.SUBI} {TargetAssemblyRegisters.ESP}, #1", "increase stack size for a variable")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {self.register_map[matches[0]]}, {TargetAssemblyRegisters.ESP}, #0", matches[2])
    
    def handle_constant_push(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.SUBI} {TargetAssemblyRegisters.ESP}, #1", "increase stack size for a constant")
        self.writer.instruction(f"{TargetAssemblyInstructions.LDI} {self.register_map['edx']}, {TargetAssemblyHelpers.CONSTANT_PREFIX}{matches[0]}", f"edx = {matches[0]}")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {self.register_map['edx']}, {TargetAssemblyRegisters.ESP}, #0", f"push {matches[0]} loaded to edx")
    
    def handle_pop(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {self.register_map[matches[0]]}, {TargetAssemblyRegisters.ESP}, #0", matches[2])
        self.writer.instruction(f"{TargetAssemblyInstructions.ADDI} {TargetAssemblyRegisters.ESP}, #1", "clear a variable from the stack")
    
    def handle_pusha(self, matches: tuple[str]):
        self.writer.comment(matches[2])
        self.writer.instruction(f"{TargetAssemblyInstructions.SUBI} {TargetAssemblyRegisters.ESP}, #3", "stack frame, increase stack size to store general purpose registers")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {TargetAssemblyRegisters.R1}, {TargetAssemblyRegisters.ESP}, #0", "stack frame, store r1")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {TargetAssemblyRegisters.R2}, {TargetAssemblyRegisters.ESP}, #1", "stack frame, store r2")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {TargetAssemblyRegisters.R3}, {TargetAssemblyRegisters.ESP}, #2", "stack frame, store r3")

    def handle_popa(self, matches: tuple[str]):
        self.writer.comment(matches[2])
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {TargetAssemblyRegisters.R3}, {TargetAssemblyRegisters.ESP}, #2", "stack frame, restore r3")
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {TargetAssemblyRegisters.R2}, {TargetAssemblyRegisters.ESP}, #1", "stack frame, restore r2")
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {TargetAssemblyRegisters.R1}, {TargetAssemblyRegisters.ESP}, #0", "stack frame, restore r1")
        self.writer.instruction(f"{TargetAssemblyInstructions.ADDI} {TargetAssemblyRegisters.ESP}, #3", "stack frame, clear stack from general purpose registers")

    def handle_memory_load(self, matches: tuple[str]):
        matches = list(matches[:6])
        matches[2] = matches[2] if matches[2] == '-' else ''
        matches[3] = matches[3] if matches[3] else 0
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}, #{matches[2]}{matches[3]}", matches[5])

    def handle_global_variable_load(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {self.register_map[matches[0]]}, {TargetAssemblyRegisters.R0}, *d*{matches[1]}", matches[3])

    def handle_constant_move(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.LDI} {self.register_map[matches[0]]}, #{matches[1]}", matches[3])

    def handle_register_move(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.MOV} {self.register_map[matches[1]]}, {self.register_map[matches[0]]}", matches[3])

    def handle_memory_store(self, matches: tuple[str]):
        matches = list(matches[:6])
        matches[1] = matches[1] if matches[1] == '-' else ''
        matches[2] = matches[2] if matches[2] else 0
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {self.register_map[matches[3]]}, {self.register_map[matches[0]]}, #{matches[1] if matches[1] == '-' else ''}{matches[2]}", matches[5])

    def handle_global_variable_store(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {self.register_map[matches[1]]}, {TargetAssemblyRegisters.R0}, *d*{matches[0]}", matches[3])
    
    def handle_constant_store(self, matches: tuple[str]):
        matches = list(matches[:6])
        matches[1] = matches[1] if matches[1] == '-' else ''
        matches[2] = matches[2] if matches[2] else 0
        self.writer.instruction(f"{TargetAssemblyInstructions.LDI} {TargetAssemblyRegisters.EDX}, #{matches[3]}", f"edx = {matches[3]}")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {TargetAssemblyRegisters.EDX}, {self.register_map[matches[0]]}, #{matches[1]}{matches[2]}", f"store {matches[3]} loaded to edx")

    def handle_call(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.JAL} {TargetAssemblyRegisters.EDX}, *{matches[0]}", matches[2])
    
    def handle_return(self, matches: tuple[str]):
        cleared_words = int(matches[0]) + 1
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {TargetAssemblyRegisters.EDX}, {TargetAssemblyRegisters.ESP}, #0", "return value, load return value from stack")
        self.writer.instruction(f"{TargetAssemblyInstructions.ADDI} {TargetAssemblyRegisters.ESP}, #{cleared_words}", f"decrease stack size by the number of parameters + the return value")
        self.writer.instruction(f"{TargetAssemblyInstructions.JREG} {TargetAssemblyRegisters.EDX}", matches[2])
    
    def handle_return_without_value(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.JREG} {TargetAssemblyRegisters.EDX}", matches[1])
    
    def handle_jump(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.JMP} #{matches[0].replace('.', '__')}", matches[2])
    
    def handle_jump_if_zero(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.BEQZ} {self.register_map[matches[0]]}, #{matches[1].replace('.', '__')}", matches[3])
    
    def handle_jump_if_not_zero(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.BNEZ} {self.register_map[matches[0]]}, #{matches[1].replace('.', '__')}", matches[3])

    def handle_jump_if_overflow(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.BOV} #{matches[0]}", matches[2])
    
    def handle_label(self, matches: tuple[str]):
        self.writer.label(matches[0].replace('.', '__'), matches[2])

    def handle_constant_not(self, matches: tuple[str]):
        not_value = (~int(matches[1])) & 0xFFFF # limit to 16 bit
        self.writer.instruction(f"{TargetAssemblyInstructions.LDI} {self.register_map[matches[0]]}, #{not_value}", matches[3])

    def handle_register_not(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.XORI} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}, #-1", matches[3])

    def handle_constant_negate(self, matches: tuple[str]):
        negate_value = (-int(matches[1])) & 0xFFFF # limit to 16 bit
        self.writer.instruction(f"{TargetAssemblyInstructions.LDI} {self.register_map[matches[0]]}, #{negate_value}", matches[3])

    def handle_register_negate(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.XORI} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}, #-1", f"{matches[3]} part 1")
        self.writer.instruction(f"{TargetAssemblyInstructions.SUBI} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}, #1", f"{matches[3]} part 2")
    
    def handle_input(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.IN} {self.register_map[matches[0]]}, #{matches[1]}", matches[3])
    
    def handle_output(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.OUT} {self.register_map[matches[0]]}, #{matches[1]}", matches[3])
    
    def handle_function_label_without_stack(self, matches: tuple[str]):
        if self.first_function:
            self.writer.raw(f"{TargetAssemblyHelpers.CODE_LABEL} {matches[0]} {TargetAssemblyHelpers.SCOPE_OPEN}", matches[2])
            self.first_function = False
        else:
            self.writer.raw(f"{TargetAssemblyHelpers.SCOPE_CLOSE}")
            self.writer.raw(f"{TargetAssemblyHelpers.CODE_LABEL} {matches[0]} {TargetAssemblyHelpers.SCOPE_OPEN}", matches[2])

    def handle_line_comment(self, matches: tuple[str]):
        self.writer.comment(matches[1])

    def handle_end_of_function(self, matches: tuple[str]):
        self.writer.raw(f"@}} {matches[0]}\n")
        self.first_function = True
    
    def _handle_constant_ALU_instruction(self, matches: tuple[str], instruction: TargetAssemblyInstructions):
        self.writer.instruction(f"{instruction} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}, #{matches[2]}", matches[4])
    
    def _handle_register_ALU_instruction(self, matches: tuple[str], instruction: TargetAssemblyInstructions):
        self.writer.instruction(f"{instruction} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}, {self.register_map[matches[2]]}", matches[4])

    def _function_call(self, matches: tuple[str]):
        self.writer.raw(f"{TargetAssemblyHelpers.CODE_LABEL} {matches[0]} {TargetAssemblyHelpers.SCOPE_OPEN}", matches[2])
        self.writer.instruction(f"{TargetAssemblyInstructions.SUBI} {TargetAssemblyRegisters.ESP}, #1", "return value, increase stack size to store the return value")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {TargetAssemblyRegisters.EDX}, {TargetAssemblyRegisters.ESP}, #0", "return value, store return address")
        