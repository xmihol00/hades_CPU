from enum import Enum
from function_call_table import FunctionCallTable
from function_declaration_table import FunctionDeclarationTable
from variable_table import VariableTable
from utils import ordinal
from constructs import Function, Variable
from enums import Types, VariableUsage, Tokens, InnerAlphabet, Keywords, ScopeTypes
from expression_parser import ExpressionParser

class ParserStates(Enum):
    FUNCTION_RETURN_TYPE = 1
    FUNCTION_NAME = 2
    FUNCTION_PARAMETERS_OPENED = 3
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
    def __init__(self, function_declaration_table: FunctionDeclarationTable, function_call_table: FunctionCallTable, variable_table: VariableTable):
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
        self.state = ParserStates.FUNCTION_RETURN_TYPE
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
        self.expression_analyzer = ExpressionParser(self.function_call_table, self.variable_table)
    
    def parse(self, token: Tokens, value: str, line_number: int, token_number: int):
        try:
            self.callback_table[token](value)
        except Exception as e:
            print(self.current_function)
            print(self.state)
            print(self.expression_analyzer.state)
            print(self.expression_analyzer.expression)
            print(f"Unexpected {ordinal(token_number)} token '{value}' at line {line_number}.")
            raise e
    
    def type(self, value: str):
        if ParserStates.FUNCTION_RETURN_TYPE == self.state:
            self.state = ParserStates.FUNCTION_NAME
            self.current_function = Function(value)
        elif ParserStates.FUNCTION_PARAMETER_TYPE_OR_CLOSED_BRACKET == self.state:
            self.state = ParserStates.FUNCTION_PARAMETER_NAME
            self.current_function.parameters.append(Variable(value))
        elif ParserStates.FUNCTION_PARAMETER_TYPE == self.state:
            self.state = ParserStates.FUNCTION_PARAMETER_NAME
            self.current_function.parameters.append(Variable(value))
        elif ParserStates.STATEMENT == self.state or ParserStates.STATEMENT_OR_ELSE == self.state:
            self.state = ParserStates.VARIABLE_NAME
            self.current_variable = Variable(value)
        else:
            raise Exception()

    def keyword(self, value: str):
        value = Keywords(value)
        if Keywords.RETURN == value and ParserStates.STATEMENT == self.state:
            self.current_function.body.append(value)
            self.state = ParserStates.EXPRESSION
        elif Keywords.IF == value and ParserStates.STATEMENT == self.state:
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
            self.current_function.body.append(InnerAlphabet.SCOPE_INCREMENT)
            self.state = ParserStates.FOR_OPENED_BRACKET
        elif Keywords.BREAK == value and ParserStates.STATEMENT == self.state:
            self.current_function.body.append(value)
            self.state = ParserStates.SEMICOLON

    def identifier(self, value: str):
        if ParserStates.FUNCTION_NAME == self.state:
            self.state = ParserStates.FUNCTION_PARAMETERS_OPENED
            self.current_function.name = value
            self.function_declaration_table.add(self.current_function)
        elif ParserStates.FUNCTION_PARAMETER_NAME == self.state:
            self.state = ParserStates.FUNCTION_PARAMETERS_COMMA_OR_CLOSED_BRACKET
            self.current_function.parameters[-1].name = value
            self.variable_table.add(self.current_function.parameters[-1])
        elif ParserStates.VARIABLE_NAME == self.state:
            self.state = ParserStates.VARIABLE_ASSIGNMENT_OR_SEMICOLON
            self.current_variable.name = value
            self.variable_table.add(self.current_variable)
            self.expression_analyzer.add_identifier_operand(self.current_variable)
        elif ParserStates.EXPRESSION == self.state:
            self.expression_analyzer.add_identifier_operand(value)
        elif ParserStates.STATEMENT == self.state:
            self.state = ParserStates.EXPRESSION
            self.expression_analyzer.add_identifier_operand(value)
        else:
            raise Exception()

    def opened_bracket(self, _: str):
        if ParserStates.FUNCTION_PARAMETERS_OPENED == self.state:
            self.state = ParserStates.FUNCTION_PARAMETER_TYPE_OR_CLOSED_BRACKET
            self.variable_table.increase_scope()
        elif ParserStates.EXPRESSION_BRACKET_START == self.state:
            self.state = ParserStates.EXPRESSION
            self.expression_analyzer.add_opened_bracket()
        elif ParserStates.EXPRESSION == self.state:
            self.expression_analyzer.add_opened_bracket()
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
            self.expression_analyzer.add_closed_bracket()
            if self.scope_type_stack[-1] in self.bracket_expression_scopes and self.expression_analyzer.is_expression_valid():
                self.state = ParserStates.OPENED_CURLY_BRACKET
                self.current_function.body += self.expression_analyzer.retrieve_expression()
                if self.scope_type_stack[-1] == ScopeTypes.FOR_HEADER:
                    self.scope_type_stack.append(ScopeTypes.FOR_BODY)
        else:
            raise Exception()

    def opened_curly_bracket(self, _: str):
        if ParserStates.FUNCTION_BODY_OPENED == self.state:
            self.scope_type_stack.append(ScopeTypes.FUNCTION)
            self.current_function.body.append(InnerAlphabet.FUNCTION_START)
            self.state = ParserStates.STATEMENT
            return # scope was already increased
        elif ParserStates.OPENED_CURLY_BRACKET == self.state:
            self.state = ParserStates.STATEMENT
            self.current_function.body.append(InnerAlphabet.SCOPE_INCREMENT)
        elif ParserStates.IF_OR_OPENED_CURLY_BRACKET == self.state:
            self.scope_type_stack.append(ScopeTypes.ELSE)
            self.current_function.body.append(InnerAlphabet.SCOPE_INCREMENT)
            self.state = ParserStates.STATEMENT
        elif ParserStates.STATEMENT == self.state:
            self.scope_type_stack.append(ScopeTypes.BLOCK)
            self.current_function.body.append(InnerAlphabet.SCOPE_INCREMENT)
        else:
            raise Exception()
        
        self.variable_table.increase_scope()

    def closed_curly_bracket(self, _: str):
        if len(self.scope_type_stack) == 0 or ParserStates.STATEMENT != self.state:
            raise Exception()
        
        popped_scope_type = self.scope_type_stack.pop()
        self.variable_table.decrease_scope()
        
        if popped_scope_type == ScopeTypes.FUNCTION:
            self.state = ParserStates.FUNCTION_RETURN_TYPE
            self.current_function.body.append(InnerAlphabet.FUNCTION_END)
            self.current_function = None
        else:
            self.state = ParserStates.STATEMENT
            self.current_function.body.append(InnerAlphabet.SCOPE_DECREMENT)

            if popped_scope_type == ScopeTypes.IF:
                self.state = ParserStates.STATEMENT_OR_ELSE
            elif popped_scope_type == ScopeTypes.FOR_BODY:
                self.scope_type_stack.pop()
                self.variable_table.decrease_scope()
                self.current_function.body.append(InnerAlphabet.SCOPE_DECREMENT)
        
    def integer(self, value: str):
        value = int(value)
        if ParserStates.EXPRESSION == self.state:
            self.expression_analyzer.add_constant_operand(Types.INT, value)
        else:
            raise Exception()

    def boolean(self, value: str):
        pass

    def assignment(self, _: str):
        if ParserStates.VARIABLE_ASSIGNMENT_OR_SEMICOLON == self.state:
            self.state = ParserStates.EXPRESSION
            self.current_variable.set_usage(VariableUsage.DECLARATION_WITH_ASSIGNMENT)
            self.current_variable = None
        elif ParserStates.EXPRESSION != self.state:
            raise Exception()

        self.expression_analyzer.add_assignment()

    def operator(self, value: str):
        if ParserStates.EXPRESSION == self.state:
            self.expression_analyzer.add_operator(value)
        else:
            raise Exception()

    def semicolon(self, _: str):
        if ParserStates.VARIABLE_ASSIGNMENT_OR_SEMICOLON == self.state:
            self.current_variable.set_usage(VariableUsage.DECLARATION)
            self.current_function.body.append(self.current_variable)
            self.current_variable = None
            self.state = ParserStates.STATEMENT
        elif ParserStates.EXPRESSION == self.state:
            self.expression_analyzer.add_semicolon()
            self.current_function.body += self.expression_analyzer.retrieve_expression()
            self.current_function.body.append(InnerAlphabet.EXPRESSION_END)
            if self.for_counter == 1:
                self.for_counter += 1
                self.state = ParserStates.EXPRESSION
            elif self.for_counter == 2:
                self.for_counter = 0
                self.state = ParserStates.EXPRESSION
                self.expression_analyzer.add_opened_bracket()
                self.scope_type_stack[-1] = ScopeTypes.FOR_HEADER
            else:
                self.state = ParserStates.STATEMENT
        elif ParserStates.SEMICOLON == self.state:
            self.state = ParserStates.STATEMENT
        else:
            raise Exception()
    
    def comma(self, _: str):
        if ParserStates.FUNCTION_PARAMETERS_COMMA_OR_CLOSED_BRACKET == self.state:
            self.state = ParserStates.FUNCTION_PARAMETER_TYPE
            self.current_variable = None
        elif ParserStates.EXPRESSION == self.state:
            self.expression_analyzer.add_comma()
        else:
            raise Exception()
