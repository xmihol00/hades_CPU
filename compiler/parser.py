from enum import Enum
from global_expressions import GlobalExpressions
from function_call_table import FunctionCallTable
from function_declaration_table import FunctionDeclarationTable
from variable_table import VariableTable
from utils import ordinal
from constructs import Constant, Function, Variable
from enums import Operators, Types, VariableUsage, Tokens, InternalAlphabet, Keywords, ScopeTypes
from expression_parser import ExpressionParser
import ast

class ParserStates(Enum):
    FUNCTION_RETURN_TYPE_OR_GLOBAL_VARIABLE_TYPE = 1
    FUNCTION_NAME_OR_GLOBAL_VARIABLE_NAME = 2
    FUNCTION_PARAMETERS_OPENED_BRACKET_OR_GLOBAL_VARIABLE_ASSIGNMENT_OR_SEMICOLON = 3
    FUNCTION_PARAMETER_TYPE_OR_CLOSED_BRACKET = 4
    FUNCTION_PARAMETER_TYPE = 5
    FUNCTION_PARAMETER_NAME_OR_POINTER = 6
    FUNCTION_PARAMETER_NAME = 7
    FUNCTION_PARAMETERS_COMMA_OR_CLOSED_BRACKET = 8
    FUNCTION_BODY_OPENED = 9
    STATEMENT = 10
    VARIABLE_NAME_OR_POINTER = 11
    VARIABLE_NAME = 12
    VARIABLE_ASSIGNMENT_OR_OPENED_SQUARE_BRACKET_OR_SEMICOLON = 13
    EXPRESSION = 14
    EXPRESSION_BRACKET_START = 15
    OPENED_CURLY_BRACKET = 16
    STATEMENT_OR_ELSE = 17
    IF_OR_OPENED_CURLY_BRACKET = 18
    FOR_OPENED_BRACKET = 19
    SEMICOLON = 20
    MEMORY_SIZE_CONSTANT = 21
    CLOSED_SQUARED_BRACKET = 22
    
