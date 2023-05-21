from enum import Enum
from global_expressions import GlobalExpressions
from function_call_table import FunctionCallTable
from function_declaration_table import FunctionDeclarationTable
from variable_table import VariableTable
from utils import ordinal
from constructs import Constant, Function, Variable
from enums import Operators, Types, VariableUsage, Tokens, InternalAlphabet, Keywords, ScopeTypes
from expression_parser import ExpressionParser

class ParserStates(Enum):
    FUNCTION_RETURN_TYPE_OR_GLOBAL_VARIABLE_TYPE = 1
    FUNCTION_NAME_OR_GLOBAL_VARIABLE_NAME = 2
    FUNCTION_PARAMETERS_OPENED_BRACKET_OR_GLOBAL_VARIABLE_ASSIGNMENT_OR_SEMICOLON = 3
    FUNCTION_PARAMETER_TYPE_OR_CLOSED_BRACKET = 4
    FUNCTION_PARAMETER_TYPE = 5
    FUNCTION_PARAMETER_NAME = 6
    FUNCTION_PARAMETERS_COMMA_OR_CLOSED_BRACKET = 7
    FUNCTION_BODY_OPENED = 8
    STATEMENT = 9
    VARIABLE_NAME = 10
    VARIABLE_ASSIGNMENT_OR_SEMICOLON = 11
    EXPRESSION = 12
    EXPRESSION_BRACKET_START = 13
    OPENED_CURLY_BRACKET = 14
    STATEMENT_OR_ELSE = 15
    IF_OR_OPENED_CURLY_BRACKET = 16
    FOR_OPENED_BRACKET = 17
    SEMICOLON = 18
    
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
            Tokens.IDENTIFIER: self.identifier,
            Tokens.OPENED_BRACKET: self.opened_bracket,
            Tokens.CLOSED_BRACKET: self.closed_bracket,
            Tokens.OPENED_CURLY_BRACKET: self.opened_curly_bracket,
            Tokens.CLOSED_CURLY_BRACKET: self.closed_curly_bracket,
            Tokens.INTEGER: self.integer,
            Tokens.BOOLEAN: self.boolean,
            Tokens.ASSIGNMENT: self.assignment,
            Tokens.OPERATOR: self.operator,
            Tokens.SEMICOLON: self.semicolon,
            Tokens.COMMA: self.comma
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
            self.state = ParserStates.FUNCTION_PARAMETER_NAME
            self.current_function.add_parameter(Variable(value))
        elif ParserStates.FUNCTION_PARAMETER_TYPE == self.state:
            self.state = ParserStates.FUNCTION_PARAMETER_NAME
            self.current_function.add_parameter(Variable(value))
        elif ParserStates.STATEMENT == self.state or ParserStates.STATEMENT_OR_ELSE == self.state:
            self.state = ParserStates.VARIABLE_NAME
            self.variable_offset -= 1
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
        elif ParserStates.FUNCTION_PARAMETER_NAME == self.state:
            self.state = ParserStates.FUNCTION_PARAMETERS_COMMA_OR_CLOSED_BRACKET
            self.current_function.parameters[-1].set_name(value)
            self.variable_table.add(self.current_function.parameters[-1])
        elif ParserStates.VARIABLE_NAME == self.state:
            self.state = ParserStates.VARIABLE_ASSIGNMENT_OR_SEMICOLON
            self.current_variable.set_name(value)
            self.variable_table.add(self.current_variable)
            self.expression_parser.add_identifier_operand(self.current_variable.name)
        elif ParserStates.EXPRESSION == self.state:
            self.expression_parser.add_identifier_operand(value)
        elif ParserStates.STATEMENT == self.state:
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
                self.state = ParserStates.OPENED_CURLY_BRACKET
                if self.scope_type_stack[-1] == ScopeTypes.FOR_HEADER:
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

            if popped_scope_type == ScopeTypes.IF:
                self.state = ParserStates.STATEMENT_OR_ELSE
            elif popped_scope_type == ScopeTypes.FOR_BODY:
                self.scope_type_stack.pop()
                self.variable_table.decrease_scope()
                self.current_function.body.append(InternalAlphabet.SCOPE_DECREMENT)
        
    def integer(self, value: str):
        value = int(value)
        if ParserStates.EXPRESSION == self.state:
            self.expression_parser.add_constant_operand(Types.INT, value)
        else:
            raise Exception()

    def boolean(self, value: str):
        pass

    def assignment(self, _: str):
        if ParserStates.VARIABLE_ASSIGNMENT_OR_SEMICOLON == self.state:
            self.state = ParserStates.EXPRESSION
            self.current_variable.set_usage(VariableUsage.DECLARATION_WITH_ASSIGNMENT)
            self.current_variable = None
        elif ParserStates.FUNCTION_PARAMETERS_OPENED_BRACKET_OR_GLOBAL_VARIABLE_ASSIGNMENT_OR_SEMICOLON == self.state:
            self.current_variable = Variable(self.global_variable_or_function_type, None, self.global_variable_or_function_name)
            self.variable_table.add(self.current_variable)
            self.global_assignment_mode = True
            return
        elif ParserStates.EXPRESSION != self.state:
            raise Exception()

        self.expression_parser.add_assignment()

    def operator(self, value: str):
        if ParserStates.EXPRESSION == self.state:
            self.expression_parser.add_operator(value)
        else:
            raise Exception()

    def semicolon(self, _: str):
        if ParserStates.VARIABLE_ASSIGNMENT_OR_SEMICOLON == self.state:
            self.current_variable.set_usage(VariableUsage.DECLARATION)
            self.expression_parser.retrieve_expression()
            self.current_variable = None
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
        elif ParserStates.FUNCTION_PARAMETERS_OPENED_BRACKET_OR_GLOBAL_VARIABLE_ASSIGNMENT_OR_SEMICOLON == self.state:
            self.state = ParserStates.FUNCTION_RETURN_TYPE_OR_GLOBAL_VARIABLE_TYPE
            self.variable_table.add(Variable(self.global_variable_or_function_type, None, self.global_variable_or_function_name, VariableUsage.DECLARATION))
        else:
            raise Exception()
    
    def comma(self, _: str):
        if ParserStates.FUNCTION_PARAMETERS_COMMA_OR_CLOSED_BRACKET == self.state:
            self.state = ParserStates.FUNCTION_PARAMETER_TYPE
            self.current_variable = None
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
            self.current_variable = None
        elif Tokens.CLOSED_BRACKET == token or Tokens.OPENED_BRACKET == token or Tokens.INTEGER == token or Tokens.OPERATOR == token:
            self.global_assignment_string += value
        else:
            raise Exception()
