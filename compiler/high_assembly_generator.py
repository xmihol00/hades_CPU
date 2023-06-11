from global_expressions import GlobalExpressions
from writer import Writer
from enums import InternalAlphabet, Keywords, Operators, HighAssemblyInstructions, Types
from constructs import Function, IntermediateResult, ReturnValue, Variable, Constant
from registers import Register, RegisterFile
from function_declaration_table import FunctionDeclarationTable
from variable_table import VariableTable

FIRST_OPERAND_OPERATORS = [
    Operators.LOGICAL_NOT,
    Operators.BITWISE_NOT,
    Operators.UNARY_MINUS,
    Operators.PARAMETER_ASSIGNMENT
]

INDIRECT_MEMORY_OPERATORS = [
    Operators.DEREFERENCE,
    Operators.ASSIGNMENT_DEREFERENCE
]

SPECIAL_OPERATORS = [
    Operators.UNARY_PLUS
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
    Operators.OFFSET_DEREFERENCE,
    Operators.OFFSET_ASSIGNMENT_DEREFERENCE
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
    Operators.UNARY_MINUS,
    Operators.DEREFERENCE,
    Operators.ASSIGNMENT_DEREFERENCE,
    Operators.OFFSET_DEREFERENCE,
    Operators.OFFSET_ASSIGNMENT_DEREFERENCE
]

