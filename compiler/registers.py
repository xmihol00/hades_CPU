from typing import Callable
from enums import RegisterStates, HighAssemblyInstructions, Types
from constructs import Construct, Function, Variable, Constant, IntermediateResult, ReturnValue
from writer import Writer

class Register():
    def __init__(self, name: str, state: RegisterStates = RegisterStates.EMPTY) -> None:
        self.name = name
        self.state = state
        self.value = None
        self.usage = 0
        self.written = False
    
    def populate(self, value: Variable|Constant|IntermediateResult, usage: int):
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
            
class RegisterFile():
    def __init__(self, number_of_registers: int, writer: Writer) -> None:
        if number_of_registers < 7:
            raise Exception("Number of registers must be at least 7.")
        self.number_of_registers = number_of_registers
        self.registers = [Register(f"r{i}") for i in range(1, number_of_registers - 3)]
        self.EAX = Register("eax", RegisterStates.USED)
        self.EDX = Register("edx", RegisterStates.USED)
        self.ESP = Register("esp", RegisterStates.USED)
        self.EBP = Register("ebp", RegisterStates.USED)
        self.writer = writer
        self.intermediate_results_counter = 0
        self.usage_counter = 0
        self.used_registers_in_instruction: list[Register] = []
        self.last_assigned_register: Register = None
        self.register_string = ", ".join([register.name for register in self.registers][:-1]) + " and " + self.registers[-1].name
        self.register_string_reversed = ", ".join([register.name for register in reversed(self.registers[1:])]) + " and " + self.registers[0].name

    def load_operand(self, operand: Variable|Constant|IntermediateResult, with_value = True) -> Register:
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
                    self.writer.instruction(f"{HighAssemblyInstructions.MOV} {register.name} {operand.value}", f"{register.name} = {operand.value}")
                elif isinstance(operand, Variable) and with_value:
                    if operand.stack_offset:
                        if operand.type == Types.INT:
                            self.writer.instruction(f"{HighAssemblyInstructions.LOAD} {register.name} [{self.EBP.name}{operand.stack_offset:+}]", f"{register.name} = {operand.name}")
                        elif operand.type == Types.PTR:
                            self.writer.instruction(f"{HighAssemblyInstructions.MOV} {register.name} {self.EBP.name}", f"get base address of {operand.name}")
                            self.writer.instruction(f"{HighAssemblyInstructions.ADD} {register.name} {register.name} {operand.stack_offset}", f"add stack offset of {operand.name}")
                    else:
                        if operand.type == Types.INT:
                            self.writer.instruction(f"{HighAssemblyInstructions.LOAD} {register.name} {operand.label}", f"{register.name} = {operand.name}")
                        elif operand.type == Types.PTR:
                            self.writer.instruction(f"{HighAssemblyInstructions.MOV} {register.name} {operand.label}", f"{register.name} = &{operand.name}")

            self.used_registers_in_instruction.append(register)
            self.last_assigned_register = register
            return register
              
        elif isinstance(operand, IntermediateResult):
            intermediate_registers = list(filter(lambda register: isinstance(register.value, IntermediateResult) and register.value.number == operand.number, self.registers))
            if len(intermediate_registers) == 0:
                register = self._free_or_empty_register()
                if register is None:
                    raise Exception("No free or empty register found.")
                else:
                    self.writer.instruction(f"{HighAssemblyInstructions.POP} {register.name}", f"pop {operand.comment}")
            elif len(intermediate_registers) == 1:
                register = intermediate_registers[0]
            else:
                raise Exception("Too many same intermediate results in registers.")
            
            self.used_registers_in_instruction.append(register)
            self.last_assigned_register = register
            return register

    def get_return_value(self, function: Function, next_function_call: bool = False) -> Register|None:
        if next_function_call: # two functions are called in a singe instruction, first result must be stored in EDX
            self.writer.instruction(f"{HighAssemblyInstructions.STORE} [{self.EBP.name}-1] {self.EAX.name}", f"temporary storing {function.name}(...) return value")
            return None
        else:
            self.last_assigned_register = self.EAX
            return self.EAX
    
    def resolve_register_names(self, register_names: list[str]):
        for i, register_name in enumerate(register_names):
            if register_name is None:
                self.writer.instruction(f"{HighAssemblyInstructions.LOAD} {self.EDX.name} [{self.EBP.name}-1]", f"loading temporary stored return value")
                register_names[i] = self.EDX.name
                return
    
    def get_for_intermediate_result(self) -> Register:
        for register in self.used_registers_in_instruction: # allow registers used in last instruction to be used again
            if not isinstance(register.value, IntermediateResult) or not register.value.address_register:
                register.clear()
        self.used_registers_in_instruction = []

        register = self._free_or_empty_register()
        if register is None: # no empty register, some must be pushed to the stack
            register = self._push_least_recently_used()
        
        intermediate_result = IntermediateResult(self.intermediate_results_counter)
        register.populate(intermediate_result, self.usage_counter)
        self.intermediate_results_counter += 1
        self.usage_counter += 1

        self.last_assigned_register = register
        return register
    
    def written_intermediate_result(self, intermediate_result_register: Register, address_register: Register):
        intermediate_result_register.value.address_register = address_register
    
    def write_register(self, register_name: str):
        register = list(filter(lambda register: register.name == register_name, self.registers))[0]
        register.written = True # mark register as written to update value of the underlying variable when it will be cleared
    
    def clear_last_instruction(self):
        for register in self.used_registers_in_instruction: # allow registers used in last instruction to be used again
            register.clear()
        self.used_registers_in_instruction = []
        
    def expression_end(self):
        self.intermediate_results_counter = 0
        for register in self.registers:
            if isinstance(register.value, IntermediateResult): # invalidate all intermediate results
                if register.value.address_register:
                    self.writer.instruction(f"{HighAssemblyInstructions.STORE} [{register.value.address_register.name}] {register.name}", f"store *{register.value.address_register.value.name}") 
                register.empty()
    
    def assign_return_register(self, intermediate_result_lookup: Callable[[int], IntermediateResult]):
        # if-elif is here just to print a comment in the assembly code, it does not affect the code itself
        if isinstance(self.last_assigned_register.value, IntermediateResult):
            intermediate_result = intermediate_result_lookup(self.last_assigned_register.value.number)
            if intermediate_result:
                return_comment = f"return {intermediate_result.comment}"
            else:
                return_comment = f"return {self.last_assigned_register.name}"
        elif isinstance(self.last_assigned_register.value, Construct):
            return_comment = f"return {self.last_assigned_register.value.comment}"
        
        if self.last_assigned_register.name == self.EAX.name:
            self.writer.comment("return value already in EAX")
        else:
            self.writer.instruction(f"{HighAssemblyInstructions.MOV} {self.EAX.name} {self.last_assigned_register.name}", return_comment)
        
    def create_stack_frame(self, number_of_variables: int):
        self.writer.instruction(f"{HighAssemblyInstructions.PUSH} {self.EBP.name}", "stack frame, store base pointer")
        self.writer.instruction(f"{HighAssemblyInstructions.MOV} {self.EBP.name} {self.ESP.name}", "stack frame, set base pointer")
        if number_of_variables > 0: # space for local variables
            self.writer.instruction(f"{HighAssemblyInstructions.SUB} {self.ESP.name} {self.ESP.name} {number_of_variables}", "stack frame, space for local variables and temporary return value")

        self.writer.instruction(f"{HighAssemblyInstructions.PUSHA}", f"stack frame, push {self.register_string}")
    
    def destroy_stack_frame(self):
        self.writer.instruction(f"{HighAssemblyInstructions.POPA}", f"stack frame, pop {self.register_string_reversed}")
        self.writer.instruction(f"{HighAssemblyInstructions.MOV} {self.ESP.name} {self.EBP.name}", "stack frame, restore stack pointer")
        self.writer.instruction(f"{HighAssemblyInstructions.POP} {self.EBP.name}", "stack frame, restore base pointer")
        self.usage_counter = 0
        self.intermediate_results_counter = 0
        self.stack_offset = 0
    
    def store_written(self):
        for register in self.registers:
            if isinstance(register.value, Variable) and register.written:
                if register.value.global_scope:
                    self.writer.instruction(f"{HighAssemblyInstructions.STORE} {register.value.label} {register.name}", f"store {register.value.name}")
                else:
                    self.writer.instruction(f"{HighAssemblyInstructions.STORE} [{self.EBP.name}{register.value.stack_offset:+}] {register.name}", f"store {register.value.name}") 
                register.empty()
    
    def store_global_variables(self):
        for register in self.registers:
            if isinstance(register.value, Variable) and register.written:
                if register.value.global_scope:
                    self.writer.instruction(f"{HighAssemblyInstructions.STORE} {register.value.label} {register.name}", f"store {register.value.name}")
                register.empty()
    
    def get_EAX(self) -> str:
        return self.EAX.name
    
    def invalidate(self):
        for register in self.registers:
            register.empty()

    def _free_or_empty_register(self) -> Register|None:
        empty_registers = list(filter(lambda register: register.state == RegisterStates.EMPTY, self.registers))
        if len(empty_registers) > 0: # first try empty registers
            return empty_registers[0] 
        else:
            free_registers = list(filter(lambda register: register.state == RegisterStates.FREE, self.registers))
            free_registers = sorted(free_registers, key=lambda register: register.usage)
            free_unwritten_registers = list(filter(lambda register: not register.written, free_registers))
            if len(free_unwritten_registers) > 0: # then try free registers that are not written
                return free_unwritten_registers[0]
            elif len(free_registers) > 0: # then try any free registers
                free_register = free_registers[0]
                if isinstance(free_register.value, Variable) and free_register.written:
                    if free_register.value.global_scope:
                        self.writer.instruction(f"{HighAssemblyInstructions.STORE} {free_register.value.label} {free_register.name}", f"store {free_register.value.name}")
                    else:
                        self.writer.instruction(f"{HighAssemblyInstructions.STORE} [{self.EBP.name}{free_register.value.stack_offset:+}] {free_register.name}", f"store {free_register.value.name}") 
                    free_register.empty()
                return free_register
            else:
                return None
            
    def _push_least_recently_used(self) -> Register:
        register = sorted(self.registers, key=lambda register: register.usage)[0] # select the least recently used intermediate result
        self.writer.instruction(f"{HighAssemblyInstructions.PUSH} {register.name}", f"push {register.name}")
        return register
