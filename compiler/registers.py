from io import TextIOWrapper
import sys
from enums import PushedTypes, RegisterStates, HighAssemblyInstructions
from constructs import Variable, Constant, IntermediateResult, ReturnValue
from constants import HIGH_ASSEMBLY_INDENT

class Register():
    def __init__(self, name: str, state: RegisterStates = RegisterStates.EMPTY) -> None:
        self.name = name
        self.state = state
        self.value = None
        self.usage = 0
    
    def populate(self, value: Variable|Constant|int, usage: int):
        self.value = value
        self.usage = usage
        self.state = RegisterStates.USED
    
    def clear(self):
        self.state = RegisterStates.FREE
    
    def empty(self):
        self.state = RegisterStates.EMPTY
        self.value = None
        self.usage = 0
        
class PushedValue():
    def __init__(self, esp_offset: int, type: PushedTypes, value: int|None) -> None:
        self.value = value
        self.esp_offset = esp_offset
        self.type = type
    
class RegisterFile():
    def __init__(self, number_of_registers: int, output_file: TextIOWrapper = sys.stdout) -> None:
        if number_of_registers < 5:
            raise Exception("Number of registers must be at least 6.")
        self.number_of_registers = number_of_registers
        self.EAX = Register("eax", RegisterStates.USED)
        self.registers = [Register(f"r{i}") for i in range(2, number_of_registers - 1)]
        self.ESP = Register("esp", RegisterStates.USED)
        self.EBP = Register("ebp", RegisterStates.USED)
        self.output_file = output_file
        self.intermediate_results_counter = 0
        self.usage_counter = 0
        self.stack_offset = 0
        self.pushed_registers: list[PushedValue] = []
        self.used_registers_in_instruction: list[Register] = []
        self.last_assigned_register: Register = None

    def load_operand(self, operand: Variable|Constant|IntermediateResult|ReturnValue) -> str:
        if isinstance(operand, Constant) or isinstance(operand, Variable):
            already_loaded_registers = list(filter(lambda register: register.value == operand, self.registers))
            if len(already_loaded_registers) > 0:
                register = already_loaded_registers[0]
            else:
                register = self._free_or_empty_register()
                if register is None:
                    register = self._push_least_recently_used()
                    
                register.populate(operand, self.usage_counter)
                self.usage_counter += 1
            
                if isinstance(operand, Constant):
                    print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.MOV} {register.name} {operand.value}", file=self.output_file)
                elif isinstance(operand, Variable):
                    print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.LOAD} {register.name} [{self.EBP.name}{operand.offset:+}]", file=self.output_file)

            self.used_registers_in_instruction.append(register)
            self.last_assigned_register = register
            return register.name
        
        elif isinstance(operand, IntermediateResult):
            intermediate_registers = list(filter(lambda register: register.value == operand.number, self.registers))
            if len(intermediate_registers) == 0:
                pushed_registers = list(filter(lambda pushed_register: pushed_register.value == operand.number, self.pushed_registers))
                if len(pushed_registers):
                    pushed_register = pushed_registers[0]
                    register = self._free_or_empty_register()
                    if register is None:
                        register = self._push_least_recently_used()
                        print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.LOAD} {register.name} [{self.ESP.name}{self.stack_offset - pushed_register.esp_offset:+}]", file=self.output_file)
                        pushed_registers[0] = None
                    else:
                        print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.LOAD} {register.name} [{self.ESP.name}{self.stack_offset - pushed_register.esp_offset:+}]", file=self.output_file)
                        pushed_registers[0] = None
                        self._clear_stack()
                else:
                    raise Exception("Intermediate result not found in registers nor stack.")
            elif len(intermediate_registers) == 1:
                register = intermediate_registers[0]
            else:
                raise Exception("Too many same intermediate results in registers.")
            
            self.used_registers_in_instruction.append(register)
            self.last_assigned_register = register
            return register.name
        
        elif isinstance(operand, ReturnValue):
            return self.EAX.name

    def store_result(self) -> str:
        for register in self.used_registers_in_instruction:
            register.clear()
        self.used_registers_in_instruction = []

        register = self._free_or_empty_register()
        if register is None:
            register = self._push_least_recently_used()
                        
        register.populate(self.intermediate_results_counter, self.usage_counter)
        self.intermediate_results_counter += 1
        self.usage_counter += 1

        self.last_assigned_register = register
        return register.name
    
    def clear_last_instruction(self):
        for register in self.used_registers_in_instruction:
            register.clear()
        self.used_registers_in_instruction = []
    
    def push_function_parameter(self, parameter: str):
        self.stack_offset += 1
        self.pushed_registers.append(PushedValue(self.stack_offset, PushedTypes.FUNCTION_PARAMETER))
        print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.PUSH} {parameter}", file=self.output_file)
    
    def expression_end(self):
        self.intermediate_results_counter = 0
        for register in self.registers:
            if isinstance(register.value, int):
                register.empty()
    
    def assign_return_register(self):
        print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.MOV} {self.EAX.name} {self.last_assigned_register.name}", file=self.output_file)
    
    def create_stack_frame(self, number_of_variables: int):
        print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.PUSH} {self.EBP.name}", file=self.output_file)
        print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.MOV} {self.EBP.name} {self.ESP.name}", file=self.output_file)
        print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.SUB} {self.ESP.name} {self.ESP.name} {number_of_variables}", file=self.output_file)

        # push general purpose registers
        for register in self.registers:
            self.stack_offset += 1
            print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.PUSH} {register.name}", file=self.output_file)
    
    def destroy_stack_frame(self):
        # pop general purpose registers
        for register in reversed(self.registers):
            if isinstance(register.value, Variable):
                print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.STORE} [{self.EBP.name}{register.value.offset:+}] {register.name}", file=self.output_file) 
            print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.POP} {register.name}", file=self.output_file)
            register.empty()

        print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.MOV} {self.ESP.name} {self.EBP.name}", file=self.output_file)
        print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.POP} {self.EBP.name}", file=self.output_file)
        self.usage_counter = 0
        self.intermediate_results_counter = 0
        self.stack_offset = 0

    def _free_or_empty_register(self) -> Register|None:
        empty_registers = list(filter(lambda register: register.state == RegisterStates.EMPTY, self.registers))
        if len(empty_registers) > 0:
            return empty_registers[0]
        else:
            free_registers = list(filter(lambda register: register.state == RegisterStates.FREE, self.registers))
            free_registers = sorted(free_registers, key=lambda register: register.usage)
            if len(free_registers) > 0:
                free_register = free_registers[0]
                if isinstance(free_register.value, Variable):
                    print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.STORE} [{self.EBP.name}{free_register.value.offset:+}] {free_register.name}", file=self.output_file)
                return free_register
            else:
                return None
            
    def _push_least_recently_used(self) -> Register:
        register = sorted(self.registers, key=lambda register: register.usage)[0]
        self.stack_offset += 1
        self.pushed_registers.append(PushedValue(self.stack_offset, PushedTypes.SAVED_REGISTER, register.value))
        print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.PUSH} {register.name}", file=self.output_file)
        return register
    
    def _clear_stack(self):
        cleared_counter = 0
        while len(self.pushed_registers) > 0 and self.pushed_registers[-1]:
            self.pushed_registers.pop()
            self.stack_offset -= 1
            cleared_counter += 1
        
        if cleared_counter > 0:
            print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.ADD} {self.ESP.name} {self.ESP.name} {cleared_counter}", file=self.output_file)