class HighAssemblyGenerator():
    def __init__(self, function_declaration_table: FunctionDeclarationTable, variable_table: VariableTable, global_code: GlobalExpressions,
                register_file: RegisterFile, writer: Writer) -> None:
        self.function_declaration_table = function_declaration_table
        self.variable_table = variable_table
        self.global_code = global_code
        self.register_file = register_file
        self.writer = writer

        # state variables
        self.register_index = 0
        self.registers: list[Register] = [None, None]
        self.register_names: list[str] = [None, None]
        self.return_expression = False
        self.intermediate_result_counter = 0
        self.scope_index = -1
        self.if_scope_ids = []
        self.while_scope_ids = []
        self.for_scope_ids = []
        self.current_jump_statement = None
        self.jump_statement_stack = []
        self.else_if_counter = 0
        self.else_if_counter_stack = []
        self.for_part1 = False
        self.for_part2 = False
        self.for_part3 = False
        self.current_for_last_statement = []
        self.for_last_statement_stack = []
        self.array_assignment = False
        
    def generate(self):
        for global_command in self.global_code.expressions: # FIXME: quite ugly solution
            if isinstance(global_command, Variable):
                variable = global_command
            elif isinstance(global_command, Constant):
                self.writer.raw(f"{variable.label}: {global_command.value}", f"global constant {variable.name}")
        self.writer.new_line()

        for function in self.function_declaration_table.functions.values():
            if len(function.body) > 0:
                function: Function = function
                self.writer.label(f"${function.name}", f"{function.pretty_comment()}")
                self.register_file.create_stack_frame(function.stack_size())
                self._generate_function(function)
                self.writer.new_line()

                # reset state
                self.register_index = 0
                self.registers = [None, None]
                self.register_names = [None, None]
                self.return_expression = False
                self.intermediate_result_counter = 0
                self.scope_index = -1
                self.if_scope_ids = []
                self.while_scope_ids = []
                self.for_scope_ids = []
                self.current_jump_statement = None
                self.jump_statement_stack = []
                self.else_if_counter = 0
                self.else_if_counter_stack = []
                self.for_part1 = False
                self.for_part2 = False
                self.for_part3 = False
                self.current_for_last_statement = []
                self.for_last_statement_stack = []
                self.array_assignment = False
    
    def _generate_function(self, function: Function):
        for i, command in enumerate(function.body):
            if self.for_part3:
                if command == InternalAlphabet.SCOPE_INCREMENT:
                    self.for_part3 = False
                    self.for_last_statement_stack.append(self.current_for_last_statement)
                    self.current_for_last_statement = []
                else:
                    self.current_for_last_statement.append((i, command))
                    continue

            if isinstance(command, Variable) or isinstance(command, IntermediateResult):
                self._handle_variable_or_intermediate_result(command, function, i)
            elif isinstance(command, Constant):
                self._handle_constant(command, function, i)
            elif isinstance(command, ReturnValue):
                self._handle_return_value(command, function, i)
            elif isinstance(command, Operators):
                self._handle_operator(command, function, i)
            elif isinstance(command, InternalAlphabet):
                self._handle_internal_alphabet(command, function, i)
            elif isinstance(command, Keywords):
                self._handle_keyword(command, function, i)

    def _handle_variable_or_intermediate_result(self, command: Variable|IntermediateResult, function: Function, i: int):
        self.registers[self.register_index] = self.register_file.load_operand(command, function.body[i + 2] != Operators.ASSIGNMENT)
        self.register_names[self.register_index] = self.registers[self.register_index].name
        self.register_index += 1

    def _handle_constant(self, command: Constant, function: Function, i: int):
        if function.body[i + 1] == Operators.PARAMETER_ASSIGNMENT:
            self.register_names[self.register_index] = command.value
        elif self.register_index == 0:
            self.registers[self.register_index] = self.register_file.load_operand(command)
            self.register_names[self.register_index] = self.registers[self.register_index].name
        else:
            self.register_names[self.register_index] = command.value
        self.register_index += 1

    def _handle_return_value(self, command: ReturnValue, function: Function, i: int):
        self.writer.instruction(f"{HighAssemblyInstructions.CALL} {command.function.name}", command.function.comment)
        self.registers[self.register_index] = self.register_file.get_return_value(command.function, isinstance(function.body[i + 1], ReturnValue))
        self.register_names[self.register_index] = self.registers[self.register_index].name if self.registers[self.register_index] else None
        self.register_index += 1

    def _handle_operator(self, command: Operators, function: Function, i: int):
        self.register_file.resolve_register_names(self.register_names)
        # TODO: refactor - reduce duplicate code
        if command in INTERMEDIATE_RESULT_OPERATORS:
            result_register = self.register_file.get_for_intermediate_result()
            if command in FIRST_OPERAND_OPERATORS:
                self.writer.instruction(f"{command.to_high_assembly_instruction()} {result_register.name} {self.register_names[0]}", 
                                        f"{result_register.name} = {command.value.replace('U', '')}{function.body[i - 1].comment}")
                self._set_intermediate_result_comment(function, i + 1, f"{command.value.replace('U', '')}{function.body[i - 1].comment}")
            elif command in BOTH_OPERAND_OPERATORS:
                if command == Operators.OFFSET_DEREFERENCE:
                    self.writer.instruction(f"{command.to_high_assembly_instruction()} {result_register.name} {self.register_names[0]} {self.register_names[1]}",
                                            f"{result_register.name} = {function.body[i - 2].comment} + {function.body[i - 1].comment}")
                    self.writer.instruction(f"{HighAssemblyInstructions.LOAD} {result_register.name} [{result_register.name}]",
                                            f"{result_register.name} = {function.body[i - 2].comment}[{function.body[i - 1].comment}]")
                    self._set_intermediate_result_comment(function, i + 1, f"{function.body[i - 2].comment}[{function.body[i - 1].comment}]")
                else:
                    if command == Operators.OFFSET_ASSIGNMENT_DEREFERENCE:
                        command = Operators.PLUS
                        self.array_assignment = True
                    self.writer.instruction(f"{command.to_high_assembly_instruction()} {result_register.name} {self.register_names[0]} {self.register_names[1]}",
                                            f"{result_register.name} = {function.body[i - 2].comment} {command.value} {function.body[i - 1].comment}")
                    self._set_intermediate_result_comment(function, i + 1, f"{function.body[i - 2].comment} {command.value} {function.body[i - 1].comment}")
                    
            elif command in INDIRECT_MEMORY_OPERATORS:
                if command == Operators.ASSIGNMENT_DEREFERENCE:
                    self.array_assignment = True
                    self.writer.instruction(f"{Operators.ASSIGNMENT.to_high_assembly_instruction()} {result_register.name} {self.register_names[0]}", 
                                            f"{result_register.name} = *{function.body[i - 1].comment}")
                else:
                    self.writer.instruction(f"{command.to_high_assembly_instruction()} {result_register.name} [{self.register_names[0]}]", 
                                            f"{result_register.name} = *{function.body[i - 1].comment}")
                self._set_intermediate_result_comment(function, i + 1, f"*{function.body[i - 1].comment}", False)
            elif command == Operators.UNARY_PLUS:
                self.writer.instruction(f"{command.to_high_assembly_instruction()} {result_register.name} {self.register_names[0]} 0", 
                                        f"{command.value.replace('U', '')}{function.body[i - 1].comment} - dummy")
                self._set_intermediate_result_comment(function, i + 1, f"{command.value.replace('U', '')}{function.body[i - 1].comment} - dummy")
            self.intermediate_result_counter += 1
        else:
            self.register_file.clear_last_instruction()
            if command in FIRST_OPERAND_OPERATORS: # currently only PUSH
                self.writer.instruction(f"{command.to_high_assembly_instruction()} {self.register_names[0]}", f"push {function.body[i - 1].comment}")
            elif command in BOTH_OPERAND_OPERATORS:
                if command == Operators.ASSIGNMENT and self.array_assignment:
                    self.array_assignment = False
                    self.writer.instruction(f"{HighAssemblyInstructions.STORE} [{self.register_names[0]}] {self.register_names[1]}",
                                            f"{function.body[i - 2].comment} {command.value} {function.body[i - 1].comment}")
                else:
                    self.writer.instruction(f"{command.to_high_assembly_instruction()} {self.register_names[0]} {self.register_names[1]}",
                                            f"{function.body[i - 2].comment} {command.value} {function.body[i - 1].comment}")
                    if command == Operators.ASSIGNMENT:
                        self.register_file.write_register(self.register_names[0])

        self.register_index = 0

    def _handle_internal_alphabet(self, command: InternalAlphabet, function: Function, i: int):
        if command == InternalAlphabet.EXPRESSION_END:
            if self.return_expression:
                self.return_expression = False
                self.register_file.assign_return_register(lambda x: self._find_intermediate_result(function, i, x))
                self.register_file.store_global_variables()
                self.register_file.destroy_stack_frame()
                self.writer.instruction(f"{HighAssemblyInstructions.RET} {function.number_of_parameters}", f"clean {function.number_of_parameters} function parameter{'s' if function.number_of_parameters != 1 else ''} from the stack and return")
                self.register_file.invalidate()
            elif self.for_part1:
                self.for_part1 = False
                self.for_part2 = True
                self.register_file.store_written()
                self.register_file.invalidate()
                self.writer.comment(f"{Keywords.FOR.to_label(function.name, self.for_scope_ids, self.scope_index)} condition")
                self.writer.label(f"{Keywords.FOR.to_label(function.name, self.for_scope_ids, self.scope_index)}_start")
            elif self.for_part2:
                self.for_part2 = False
                self.for_part3 = True

            self.register_file.expression_end()
            self.intermediate_result_counter = 0
            self.register_index = 0

        elif command == InternalAlphabet.EQUAL_ZERO_JUMP:
            self.register_file.resolve_register_names(self.register_names)
            if self.current_jump_statement == Keywords.IF or self.current_jump_statement == Keywords.ELSE_IF or self.current_jump_statement == Keywords.ELSE:
                self.writer.instruction(f"{HighAssemblyInstructions.JZ} {self.register_names[0]} {self.current_jump_statement.to_label(function.name, self.if_scope_ids, self.scope_index, self.else_if_counter - 1)}_{'end' if self.current_jump_statement == Keywords.WHILE or self.current_jump_statement == Keywords.FOR else 'skip'}", 
                                        f"jump when not {function.body[i - 1].comment}")
                self.writer.comment(f"{self.current_jump_statement.to_label(function.name, self.if_scope_ids, self.scope_index, self.else_if_counter - 1)} body")
            elif self.current_jump_statement == Keywords.WHILE:
                self.writer.instruction(f"{HighAssemblyInstructions.JZ} {self.register_names[0]} {self.current_jump_statement.to_label(function.name, self.while_scope_ids, self.scope_index)}_end", 
                                        f"jump when not {function.body[i - 1].comment}")
                self.writer.comment(f"{self.current_jump_statement.to_label(function.name, self.while_scope_ids, self.scope_index)} body")
            elif self.current_jump_statement == Keywords.FOR:
                self.writer.instruction(f"{HighAssemblyInstructions.JZ} {self.register_names[0]} {self.current_jump_statement.to_label(function.name, self.for_scope_ids, self.scope_index)}_end", 
                                        f"jump when not {function.body[i - 1].comment}")
                self.writer.comment(f"{self.current_jump_statement.to_label(function.name, self.for_scope_ids, self.scope_index)} body")
            else:
                raise Exception("Unknown jump statement")

        elif command == InternalAlphabet.SCOPE_INCREMENT:
            if not self.for_part1 and self.current_jump_statement: # no increment for first 'for' statement or empty statements
                self.writer.increase_indent()
                self.else_if_counter_stack.append(self.else_if_counter)
                self.else_if_counter = 0
                self.jump_statement_stack.append(self.current_jump_statement)
                self.current_jump_statement = None
            else:
                self.jump_statement_stack.append(None)

        elif command == InternalAlphabet.SCOPE_DECREMENT:
            self.current_jump_statement = self.jump_statement_stack.pop()
            if self.current_jump_statement: # no decrement for first 'for' statement or empty statements
                self.else_if_counter = self.else_if_counter_stack.pop()

                if self.current_jump_statement == Keywords.IF:
                    self.register_file.store_written()
                    self.register_file.invalidate()
                    if function.body[i + 1] == Keywords.ELSE_IF or function.body[i + 1] == Keywords.ELSE:
                        self.writer.instruction(f"{HighAssemblyInstructions.JMP} {Keywords.IF.to_label(function.name, self.if_scope_ids, self.scope_index)}_end")
                    self.writer.label(f"{self.current_jump_statement.to_label(function.name, self.if_scope_ids, self.scope_index)}_skip")
                    if function.body[i + 1] != Keywords.ELSE and function.body[i + 1] != Keywords.ELSE_IF:
                        self.if_scope_ids[self.scope_index] += 1

                elif self.current_jump_statement == Keywords.ELSE_IF:
                    self.register_file.store_written()
                    self.register_file.invalidate()
                    if function.body[i + 1] == Keywords.ELSE_IF or function.body[i + 1] == Keywords.ELSE:
                        self.writer.instruction(f"{HighAssemblyInstructions.JMP} {Keywords.IF.to_label(function.name, self.if_scope_ids, self.scope_index)}_end")
                        self.writer.label(f"{self.current_jump_statement.to_label(function.name, self.if_scope_ids, self.scope_index, self.else_if_counter - 1)}_skip")
                    else:
                        self.writer.label(f"{Keywords.IF.to_label(function.name, self.if_scope_ids, self.scope_index)}_end")
                        self.writer.label(f"{self.current_jump_statement.to_label(function.name, self.if_scope_ids, self.scope_index, self.else_if_counter - 1)}_skip")
                        self.if_scope_ids[self.scope_index] += 1

                elif self.current_jump_statement == Keywords.ELSE:
                    self.register_file.store_written()
                    self.register_file.invalidate()
                    self.writer.label(f"{Keywords.IF.to_label(function.name, self.if_scope_ids, self.scope_index)}_end")
                    self.writer.new_line()
                    self.if_scope_ids[self.scope_index] += 1

                elif self.current_jump_statement == Keywords.WHILE:
                    self.register_file.store_written()
                    self.register_file.invalidate()
                    self.writer.instruction(f"{HighAssemblyInstructions.JMP} {Keywords.WHILE.to_label(function.name, self.while_scope_ids, self.scope_index)}_start")
                    self.writer.label(f"{Keywords.WHILE.to_label(function.name, self.while_scope_ids, self.scope_index)}_end")
                    self.writer.new_line()
                    self.while_scope_ids[self.scope_index] += 1
                
                elif self.current_jump_statement == Keywords.FOR:
                    saved_for_statement = self.for_last_statement_stack.pop()
                    self.writer.comment(f"{Keywords.FOR.to_label(function.name, self.for_scope_ids, self.scope_index)} increment")
                    self._process_last_for_statement(saved_for_statement, function)
                    self.register_file.store_written()
                    self.register_file.invalidate()
                    self.writer.instruction(f"{HighAssemblyInstructions.JMP} {Keywords.FOR.to_label(function.name, self.for_scope_ids, self.scope_index)}_start")
                    self.writer.label(f"{Keywords.FOR.to_label(function.name, self.for_scope_ids, self.scope_index)}_end")
                    self.writer.new_line()
                    self.for_scope_ids[self.scope_index] += 1

                self.writer.decrease_indent()
                self.scope_index -= 1

        elif command == InternalAlphabet.FUNCTION_END:
            self.writer.raw(f"{HighAssemblyInstructions.EOF} ; end of function {function.name if function.name else ''}")

    def _handle_keyword(self, command: Keywords, function: Function, i: int):
        if command == Keywords.IF or command == Keywords.ELSE_IF or command == Keywords.ELSE or command == Keywords.WHILE or command == Keywords.FOR:
            self.scope_index += 1
            if self.scope_index == len(self.if_scope_ids):
                self.if_scope_ids.append(0)
                self.while_scope_ids.append(0)
                self.for_scope_ids.append(0)

        if command == Keywords.RETURN:
            self.return_expression = True
            self.register_index = 0
        elif command == Keywords.IF:
            self.current_jump_statement = Keywords.IF
            self.writer.new_line()
            self.writer.comment(f"{command.to_label(function.name, self.if_scope_ids, self.scope_index, self.else_if_counter)} header")
            self.register_file.store_written()
        elif command == Keywords.ELSE_IF:
            self.current_jump_statement = Keywords.ELSE_IF
            self.writer.comment(f"{command.to_label(function.name, self.if_scope_ids, self.scope_index, self.else_if_counter)} header")
            self.else_if_counter += 1
        elif command == Keywords.ELSE:
            self.current_jump_statement = Keywords.ELSE
            self.writer.comment(f"{command.to_label(function.name, self.if_scope_ids, self.scope_index, self.else_if_counter)}")
        elif command == Keywords.WHILE:
            self.current_jump_statement = Keywords.WHILE
            self.writer.comment(f"{command.to_label(function.name, self.while_scope_ids, self.scope_index)} header")
            self.register_file.store_written()
            self.writer.label(f"{command.to_label(function.name, self.while_scope_ids, self.scope_index)}_start")
            self.register_file.invalidate()
        elif command == Keywords.FOR:
            self.current_jump_statement = Keywords.FOR
            self.writer.comment(f"{command.to_label(function.name, self.for_scope_ids, self.scope_index)} assignment")
            self.for_part1 = True
    
    def _process_last_for_statement(self, commands: list[tuple], function: Function):
        for i, command in commands:
            if isinstance(command, Variable) or isinstance(command, IntermediateResult):
                self._handle_variable_or_intermediate_result(command, function, i)
            elif isinstance(command, Constant):
                self._handle_constant(command, function, i)
            elif isinstance(command, ReturnValue):
                self._handle_return_value(command, function, i)
            elif isinstance(command, Operators):
                self._handle_operator(command, function, i)
            elif isinstance(command, InternalAlphabet):
                self._handle_internal_alphabet(command, function, i)
            elif isinstance(command, Keywords):
                self._handle_keyword(command, function, i)

# functions to print better comments
    def _set_intermediate_result_comment(self, function: Function, function_index: int, comment: str, bracket: bool = True):
        for command in function.body[function_index:]:
            if isinstance(command, IntermediateResult) and command.number == self.intermediate_result_counter:
                command.set_comment(comment, bracket)
                return
        
        for command in reversed(function.body[:function_index + 1]):
            if isinstance(command, Keywords) and command == Keywords.RETURN:
                command.set_comment(comment)
                return
    
    def _find_intermediate_result(self, function: Function, function_index: int, number: int) -> IntermediateResult:
        for command in reversed(function.body[:function_index + 1]):
            if isinstance(command, IntermediateResult) and command.number == number:
                return command
        
        for command in reversed(function.body[:function_index + 1]):
            if isinstance(command, Keywords) and command == Keywords.RETURN:
                return command

        return None
        
