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
        self.regex = (
            r"(^\s*@([a-z_][a-z0-9_]*):\s*(\-*\d+)\s*(;\s*(.*))*$)|" +  # @<identifier>: <value> (5 groups)
            r"(^\s*\$([a-z_][a-z0-9_]*):\s*(;\s*(.*))*$)|" +            # $<function name>:      (4 groups)
            HighAssemblyInstructions.PUSH.to_regex() +       # push <register>        (4 groups)
            HighAssemblyInstructions.POP.to_regex() +        # pop <register>         (4 groups)
            HighAssemblyInstructions.PUSHA.to_regex() +      # pusha                  (3 groups)
            HighAssemblyInstructions.POPA.to_regex() +       # popa                   (3 groups)
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
            r"(^\s*(;\s*(.*))*$)|"                           # line comment                                      (3 groups)
        )
        self.group_dict = {
            0: self.handle_global_variable,
            5: self.handle_function_label, 
            9: self.handle_push, 
            13: self.handle_pop, 
            17: self.handle_pusha, 
            20: self.handle_popa, 
            23: self.handle_memory_load, 
            30: self.handle_global_variable_load, 
            35: self.handle_constant_move, 
            40: self.handle_register_move, 
            45: self.handle_memory_store, 
            52: self.handle_global_variable_store, 
            57: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.ADDI), 
            63: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.ADD), 
            69: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SUBI), 
            75: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SUB), 
            81: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.MULI), 
            87: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.MUL), 
            93: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.ANDI), 
            99: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.AND), 
            105: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.ORI), 
            111: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.OR), 
            117: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.XORI), 
            123: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.XOR), 
            129: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SHLI), 
            135: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SHL), 
            141: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SHRI), 
            147: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SHR), 
            153: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.CSHLI), 
            159: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.CSHL), 
            165: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.CSHRI), 
            171: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.CSHR), 
            177: self.handle_call, 
            181: self.handle_return, 
            185: self.handle_return_without_value,
            189: self.handle_jump, 
            192: self.handle_jump_if_zero, 
            197: self.handle_jump_if_not_zero, 
            202: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SEQI), 
            208: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SEQ), 
            214: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SNEI), 
            220: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SNE), 
            226: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SLTI), 
            232: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SLT), 
            238: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SGTI), 
            244: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SGT), 
            250: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SLEI), 
            256: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SLE), 
            262: lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SGRI), 
            268: lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SGR), 
            274: self.handle_label, 
            278: self.handle_constant_not, 
            283: self.handle_register_not, 
            288: self.handle_constant_negate, 
            293: self.handle_register_negate, 
            298: self.handle_input, 
            303: self.handle_output, 
            308: self.handle_function_label_without_stack,
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
        
        self.writer.raw(f"{TargetAssemblyHelpers.SCOPE_CLOSE}")
        self.writer.raw(
"""
@code __init {
   DPMA                                 ; set data memory access
   DEI                                  ; disable interrupts
   LDI @esp, #0x7FFF                    ; init stack-pointer
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
    
    def handle_push(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.SUBI} {TargetAssemblyRegisters.ESP}, #1", "increase stack size for a variable")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {self.register_map[matches[0]]}, {TargetAssemblyRegisters.ESP}, #0", matches[2])
    
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
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}, #{matches[2] if matches[2] == '-' else ''}{matches[3]}", matches[5])

    def handle_global_variable_load(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {self.register_map[matches[0]]}, {TargetAssemblyRegisters.R0}, *d*{matches[1]}", matches[3])

    def handle_constant_move(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.LDI} {self.register_map[matches[0]]}, #{matches[1]}", matches[3])

    def handle_register_move(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.MOV} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}", matches[3])

    def handle_memory_store(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {self.register_map[matches[3]]}, {self.register_map[matches[0]]}, #{matches[1] if matches[1] == '-' else ''}{matches[2]}", matches[5])

    def handle_global_variable_store(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {self.register_map[matches[1]]}, {TargetAssemblyRegisters.R0}, *d*{matches[0]}", matches[3])

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
        self.writer.instruction(f"{TargetAssemblyInstructions.JMP} #{matches[0]}", matches[2])
    
    def handle_jump_if_zero(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.BEQZ} {self.register_map[matches[0]]}, #{matches[1].replace('.', '_')}", matches[3])
    
    def handle_jump_if_not_zero(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.BNEZ} {self.register_map[matches[0]]}, #{matches[1].replace('.', '_')}", matches[3])

    def handle_jump_if_overflow(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.BOV} #{matches[0]}", matches[2])
    
    def handle_label(self, matches: tuple[str]):
        self.writer.label(matches[0].replace('.', '_'), matches[2])

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
    
    def _handle_constant_ALU_instruction(self, matches: tuple[str], instruction: TargetAssemblyInstructions):
        self.writer.instruction(f"{instruction} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}, #{matches[2]}", matches[4])
    
    def _handle_register_ALU_instruction(self, matches: tuple[str], instruction: TargetAssemblyInstructions):
        self.writer.instruction(f"{instruction} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}, {self.register_map[matches[2]]}", matches[4])

    def _function_call(self, matches: tuple[str]):
        self.writer.raw(f"{TargetAssemblyHelpers.CODE_LABEL} {matches[0]} {TargetAssemblyHelpers.SCOPE_OPEN}", matches[2])
        self.writer.instruction(f"{TargetAssemblyInstructions.SUBI} {TargetAssemblyRegisters.ESP}, #1", "return value, increase stack size to store the return value")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {TargetAssemblyRegisters.EDX}, {TargetAssemblyRegisters.ESP}, #0", "return value, store return address")

        