class Parser:
    def __init__(self, function_declaration_table: FunctionDeclarationTable, function_call_table: FunctionCallTable, 
                       variable_table: VariableTable, global_expressions: GlobalExpressions):
        self.function_declaration_table = function_declaration_table
        self.function_call_table = function_call_table
        self.variable_table = variable_table
        self.variable_table.increase_scope()
        self.callback_table = { 
            Tokens.KEYWORD: self.keyword,
            Tokens.TYPE: self.type,
            Tokens.BOOLEAN: self.boolean,
            Tokens.IDENTIFIER: self.identifier,
            Tokens.OPENED_BRACKET: self.opened_bracket,
            Tokens.CLOSED_BRACKET: self.closed_bracket,
            Tokens.OPENED_CURLY_BRACKET: self.opened_curly_bracket,
            Tokens.CLOSED_CURLY_BRACKET: self.closed_curly_bracket,
            Tokens.OPENED_SQUARE_BRACKET: self.opened_square_bracket,
            Tokens.CLOSED_SQUARE_BRACKET: self.closed_square_bracket,
            Tokens.INTEGER: self.integer,
            Tokens.ASSIGNMENT: self.assignment,
            Tokens.OPERATOR: self.operator,
            Tokens.SEMICOLON: self.semicolon,
            Tokens.COMMA: self.comma,
            Tokens.CHARACTER: self.character,
        }
        self.state = ParserStates.FUNCTION_RETURN_TYPE_OR_GLOBAL_VARIABLE_TYPE
        self.scope_number = 0
        self.scope_type_stack = [ScopeTypes.GLOBAL]
        self.bracket_expression_scopes = [
            ScopeTypes.IF,
            ScopeTypes.WHILE,
            ScopeTypes.FOR_HEADER
        ]
        self.current_function = None
        self.current_variable = None
        self.for_counter = 0
        self.expression_parser = ExpressionParser(function_call_table=self.function_call_table, variable_table=self.variable_table)
        self.global_variable_or_function_type = None
        self.global_variable_or_function_name = None
        self.global_expressions = global_expressions
        self.global_assignment_mode = False
        self.global_assignment_string = ""
        self.variable_offset = 0
    
    def parse(self, token: Tokens, value: str, line_number: int, token_number: int):
        try:
            if self.global_assignment_mode:
                self._resolve_global_assignment(token, value)
            else:
                self.callback_table[token](value)
        except Exception as e:
            raise Exception(f"Unexpected {ordinal(token_number)} token '{value}' at line {line_number}.") from e
    
    def type(self, value: str):
        if ParserStates.FUNCTION_RETURN_TYPE_OR_GLOBAL_VARIABLE_TYPE == self.state:
            self.state = ParserStates.FUNCTION_NAME_OR_GLOBAL_VARIABLE_NAME
            self.global_variable_or_function_type = value
        elif ParserStates.FUNCTION_PARAMETER_TYPE_OR_CLOSED_BRACKET == self.state:
            self.state = ParserStates.FUNCTION_PARAMETER_NAME_OR_POINTER
            self.current_function.add_parameter(Variable(value))
        elif ParserStates.FUNCTION_PARAMETER_TYPE == self.state:
            self.state = ParserStates.FUNCTION_PARAMETER_NAME_OR_POINTER
            self.current_function.add_parameter(Variable(value))
        elif ParserStates.STATEMENT == self.state or ParserStates.STATEMENT_OR_ELSE == self.state:
            self.state = ParserStates.VARIABLE_NAME_OR_POINTER
            self.variable_offset -= self.current_variable.stack_size if self.current_variable else 2
            self.current_variable = Variable(value, self.variable_offset)
        else:
            raise Exception()

    def keyword(self, value: str):
        value = Keywords(value)
        if Keywords.RETURN == value and ParserStates.STATEMENT == self.state:
            self.current_function.body.append(value)
            self.state = ParserStates.EXPRESSION
        elif Keywords.IF == value and (ParserStates.STATEMENT == self.state or ParserStates.STATEMENT_OR_ELSE == self.state):
            self.scope_type_stack.append(ScopeTypes.IF)
            self.current_function.body.append(value)
            self.state = ParserStates.EXPRESSION_BRACKET_START
        elif Keywords.IF == value and ParserStates.IF_OR_OPENED_CURLY_BRACKET == self.state:
            self.scope_type_stack.append(ScopeTypes.IF)
            value = Keywords.ELSE_IF
            self.current_function.body[-1] = value
            self.state = ParserStates.EXPRESSION_BRACKET_START
        elif Keywords.ELSE == value and ParserStates.STATEMENT_OR_ELSE == self.state:
            self.current_function.body.append(value)
            self.state = ParserStates.IF_OR_OPENED_CURLY_BRACKET
        elif Keywords.WHILE == value and ParserStates.STATEMENT == self.state:
            self.current_function.body.append(value)
            self.scope_type_stack.append(ScopeTypes.WHILE)
            self.state = ParserStates.EXPRESSION_BRACKET_START
        elif Keywords.FOR == value and ParserStates.STATEMENT == self.state:
            self.current_function.body.append(value)
            self.scope_type_stack.append(ScopeTypes.BLOCK) # will be changed to FOR_HEADER for lass expression later
            self.variable_table.increase_scope()
            self.current_function.body.append(InternalAlphabet.SCOPE_INCREMENT)
            self.state = ParserStates.FOR_OPENED_BRACKET
        elif Keywords.BREAK == value and ParserStates.STATEMENT == self.state:
            self.current_function.body.append(value)
            self.state = ParserStates.SEMICOLON
        else:
            raise Exception()

    def identifier(self, value: str):
        if ParserStates.FUNCTION_NAME_OR_GLOBAL_VARIABLE_NAME == self.state:
            self.state = ParserStates.FUNCTION_PARAMETERS_OPENED_BRACKET_OR_GLOBAL_VARIABLE_ASSIGNMENT_OR_SEMICOLON
            self.global_variable_or_function_name = value
        elif ParserStates.FUNCTION_PARAMETER_NAME == self.state or ParserStates.FUNCTION_PARAMETER_NAME_OR_POINTER == self.state:
            self.state = ParserStates.FUNCTION_PARAMETERS_COMMA_OR_CLOSED_BRACKET
            self.current_function.parameters[-1].set_name(value)
            self.variable_table.add(self.current_function.parameters[-1])
        elif ParserStates.VARIABLE_NAME == self.state or ParserStates.VARIABLE_NAME_OR_POINTER == self.state:
            self.state = ParserStates.VARIABLE_ASSIGNMENT_OR_OPENED_SQUARE_BRACKET_OR_SEMICOLON
            self.current_variable.set_name(value)
            self.variable_table.add(self.current_variable)
            self.current_function.add_variable(self.current_variable)
            self.expression_parser.add_identifier_operand(self.current_variable.name)
        elif ParserStates.EXPRESSION == self.state:
            self.expression_parser.add_identifier_operand(value)
        elif ParserStates.STATEMENT == self.state or ParserStates.STATEMENT_OR_ELSE == self.state:
            self.state = ParserStates.EXPRESSION
            self.expression_parser.add_identifier_operand(value)
        else:
            raise Exception()

    def opened_bracket(self, _: str):
        if ParserStates.FUNCTION_PARAMETERS_OPENED_BRACKET_OR_GLOBAL_VARIABLE_ASSIGNMENT_OR_SEMICOLON == self.state:
            self.state = ParserStates.FUNCTION_PARAMETER_TYPE_OR_CLOSED_BRACKET
            self.current_function = Function(self.global_variable_or_function_type, self.global_variable_or_function_name)
            self.function_declaration_table.add(self.current_function)
            self.variable_table.increase_scope()
        elif ParserStates.EXPRESSION_BRACKET_START == self.state:
            self.state = ParserStates.EXPRESSION
            self.expression_parser.add_opened_bracket()
        elif ParserStates.EXPRESSION == self.state:
            self.expression_parser.add_opened_bracket()
        elif ParserStates.FOR_OPENED_BRACKET == self.state:
            self.state = ParserStates.STATEMENT
            self.for_counter += 1
        else:
            raise Exception()

    def closed_bracket(self, _: str):
        if ParserStates.FUNCTION_PARAMETER_TYPE_OR_CLOSED_BRACKET == self.state:
            self.state = ParserStates.FUNCTION_BODY_OPENED
        elif ParserStates.FUNCTION_PARAMETERS_COMMA_OR_CLOSED_BRACKET == self.state:
            self.state = ParserStates.FUNCTION_BODY_OPENED
        elif ParserStates.EXPRESSION == self.state:
            self.expression_parser.add_closed_bracket()
            if self.scope_type_stack[-1] in self.bracket_expression_scopes and self.expression_parser.is_expression_valid():
                self.scope_type_stack[-1] = self.scope_type_stack[-1].to_opened()
                self.state = ParserStates.OPENED_CURLY_BRACKET
                if self.scope_type_stack[-1] == ScopeTypes.FOR_HEADER_OPENED:
                    self.scope_type_stack.append(ScopeTypes.FOR_BODY)
                else:
                    self.expression_parser.add_equal_zero_jump() # if, else if, while
                self.current_function.body += self.expression_parser.retrieve_expression()
                self.current_function.body.append(InternalAlphabet.EXPRESSION_END)
        else:
            raise Exception()

    def opened_curly_bracket(self, _: str):
        if ParserStates.FUNCTION_BODY_OPENED == self.state:
            self.scope_type_stack.append(ScopeTypes.FUNCTION)
            self.current_function.body.append(InternalAlphabet.FUNCTION_START)
            self.state = ParserStates.STATEMENT
            return # scope was already increased
        elif ParserStates.OPENED_CURLY_BRACKET == self.state:
            self.state = ParserStates.STATEMENT
            self.current_function.body.append(InternalAlphabet.SCOPE_INCREMENT)
        elif ParserStates.IF_OR_OPENED_CURLY_BRACKET == self.state:
            self.scope_type_stack.append(ScopeTypes.ELSE)
            self.current_function.body.append(InternalAlphabet.SCOPE_INCREMENT)
            self.state = ParserStates.STATEMENT
        elif ParserStates.STATEMENT == self.state:
            self.scope_type_stack.append(ScopeTypes.BLOCK)
            self.current_function.body.append(InternalAlphabet.SCOPE_INCREMENT)
        else:
            raise Exception()
        
        self.variable_table.increase_scope()

    def closed_curly_bracket(self, _: str):
        if len(self.scope_type_stack) == 0 or ParserStates.STATEMENT != self.state:
            raise Exception()
        
        popped_scope_type = self.scope_type_stack.pop()
        self.variable_table.decrease_scope(self.current_function.name)
        
        if popped_scope_type == ScopeTypes.FUNCTION:
            self.state = ParserStates.FUNCTION_RETURN_TYPE_OR_GLOBAL_VARIABLE_TYPE
            self.current_function.body.append(InternalAlphabet.FUNCTION_END)
            self.current_function.assign_parameters_offset()
            self.current_function = None
            self.variable_offset = 0
        else:
            self.state = ParserStates.STATEMENT
            self.current_function.body.append(InternalAlphabet.SCOPE_DECREMENT)

            if popped_scope_type == ScopeTypes.IF_OPENED:
                self.state = ParserStates.STATEMENT_OR_ELSE
            elif popped_scope_type == ScopeTypes.FOR_BODY:
                self.scope_type_stack.pop()
                self.variable_table.decrease_scope()
                self.current_function.body.append(InternalAlphabet.SCOPE_DECREMENT)
    
    def opened_square_bracket(self, _: str):
        if ParserStates.VARIABLE_ASSIGNMENT_OR_OPENED_SQUARE_BRACKET_OR_SEMICOLON == self.state:
            self.state = ParserStates.MEMORY_SIZE_CONSTANT
            self.current_variable.type = Types.ARRAY
        elif ParserStates.EXPRESSION == self.state:
            self.expression_parser.add_opened_square_bracket()
        else:
            raise Exception()

    def closed_square_bracket(self, _: str):
        if ParserStates.CLOSED_SQUARED_BRACKET == self.state:
            self.state = ParserStates.SEMICOLON
        elif ParserStates.EXPRESSION == self.state:
            self.expression_parser.add_closed_square_bracket()
        else:
            raise Exception()
        
    def integer(self, value: str|Constant):
        if isinstance(value, str):
            value = Constant(type=Types.INT, value=int(value), comment=value)

        if ParserStates.EXPRESSION == self.state:
            self.expression_parser.add_constant_operand(value)
        elif ParserStates.MEMORY_SIZE_CONSTANT == self.state:
            self.state = ParserStates.CLOSED_SQUARED_BRACKET
            self.current_variable.set_stack_size(value.value)
        else:
            raise Exception()

    def boolean(self, value: str):
        operand = Constant(type=Types.INT, value=int(value == "true"), comment=value)
        self.integer(operand)

    def character(self, value: str):
        character = ord(ast.literal_eval(value))
        if ParserStates.EXPRESSION == self.state:
            operand = Constant(type=Types.INT, value=character, comment=value)
            self.integer(operand)
        else:
            raise Exception()

    def assignment(self, _: str):
        if ParserStates.VARIABLE_ASSIGNMENT_OR_OPENED_SQUARE_BRACKET_OR_SEMICOLON == self.state:
            self.state = ParserStates.EXPRESSION
            self.current_variable.set_usage(VariableUsage.DECLARATION_WITH_ASSIGNMENT)
            self.expression_parser.add_assignment()
        elif ParserStates.FUNCTION_PARAMETERS_OPENED_BRACKET_OR_GLOBAL_VARIABLE_ASSIGNMENT_OR_SEMICOLON == self.state:
            self.current_variable = Variable(self.global_variable_or_function_type, None, self.global_variable_or_function_name)
            self.variable_table.add(self.current_variable)
            self.current_function.add_variable(self.current_variable)
            self.global_assignment_mode = True
            return
        elif ParserStates.EXPRESSION == self.state:
            self.expression_parser.add_assignment()
        else:
            raise Exception()

    def operator(self, value: str):
        if ParserStates.EXPRESSION == self.state:
            self.expression_parser.add_operator(value)
        elif (ParserStates.STATEMENT == self.state or ParserStates.STATEMENT_OR_ELSE == self.state) and value == '*': # dereference
            self.expression_parser.add_operator(Operators.ASSIGNMENT_DEREFERENCE.value)
            self.state = ParserStates.EXPRESSION
        elif ParserStates.VARIABLE_NAME_OR_POINTER == self.state and value == '*': # pointer
            self.current_variable.type = Types.PTR
            self.state = ParserStates.VARIABLE_NAME
        elif ParserStates.FUNCTION_PARAMETER_NAME_OR_POINTER == self.state and value == '*': # pointer
            self.current_function.parameters[-1].type = Types.PTR
            self.state = ParserStates.FUNCTION_PARAMETER_NAME
        else:
            raise Exception()

    def semicolon(self, _: str):
        if ParserStates.VARIABLE_ASSIGNMENT_OR_OPENED_SQUARE_BRACKET_OR_SEMICOLON == self.state:
            self.current_variable.set_usage(VariableUsage.DECLARATION)
            self.expression_parser.retrieve_expression()
            self.state = ParserStates.STATEMENT
        elif ParserStates.EXPRESSION == self.state:
            self.expression_parser.add_semicolon()
            if self.for_counter == 2:
                self.expression_parser.add_equal_zero_jump()
            self.current_function.body += self.expression_parser.retrieve_expression()
            self.current_function.body.append(InternalAlphabet.EXPRESSION_END)

            if self.for_counter == 1:
                self.for_counter += 1
            elif self.for_counter == 2:
                self.for_counter = 0
                self.expression_parser.add_opened_bracket()
                self.scope_type_stack[-1] = ScopeTypes.FOR_HEADER
            else:
                self.state = ParserStates.STATEMENT

        elif ParserStates.SEMICOLON == self.state:
            self.state = ParserStates.STATEMENT
            self.expression_parser.retrieve_expression()
        elif ParserStates.FUNCTION_PARAMETERS_OPENED_BRACKET_OR_GLOBAL_VARIABLE_ASSIGNMENT_OR_SEMICOLON == self.state:
            self.state = ParserStates.FUNCTION_RETURN_TYPE_OR_GLOBAL_VARIABLE_TYPE
            variable = Variable(self.global_variable_or_function_type, None, self.global_variable_or_function_name, VariableUsage.DECLARATION)
            self.variable_table.add(variable)
            self.current_function.add_variable(variable)
        else:
            raise Exception()
    
    def comma(self, _: str):
        if ParserStates.FUNCTION_PARAMETERS_COMMA_OR_CLOSED_BRACKET == self.state:
            self.state = ParserStates.FUNCTION_PARAMETER_TYPE
        elif ParserStates.EXPRESSION == self.state:
            self.expression_parser.add_comma()
        else:
            raise Exception()
        
    def _resolve_global_assignment(self, token: Tokens, value: str):
        if Tokens.SEMICOLON == token:
            self.global_expressions.add(self.current_variable)
            self.global_expressions.add(Constant(Types.INT, int(eval(self.global_assignment_string))))
            self.global_expressions.add(Operators.ASSIGNMENT)
            self.global_expressions.add(InternalAlphabet.EXPRESSION_END)
            self.global_assignment_string = ""
            self.state = ParserStates.FUNCTION_RETURN_TYPE_OR_GLOBAL_VARIABLE_TYPE
            self.global_assignment_mode = False
            self.current_variable.set_label(f"@{self.current_variable.name}")
        elif Tokens.CLOSED_BRACKET == token or Tokens.OPENED_BRACKET == token or Tokens.INTEGER == token or Tokens.OPERATOR == token:
            self.global_assignment_string += value
        else:
            raise Exception()
