from typing import Callable
from enums import PushedTypes, RegisterStates, HighAssemblyInstructions
from constructs import Construct, Function, Variable, Constant, IntermediateResult, ReturnValue
from writer import Writer

class Register():
    def __init__(self, name: str, state: RegisterStates = RegisterStates.EMPTY) -> None:
        self.name = name
        self.state = state
        self.value = None
        self.usage = 0
        self.written = False
    
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
        self.written = False
        
class PushedValue():
    def __init__(self, esp_offset: int, intermediate_operand_number: int) -> None:
        if not isinstance(intermediate_operand_number, int):
            raise Exception("Only intermediate operands can be pushed.")
        self.value = intermediate_operand_number
        self.esp_offset = esp_offset
    
class RegisterFile():
    def __init__(self, number_of_registers: int, writer: Writer) -> None:
        if number_of_registers < 5:
            raise Exception("Number of registers must be at least 6.")
        self.number_of_registers = number_of_registers
        self.EAX = Register("eax", RegisterStates.USED)
        self.registers = [Register(f"r{i}") for i in range(2, number_of_registers - 1)]
        self.ESP = Register("esp", RegisterStates.USED)
        self.EBP = Register("ebp", RegisterStates.USED)
        self.EDX = Register("edx", RegisterStates.USED)
        self.writer = writer
        self.intermediate_results_counter = 0
        self.usage_counter = 0
        self.stack_offset = 0
        self.pushed_registers: list[PushedValue] = []
        self.used_registers_in_instruction: list[Register] = []
        self.last_assigned_register: Register = None

    def load_operand(self, operand: Variable|Constant|IntermediateResult, with_value = True) -> str:
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
                    self.writer.write_instruction(f"{HighAssemblyInstructions.MOV} {register.name} {operand.value}",
                                                  f"load constant")
                elif isinstance(operand, Variable) and with_value:
                    self.writer.write_instruction(f"{HighAssemblyInstructions.LOAD} {register.name} [{self.EBP.name}{operand.offset:+}]", 
                                                  f"load {operand.name}")

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
                        self.writer.write_instruction(f"{HighAssemblyInstructions.LOAD} {register.name} [{self.ESP.name}{self.stack_offset - pushed_register.esp_offset:+}]",
                                                      f"load intermediate_result_{operand.number}")
                        pushed_registers[0] = None
                    else:
                        self.writer.write_instruction(f"{HighAssemblyInstructions.LOAD} {register.name} [{self.ESP.name}{self.stack_offset - pushed_register.esp_offset:+}]",
                                                      f"load intermediate_result_{operand.number}")
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

    def get_return_value(self, function: Function, next_function_call: bool = False) -> str:
        if next_function_call:
            self.writer.write_instruction(f"{HighAssemblyInstructions.MOV} {self.EDX.name} {self.EAX.name}", f"{function.name}(...) return value temporary stored")
            return self.EDX.name
        else:
            return self.EAX.name
    
    def get_intermediate_result(self) -> str:
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
    
    def write_register(self, register_name: str):
        register = list(filter(lambda register: register.name == register_name, self.registers))[0]
        register.written = True
    
    def clear_last_instruction(self):
        for register in self.used_registers_in_instruction:
            register.clear()
        self.used_registers_in_instruction = []
        
    def expression_end(self):
        self.intermediate_results_counter = 0
        for register in self.registers:
            if isinstance(register.value, int):
                register.empty()
    
    def assign_return_register(self, intermediate_result_lookup: Callable[[int], IntermediateResult]):
        self.writer.write_instruction(f"{HighAssemblyInstructions.MOV} {self.EAX.name} {self.last_assigned_register.name}", 
                                      f"return {self.last_assigned_register.value.to_comment() if isinstance(self.last_assigned_register.value, Construct) else self.last_assigned_register.value}")
                                      #f"return {self.last_assigned_register.value.to_comment() if isinstance(self.last_assigned_register.value, Construct) else intermediate_result_lookup(self.last_assigned_register.value).to_comment()}")
    
    def create_stack_frame(self, number_of_variables: int):
        self.writer.write_instruction(f"{HighAssemblyInstructions.PUSH} {self.EBP.name}", "stack frame")
        self.writer.write_instruction(f"{HighAssemblyInstructions.MOV} {self.EBP.name} {self.ESP.name}", "stack frame")
        self.writer.write_instruction(f"{HighAssemblyInstructions.SUB} {self.ESP.name} {self.ESP.name} {number_of_variables}", "stack frame")

        # push general purpose registers
        for register in self.registers:
            self.stack_offset += 1
            self.writer.write_instruction(f"{HighAssemblyInstructions.PUSH} {register.name}", "stack frame")
    
    def destroy_stack_frame(self):
        # pop general purpose registers
        for register in reversed(self.registers):
            if isinstance(register.value, Variable) and register.written:
                self.writer.write_instruction(f"{HighAssemblyInstructions.STORE} [{self.EBP.name}{register.value.offset:+}] {register.name}", f"store {register.value.name}") 
            self.writer.write_instruction(f"{HighAssemblyInstructions.POP} {register.name}", "stack frame")
            register.empty()

        self.writer.write_instruction(f"{HighAssemblyInstructions.MOV} {self.ESP.name} {self.EBP.name}", "stack frame")
        self.writer.write_instruction(f"{HighAssemblyInstructions.POP} {self.EBP.name}", "stack frame")
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
            free_unwritten_registers = list(filter(lambda register: not register.written, free_registers))
            if len(free_unwritten_registers) > 0:
                return free_unwritten_registers[0]
            elif len(free_registers) > 0:
                free_register = free_registers[0]
                if isinstance(free_register.value, Variable):
                    self.writer.write_instruction(f"{HighAssemblyInstructions.STORE} [{self.EBP.name}{free_register.value.offset:+}] {free_register.name}",
                                                  f"store {free_register.value.name}")
                    free_register.written = False
                return free_register
            else:
                return None
            
    def _push_least_recently_used(self) -> Register:
        register = sorted(self.registers, key=lambda register: register.usage)[0]
        self.stack_offset += 1
        self.pushed_registers.append(PushedValue(self.stack_offset, register.value))
        self.writer.write_instruction(f"{HighAssemblyInstructions.PUSH} {register.name}", f"intermediate_result_{register.value}")
        return register
    
    def _clear_stack(self):
        cleared_counter = 0
        while len(self.pushed_registers) > 0 and self.pushed_registers[-1]:
            self.pushed_registers.pop()
            self.stack_offset -= 1
            cleared_counter += 1
        
        if cleared_counter > 0:
            self.writer.write_instruction(f"{HighAssemblyInstructions.ADD} {self.ESP.name} {self.ESP.name} {cleared_counter}", "stack cleared from intermediate results")
