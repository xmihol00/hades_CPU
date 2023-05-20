from writer import Writer
from enums import InternalAlphabet, Keywords, Operators, HighAssemblyInstructions
from constructs import Function, IntermediateResult, ReturnValue, Variable, Constant
from registers import RegisterFile
from function_declaration_table import FunctionDeclarationTable
from variable_table import VariableTable

FIRST_OPERAND_OPERATORS = [
    Operators.LOGICAL_NOT,
    Operators.BITWISE_NOT,
    Operators.UNARY_PLUS,
    Operators.UNARY_MINUS,
    Operators.PARAMETER_ASSIGNMENT
]

SECOND_OPERAND_OPERATORS = [
]

BOTH_OPERAND_OPERATORS = [
    Operators.MULTIPLY,
    Operators.PLUS,
    Operators.MINUS,
    Operators.RIGHT_SHIFT,
    Operators.LEFT_SHIFT,
    Operators.RIGHT_ROTATION_SHIFT,
    Operators.LEFT_ROTATION_SHIFT,
    Operators.LOGICAL_LESS,
    Operators.LOGICAL_LESS_OR_EQUAL,
    Operators.LOGICAL_GREATER,
    Operators.LOGICAL_GREATER_OR_EQUAL,
    Operators.LOGICAL_EQUAL,
    Operators.LOGICAL_NOT_EQUAL,
    Operators.BITWISE_AND,
    Operators.BITWISE_XOR,
    Operators.BITWISE_OR,
    Operators.LOGICAL_AND,
    Operators.LOGICAL_OR,
    Operators.ASSIGNMENT,
]

INTERMEDIATE_RESULT_OPERATORS = [
    Operators.MULTIPLY,
    Operators.PLUS,
    Operators.MINUS,
    Operators.RIGHT_SHIFT,
    Operators.LEFT_SHIFT,
    Operators.RIGHT_ROTATION_SHIFT,
    Operators.LEFT_ROTATION_SHIFT,
    Operators.LOGICAL_LESS,
    Operators.LOGICAL_LESS_OR_EQUAL,
    Operators.LOGICAL_GREATER,
    Operators.LOGICAL_GREATER_OR_EQUAL,
    Operators.LOGICAL_EQUAL,
    Operators.LOGICAL_NOT_EQUAL,
    Operators.BITWISE_AND,
    Operators.BITWISE_XOR,
    Operators.BITWISE_OR,
    Operators.LOGICAL_AND,
    Operators.LOGICAL_OR,
    Operators.LOGICAL_NOT,
    Operators.BITWISE_NOT,
    Operators.UNARY_PLUS,
    Operators.UNARY_MINUS
]

class HighAssemblyGenerator():
    def __init__(self, function_declaration_table: FunctionDeclarationTable, variable_table: VariableTable, 
                register_file: RegisterFile, writer: Writer) -> None:
        self.function_declaration_table = function_declaration_table
        self.variable_table = variable_table
        self.register_file = register_file
        self.writer = writer
        self.register_index = 0
        self.registers = ["", ""]
        self.return_expression = False
        self.intermediate_result_counter = 0
        
    def generate(self):
        for function in self.function_declaration_table.functions.values():
            self.writer.write_label(function.name)
            self.register_file.create_stack_frame(self.variable_table.number_of_variables_in_function(function.name) - function.number_of_parameters)
            self._generate_function(function)
            self.writer.new_line()
            self.intermediate_result_counter = 0
    
    def _generate_function(self, function: Function):
        for i, command in enumerate(function.body):
            if isinstance(command, Variable) or isinstance(command, IntermediateResult):
                self.registers[self.register_index] = self.register_file.load_operand(command, function.body[i + 2] != Operators.ASSIGNMENT)
                self.register_index += 1
            
            elif isinstance(command, Constant):
                if function.body[i + 1] == Operators.PARAMETER_ASSIGNMENT:
                    self.registers[self.register_index] = command.value
                elif self.register_index == 0:
                    self.registers[self.register_index] = self.register_file.load_operand(command)
                else:
                    self.registers[self.register_index] = command.value
                self.register_index += 1

            elif isinstance(command, ReturnValue):
                self.writer.write_instruction(f"{HighAssemblyInstructions.CALL} {command.function.name}", command.function.to_comment())
                self.registers[self.register_index] = self.register_file.get_return_value(command.function, isinstance(function.body[i + 1], ReturnValue))
                self.register_index += 1

            elif isinstance(command, Operators):
                if command in INTERMEDIATE_RESULT_OPERATORS:
                    result_register = self.register_file.get_intermediate_result()
                    if command in FIRST_OPERAND_OPERATORS:
                        self.writer.write_instruction(f"{command.to_high_assembly_instruction()} {result_register} {self.registers[0]}", 
                                                      f"intermediate_result_{self.intermediate_result_counter} = {command.value.replace('U', '')}{function.body[i - 1].to_comment()}")
                        self._set_intermediate_result_comment(function, i + 1, f"{command.value.replace('U', '')}{function.body[i - 1].to_comment()}")
                    elif command in BOTH_OPERAND_OPERATORS:
                        self.writer.write_instruction(f"{command.to_high_assembly_instruction()} {result_register} {self.registers[0]} {self.registers[1]}",
                                                      f"intermediate_result_{self.intermediate_result_counter} = {function.body[i - 2].to_comment()} {command.value} {function.body[i - 1].to_comment()}")
                        self._set_intermediate_result_comment(function, i + 1, f"{function.body[i - 2].to_comment()} {command.value} {function.body[i - 1].to_comment()}")
                    self.intermediate_result_counter += 1

                else:
                    self.register_file.clear_last_instruction()
                    if command in FIRST_OPERAND_OPERATORS:
                       self.writer.write_instruction(f"{command.to_high_assembly_instruction()} {self.registers[0]}", f"push {function.body[i - 1].to_comment()}")
                    elif command in BOTH_OPERAND_OPERATORS:
                       self.writer.write_instruction(f"{command.to_high_assembly_instruction()} {self.registers[0]} {self.registers[1]}",
                                                     f"{function.body[i - 2].to_comment()} {command.value} {function.body[i - 1].to_comment()}")
                       if command == Operators.ASSIGNMENT:
                           self.register_file.write_register(self.registers[0])

                self.register_index = 0
                    
            elif isinstance(command, InternalAlphabet):
                if command == InternalAlphabet.EXPRESSION_END:
                    if self.return_expression:
                        self.return_expression = False
                        self.register_file.assign_return_register(lambda x: self._find_intermediate_result(function, i, x))
                        self.register_file.destroy_stack_frame()
                        self.writer.write_instruction(f"{HighAssemblyInstructions.RETURN} {function.number_of_parameters}")
                    self.register_file.expression_end()
                    self.intermediate_result_counter = 0
            
            elif isinstance(command, Keywords):
                if command == Keywords.RETURN:
                    self.return_expression = True
                    self.register_index = 0
    
    def _set_intermediate_result_comment(self, function: Function, function_index: int, comment: str):
        for command in function.body[function_index:]:
            if isinstance(command, IntermediateResult) and command.number == self.intermediate_result_counter:
                command.set_comment(comment)
                return
    
    def _find_intermediate_result(self, function: Function, function_index: int, number: int) -> IntermediateResult:
        for command in reversed(function.body[:function_index + 1]):
            if isinstance(command, IntermediateResult) and command.number == number:
                return command
        return None
        
