from enum import Enum
from function_table import FunctionTable
from variable_table import VariableTable
from utils import ordinal
from constructs import Function, Variable
from enums import Types, VariableUsage, Tokens, InnerAlphabet, Keywords
from expression_parser import ExpressionParser

class ParserStates(Enum):
    FUNCTION_RETURN_TYPE = 1
    FUNCTION_NAME = 2
    FUNCTION_PARAMETERS_OPENED = 3
    FUNCTION_PARAMETER_TYPE_OR_CLOSED = 4
    FUNCTION_PARAMETER_NAME = 5
    FUNCTION_PARAMETERS_COMMA_OR_CLOSED = 6
    FUNCTION_BODY_OPENED = 7
    EXPRESSION = 8
    VARIABLE_NAME = 9
    VARIABLE_ASSIGNMENT_OR_SEMICOLON = 10
    
class Parser:
    def __init__(self, function_table: FunctionTable, variable_table: VariableTable):
        self.function_table = function_table
        self.variable_table = variable_table
        self.callback_table = { 
            Tokens.KEYWORD: self.keyword,
            Tokens.TYPE: self.type,
            Tokens.IDENTIFIER: self.identifier,
            Tokens.OPENED_BRACKET: self.opened_bracket,
            Tokens.CLOSED_BRACKET: self.closed_bracket,
            Tokens.OPENED_PARENTHESES: self.opened_parentheses,
            Tokens.CLOSED_PARENTHESES: self.closed_parentheses,
            Tokens.INTEGER: self.integer,
            Tokens.BOOLEAN: self.boolean,
            Tokens.ASSIGNMENT: self.assignment,
            Tokens.OPERATOR: self.operator,
            Tokens.SEMICOLON: self.semicolon
        }
        self.state = ParserStates.FUNCTION_RETURN_TYPE
        self.state_stack = []
        self.current_function = None
        self.current_variable = None
        self.expression_analyzer = ExpressionParser()
    
    def parse(self, token: Tokens, value: str, line_number: int, token_number: int):
            self.callback_table[token](value)
        #try:
        #except Exception as e:
        #    print("Exception:", e, file=sys.stderr)
        #    print(f"Unexpected {ordinal(token_number)} token '{value}' at line {line_number}.")
        #    exit(2)
    
    def type(self, value: str):
        if ParserStates.FUNCTION_RETURN_TYPE == self.state:
            self.state = ParserStates.FUNCTION_NAME
            self.current_function = Function(value)
        elif ParserStates.EXPRESSION == self.state:
            self.state = ParserStates.VARIABLE_NAME
            self.current_variable = Variable(value)
        else:
            raise Exception()

    def keyword(self, value: str):
        value = Keywords(value)
        if ParserStates.EXPRESSION == self.state:
            if Keywords.RETURN == value:
                self.current_function.body.append(value)
                self.state = ParserStates.EXPRESSION

    def identifier(self, value: str):
        if ParserStates.FUNCTION_NAME == self.state:
            self.state = ParserStates.FUNCTION_PARAMETERS_OPENED
            self.current_function.name = value
            self.function_table.add(self.current_function)
        elif ParserStates.VARIABLE_NAME == self.state:
            self.state = ParserStates.VARIABLE_ASSIGNMENT_OR_SEMICOLON
            self.current_variable.name = value
        elif ParserStates.EXPRESSION == self.state:
            self.expression_analyzer.add_variable_operand(value)
        else:
            raise Exception()

    def opened_bracket(self, _: str):
        if ParserStates.FUNCTION_PARAMETERS_OPENED == self.state:
            self.state = ParserStates.FUNCTION_PARAMETER_TYPE_OR_CLOSED
            self.variable_table.increase_scope()
        else:
            raise Exception()

    def closed_bracket(self, _: str):
        if ParserStates.FUNCTION_PARAMETER_TYPE_OR_CLOSED == self.state:
            self.state = ParserStates.FUNCTION_BODY_OPENED
        else:
            raise Exception()

    def opened_parentheses(self, _: str):
        if ParserStates.FUNCTION_BODY_OPENED == self.state:
            self.current_function.body.append(InnerAlphabet.FUNCTION_START)
            self.state_stack.append(self.state)
            self.state = ParserStates.EXPRESSION
        else:
            raise Exception()

    def closed_parentheses(self, _: str):
        if ParserStates.FUNCTION_BODY_OPENED == self.state:
            self.state = ParserStates.FUNCTION_RETURN_TYPE
            self.current_function.body.append(InnerAlphabet.FUNCTION_END)
            self.current_function = None
            self.variable_table.decrease_scope()
        elif ParserStates.EXPRESSION == self.state:
            self.state = self.state_stack.pop()
            if ParserStates.FUNCTION_BODY_OPENED == self.state:
                self.current_function.body.append(InnerAlphabet.FUNCTION_END)
                print(self.current_function)
                self.current_function = None
                self.variable_table.decrease_scope()
        else:
            raise Exception()

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
            self.current_function.body.append(self.current_variable)
            self.current_variable = None
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
        elif ParserStates.EXPRESSION == self.state:
            self.state = ParserStates.EXPRESSION
            self.expression_analyzer.add_semicolon()
            self.current_function.body += self.expression_analyzer.retrieve_expression()
            self.current_function.body.append(InnerAlphabet.EXPRESSION_END)
        else:
            raise Exception()
        
