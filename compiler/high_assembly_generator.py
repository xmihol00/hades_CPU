from io import TextIOWrapper
from constants import HIGH_ASSEMBLY_INDENT
from enums import InternalAlphabet, Keywords, Operators, HighAssemblyInstructions
from constructs import Function, IntermediateResult, ReturnValue, Variable, Constant
import sys
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
                register_file: RegisterFile, output_file: TextIOWrapper = sys.stdout) -> None:
        self.function_declaration_table = function_declaration_table
        self.variable_table = variable_table
        self.register_file = register_file
        self.output_file = output_file
        self.register_index = 0
        self.registers = ["", ""]
        self.return_expression = False
        
    def generate(self):
        for function in self.function_declaration_table.functions.values():
            print(f"{function.name}:", file=self.output_file)
            self.register_file.create_stack_frame(self.variable_table.number_of_variables_in_function(function.name) - len(function.parameters))
            self._generate_function(function)
            print(file=self.output_file)
    
    def _generate_function(self, function: Function):
        for i, command in enumerate(function.body):
            if isinstance(command, Variable) or isinstance(command, Constant) or isinstance(command, IntermediateResult):
                self.registers[self.register_index] = self.register_file.load_operand(command)
                self.register_index += 1

            elif isinstance(command, ReturnValue):
                print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.CALL} {command.function.name}", file=self.output_file)
                self.registers[self.register_index] = self.register_file.load_operand(command)
                self.register_index += 1

            elif isinstance(command, Operators):
                if command in INTERMEDIATE_RESULT_OPERATORS:
                    result_register = self.register_file.store_result()
                    if command in FIRST_OPERAND_OPERATORS:
                        print(f"{HIGH_ASSEMBLY_INDENT}{command.to_high_assembly_instruction()} {result_register} {self.registers[0]}", file=self.output_file)
                    elif command in BOTH_OPERAND_OPERATORS:
                        print(f"{HIGH_ASSEMBLY_INDENT}{command.to_high_assembly_instruction()} {result_register} {self.registers[0]} {self.registers[1]}", file=self.output_file)
                else:
                    self.register_file.clear_last_instruction()
                    if command in FIRST_OPERAND_OPERATORS:
                       print(f"{HIGH_ASSEMBLY_INDENT}{command.to_high_assembly_instruction()} {self.registers[0]}", file=self.output_file)
                    elif command in BOTH_OPERAND_OPERATORS:
                       print(f"{HIGH_ASSEMBLY_INDENT}{command.to_high_assembly_instruction()} {self.registers[0]} {self.registers[1]}", file=self.output_file)

                self.register_index = 0
                    

            elif isinstance(command, InternalAlphabet):
                if command == InternalAlphabet.EXPRESSION_END:
                    if self.return_expression:
                        self.return_expression = False
                        self.register_file.assign_return_register()
                        self.register_file.destroy_stack_frame()
                        print(f"{HIGH_ASSEMBLY_INDENT}{HighAssemblyInstructions.RETURN}", file=self.output_file)
                    self.register_file.expression_end()
            
            elif isinstance(command, Keywords):
                if command == Keywords.RETURN:
                    self.return_expression = True
                    self.register_index = 0
