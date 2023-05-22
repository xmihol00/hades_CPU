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
            r"(^\s*\$([a-z_][a-z0-9_]*):\s*(;\s*(.*))*$)|" +            # $<identifier>:         (4 groups)
            HighAssemblyInstructions.PUSH.to_regex() +       # push <register>        (4 groups)
            HighAssemblyInstructions.POP.to_regex() +        # pop <register>         (4 groups)
            HighAssemblyInstructions.PUSHA.to_regex() +      # pusha                  (3 groups)
            HighAssemblyInstructions.POPA.to_regex() +       # popa                   (3 groups)
            HighAssemblyInstructions.LOAD.to_regex() +       # load <register> <memory|global variable>      (7 and 5 groups)
            HighAssemblyInstructions.MOV.to_regex() +        # move <register> <constant|register>           (5 and 5 groups)
            HighAssemblyInstructions.STORE.to_regex() +      # store <memory|global variable> <register>     (7 and 5 groups)
            HighAssemblyInstructions.ADD.to_regex() +        # add <register> <register> <constant|register> (6 and 6 groups)
            HighAssemblyInstructions.SUB.to_regex() +        # sub <register> <register> <constant|register> (6 and 6 groups)
            HighAssemblyInstructions.MUL.to_regex() +        # mul <register> <register> <constant|register> (6 and 6 groups)
            HighAssemblyInstructions.AND.to_regex() +        # and <register> <register> <constant|register> (6 and 6 groups)
            HighAssemblyInstructions.OR.to_regex() +         # or  <register> <register> <constant|register> (6 and 6 groups)
            HighAssemblyInstructions.XOR.to_regex() +        # xor <register> <register> <constant|register> (6 and 6 groups)
            HighAssemblyInstructions.SHL.to_regex() +        # shl <register> <register> <constant|register> (6 and 6 groups)
            HighAssemblyInstructions.SHR.to_regex() +        # shr <register> <register> <constant|register> (6 and 6 groups)
            HighAssemblyInstructions.ROR.to_regex() +        # ror <register> <register> <constant|register> (6 and 6 groups)
            HighAssemblyInstructions.ROL.to_regex() +        # rol <register> <register> <constant|register> (6 and 6 groups)
            r"(^\s*(;\s*(.*))*$)|"                           # line comment
        )
        self.group_dict = {
            0: (self.handle_global_variable, 1),
            5: (self.handle_function_call, 6),
            9: (self.handle_push, 10),
            13: (self.handle_pop, 14),
            17: (self.handle_pusha, 18),
            20: (self.handle_popa, 21),
            23: (self.handle_memory_load, 24),
            30: (self.handle_global_variable_load, 31),
            35: (self.handle_constant_move, 36),
            40: (self.handle_register_move, 41),
            45: (self.handle_memory_store, 46),
            52: (self.handle_global_variable_store, 53),
            57: (lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.ADDI), 58),
            63: (lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.ADD), 64),
            69: (lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SUBI), 70),
            75: (lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SUB), 76),
            81: (lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.MULI), 82),
            87: (lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.MUL), 88),
            93: (lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.ANDI), 94),
            99: (lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.AND), 100),
            105: (lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.ORI), 106),
            111: (lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.OR), 112),
            117: (lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.XORI), 118),
            123: (lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.XOR), 124),
            129: (lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SHLI), 130),
            135: (lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SHL), 136),
            141: (lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.SHRI), 142),
            147: (lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.SHR), 148),
            153: (lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.CSHLI), 154),
            159: (lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.CSHL), 160),
            165: (lambda x: self._handle_constant_ALU_instruction(x, TargetAssemblyInstructions.CSHRI), 166),
            171: (lambda x: self._handle_register_ALU_instruction(x, TargetAssemblyInstructions.CSHR), 172),
        }
        self.register_definitions = register_definitions

    def generate(self):
        for key, value in self.register_definitions.items():
            self.writer.raw(f'{TargetAssemblyHelpers.DEFINE_PREFIX} {key} "{value}"', 'register definitions')
        self.writer.new_line()

        for line in self.source_code:
            match = re.match(self.regex, line, re.IGNORECASE)
            #for i, value in enumerate(match.groups()):
            #    if value:
            #        print(f"{i}: {value}")
            for i, (handler, shift) in self.group_dict.items():
                if match.groups()[i]:
                    handler(match.groups()[shift:])
        
        self.writer.raw(f"{TargetAssemblyHelpers.SCOPE_CLOSE}")
    
    def handle_global_variable(self, matches: tuple[str]):
        self.writer.raw(f"{TargetAssemblyHelpers.DATA_LABEL} {matches[0]} {TargetAssemblyHelpers.SCOPE_OPEN}")
        self.writer.instruction(f"{TargetAssemblyHelpers.CONSTANT_PREFIX}{matches[1]}", matches[3])
        self.writer.raw(f"{TargetAssemblyHelpers.SCOPE_CLOSE}")

    def handle_function_call(self, matches: tuple[str]):
        if self.first_function:
            self._function_call(matches)
            self.first_function = False
        else:
            self.writer.raw(f"{TargetAssemblyHelpers.SCOPE_CLOSE}")
            self._function_call(matches)
    
    def handle_push(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.SUBI} {TargetAssemblyRegisters.ESP}, #1", "stack frame, increase stack size by 4 B")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {matches[0]}, {TargetAssemblyRegisters.ESP}, #0", matches[2])
    
    def handle_pop(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {TargetAssemblyRegisters.ESP}, {matches[0]}, #0", matches[2])
        self.writer.instruction(f"{TargetAssemblyInstructions.ADDI} {TargetAssemblyRegisters.ESP}, #1", "stack frame, decrease stack size 4 B")
    
    def handle_pusha(self, matches: tuple[str]):
        self.writer.comment(matches[2])
        self.writer.instruction(f"{TargetAssemblyInstructions.SUBI} {TargetAssemblyRegisters.ESP}, #3", "stack frame, increase stack size by 12 B")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {TargetAssemblyRegisters.R1}, {TargetAssemblyRegisters.ESP}, #0", "stack frame, store r1")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {TargetAssemblyRegisters.R2}, {TargetAssemblyRegisters.ESP}, #1", "stack frame, store r2")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {TargetAssemblyRegisters.R3}, {TargetAssemblyRegisters.ESP}, #2", "stack frame, store r3")

    def handle_popa(self, matches: tuple[str]):
        self.writer.comment(matches[2])
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {TargetAssemblyRegisters.R3}, {TargetAssemblyRegisters.ESP}, #2", "stack frame, restore r3")
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {TargetAssemblyRegisters.R2}, {TargetAssemblyRegisters.ESP}, #1", "stack frame, restore r2")
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {TargetAssemblyRegisters.R1}, {TargetAssemblyRegisters.ESP}, #0", "stack frame, restore r1")
        self.writer.instruction(f"{TargetAssemblyInstructions.ADDI} {TargetAssemblyRegisters.ESP}, #3", "stack frame, decrease stack size by 12 B")

    def handle_memory_load(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}, #{matches[2] if matches[2] == '-' else ''}{matches[3]}", matches[5])

    def handle_global_variable_load(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.LOAD} {self.register_map[matches[0]]}, {TargetAssemblyRegisters.R0}, *d*{matches[1]}", matches[3])

    def handle_constant_move(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.LDI} {self.register_map[matches[0]]}, {matches[1]}", matches[3])

    def handle_register_move(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.MOV} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}", matches[3])

    def handle_memory_store(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {self.register_map[matches[3]]}, {self.register_map[matches[0]]}, #{matches[1] if matches[1] == '-' else ''}{matches[2]}", matches[5])

    def handle_global_variable_store(self, matches: tuple[str]):
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {self.register_map[matches[1]]}, {TargetAssemblyRegisters.R0}, *d*{matches[0]}", matches[3])
    
    def _handle_constant_ALU_instruction(self, matches: tuple[str], instruction: TargetAssemblyInstructions):
        self.writer.instruction(f"{instruction} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}, #{matches[2]}", matches[4])
    
    def _handle_register_ALU_instruction(self, matches: tuple[str], instruction: TargetAssemblyInstructions):
        self.writer.instruction(f"{instruction} {self.register_map[matches[0]]}, {self.register_map[matches[1]]}, {self.register_map[matches[2]]}", matches[4])

    def _function_call(self, matches: tuple[str]):
        self.writer.raw(f"{TargetAssemblyHelpers.CODE_LABEL} {matches[0]} {TargetAssemblyHelpers.SCOPE_OPEN}", matches[2])
        self.writer.instruction(f"{TargetAssemblyInstructions.SUBI} {TargetAssemblyRegisters.ESP}, #1", "return value, increase stack size by 4 B")
        self.writer.instruction(f"{TargetAssemblyInstructions.STORE} {TargetAssemblyRegisters.EDX}, {TargetAssemblyRegisters.ESP}, #0", "return value, store return address")

        
        