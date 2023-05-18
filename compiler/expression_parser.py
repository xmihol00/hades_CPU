from enum import Enum

from function_call_table import FunctionCallTable
from variable_table import VariableTable
from enums import InnerAlphabet, Operators, Types, VariableUsage
from constructs import FunctionCall, IntermediateResult, ReturnValue, Variable, Constant, Parameter

class ExpressionParserStates(Enum):
    UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET = 1
    BINARY_OPERATOR_OR_CLOSED_BRACKET = 2
    FUNCTION_CALL = 3

UNARY_OPERATORS = [
    Operators.LOGICAL_NOT,
    Operators.BITWISE_NOT,
    Operators.UNARY_PLUS,
    Operators.UNARY_MINUS
]

BINARY_OPERATORS = [
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
    Operators.PARAMETER_ASSIGNMENT,
    Operators.PARAMETER_POSSIBLE_ASSIGNMENT
]

class ExpressionParser:
    def __init__(self, function_call_table: FunctionCallTable, variable_table: VariableTable) -> None:
        self.operator_precedence = {
            Operators.LOGICAL_NOT: 11,
            Operators.BITWISE_NOT: 11,
            Operators.UNARY_PLUS: 11,
            Operators.UNARY_MINUS: 11,
            Operators.MULTIPLY: 10,
            Operators.PLUS: 9,
            Operators.MINUS: 9,
            Operators.RIGHT_SHIFT: 8,
            Operators.LEFT_SHIFT: 8,
            Operators.RIGHT_ROTATION_SHIFT: 8,
            Operators.LEFT_ROTATION_SHIFT: 8,
            Operators.LOGICAL_LESS: 7,
            Operators.LOGICAL_LESS_OR_EQUAL: 7,
            Operators.LOGICAL_GREATER: 7,
            Operators.LOGICAL_GREATER_OR_EQUAL: 7,
            Operators.LOGICAL_EQUAL: 6,
            Operators.LOGICAL_NOT_EQUAL: 6,
            Operators.BITWISE_AND: 5,
            Operators.BITWISE_XOR: 4,
            Operators.BITWISE_OR: 3,
            Operators.LOGICAL_AND: 2,
            Operators.LOGICAL_OR: 1,
            Operators.ASSIGNMENT: 0,
            Operators.PARAMETER_ASSIGNMENT: 0,
            Operators.PARAMETER_POSSIBLE_ASSIGNMENT: 0
        }
        self.function_call_table = function_call_table
        self.variable_table = variable_table
        self.state = ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET
        self.current_precedence = -1
        self.bracket_stack = []
        self.expression = []
        self.operand_stack = []
        self.operator_stack = []
        self.function_call_stack = []
        self.current_function_call = None
        self.in_function_call = False
        self.intermediate_results_count = 0
    
    def add_assignment(self):
        if len(self.operand_stack) == 1 and len(self.operator_stack) == 0 and len(self.expression) == 0:
            self.operator_stack.append(Operators.ASSIGNMENT)
            self.current_precedence = self.operator_precedence[Operators.ASSIGNMENT]
            self.state = ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET
        else:
            raise Exception()
    
    def add_identifier_operand(self, operand: str|Variable):
        if ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET == self.state:
            if isinstance(operand, str):
                operand = Variable(name=operand, usage=VariableUsage.EXPRESSION)
            if self.variable_table.exists(operand.name):
                self.operand_stack.append(operand)
                self.state = ExpressionParserStates.BINARY_OPERATOR_OR_CLOSED_BRACKET
            else:
                self.state = ExpressionParserStates.FUNCTION_CALL
                if self.current_function_call:
                    self.function_call_stack.append(self.current_function_call)                
                self.current_function_call = FunctionCall(name=operand.name)
        else:
            raise Exception()
    
    def add_constant_operand(self, type: Types, operand: str|bool|int):
        if ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET == self.state:
            operand = Constant(type=type, value=operand)
            self.operand_stack.append(operand)
            self.state = ExpressionParserStates.BINARY_OPERATOR_OR_CLOSED_BRACKET
        else:
            raise Exception()

    def add_operator(self, operator: str):
        operator = Operators(operator)
        if (operator == Operators.PLUS or operator == Operators.MINUS) and ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET == self.state:
            operator = Operators.UNARY_PLUS if operator == Operators.PLUS else Operators.UNARY_MINUS

        precedence = self.operator_precedence[operator]
        if (operator in UNARY_OPERATORS and ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET == self.state or
            operator in BINARY_OPERATORS and ExpressionParserStates.BINARY_OPERATOR_OR_CLOSED_BRACKET == self.state):
            self.state = ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET if operator in BINARY_OPERATORS else self.state
            self._pop_stacks_insert_expression(precedence)
            self.operator_stack.append(operator)
        else:
            raise Exception()

    def add_opened_bracket(self):
        self.bracket_stack.append((self.current_precedence, self.operator_stack, self.operand_stack, self.in_function_call))
        self.operator_stack = []
        self.operand_stack = []
        self.current_precedence = -1
        if ExpressionParserStates.FUNCTION_CALL == self.state:
            self.in_function_call = True
            self.state = ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET
            self.operand_stack.append(Parameter(0, self.current_function_call))
            self.operator_stack.append(Operators.PARAMETER_POSSIBLE_ASSIGNMENT)
            self.current_precedence = self.operator_precedence[Operators.PARAMETER_POSSIBLE_ASSIGNMENT]
        elif ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET != self.state:
            raise Exception()

    def add_closed_bracket(self):
        if ExpressionParserStates.BINARY_OPERATOR_OR_CLOSED_BRACKET == self.state:
            self._pop_stacks_insert_expression(-1)
            if len(self.bracket_stack) > 0 and len(self.operand_stack) == 1:
                if self.in_function_call:
                    self.operand_stack.pop()
                    self.intermediate_results_count -= 1
                    self.current_function_call.add_parameter()
                    self.function_call_table.add(self.current_function_call)
                    scope_result = ReturnValue(self.current_function_call)
                else:
                    scope_result = self.operand_stack.pop()
                    
                self.current_precedence, self.operator_stack, self.operand_stack, self.in_function_call = self.bracket_stack.pop()
                if self.in_function_call:
                    self.current_function_call = self.function_call_stack.pop()
                else:
                    self.current_function_call = None

                self.operand_stack.append(scope_result)
                return
        elif (self.in_function_call and ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET == self.state and
              isinstance(self.operand_stack[-1], Parameter) and self.operator_stack[-1] == Operators.PARAMETER_POSSIBLE_ASSIGNMENT):
            self.operand_stack.pop()
            self.operator_stack.pop()
            self.state = ExpressionParserStates.BINARY_OPERATOR_OR_CLOSED_BRACKET
            self.current_precedence, self.operator_stack, self.operand_stack, self.in_function_call = self.bracket_stack.pop()
            self.operand_stack.append(ReturnValue(self.current_function_call))
            self.function_call_table.add(self.current_function_call)
            if self.in_function_call:
                self.current_function_call = self.function_call_stack.pop()
            else:
                self.current_function_call = None
            return
            
        raise Exception()

    def add_semicolon(self):
        if ExpressionParserStates.BINARY_OPERATOR_OR_CLOSED_BRACKET:
            self._pop_stacks_insert_expression(-1)
            if len(self.operand_stack) and not len(self.operator_stack) and isinstance(self.operand_stack[-1], ReturnValue):
                self.expression.append(self.operand_stack.pop())
        else:
            raise Exception()
    
    def add_comma(self):
        if ExpressionParserStates.BINARY_OPERATOR_OR_CLOSED_BRACKET == self.state and self.in_function_call:
            self._pop_stacks_insert_expression(-1)
            self.current_function_call.add_parameter()
            self.operand_stack.pop()
            self.intermediate_results_count -= 1
            self.operand_stack.append(Parameter(self.current_function_call.number_of_parameters, self.current_function_call))
            self.operator_stack.append(Operators.PARAMETER_ASSIGNMENT)
            self.state = ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET
        else:
            raise Exception()
    
    def is_expression_valid(self) -> bool:
        return (ExpressionParserStates.BINARY_OPERATOR_OR_CLOSED_BRACKET == self.state and 
            self.current_precedence == -1 and len(self.operator_stack) == 0 and len(self.bracket_stack) == 0)
    
    def retrieve_expression(self) -> list:
        if (ExpressionParserStates.BINARY_OPERATOR_OR_CLOSED_BRACKET == self.state and 
            self.current_precedence == -1 and len(self.operator_stack) == 0 and len(self.bracket_stack) == 0):
            if len(self.operand_stack) and (isinstance(self.operand_stack[-1], Variable) or isinstance(self.operand_stack[-1], Constant)):
                self.expression.append(self.operand_stack.pop())
            expression = self.expression
            self.expression = []
            self.operand_stack = []
            self.operator_stack = []
            self.state = ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET
            self.intermediate_results_count = 0
        else:
            raise Exception()
        return expression
    
    def _pop_stacks_insert_expression(self, precedence: int):
        while len(self.operator_stack) and precedence <= self.operator_precedence[self.operator_stack[-1]]:
            popped_operator = self.operator_stack.pop()
            if popped_operator == Operators.PARAMETER_POSSIBLE_ASSIGNMENT:
                popped_operator = Operators.PARAMETER_ASSIGNMENT
            self.expression.append(popped_operator)

            operand2 = self.operand_stack.pop()
            operand1 = None
            if popped_operator in UNARY_OPERATORS:
                self.expression.append(operand2)
            elif popped_operator in BINARY_OPERATORS:
                operand1 = self.operand_stack.pop()
                self.expression.append(operand1)
                self.expression.append(operand2)
            
            if isinstance(operand1, IntermediateResult):
                self.intermediate_results_count -= 1
            if isinstance(operand2, IntermediateResult):
                self.intermediate_results_count -= 1

            self.operand_stack.append(IntermediateResult(self.intermediate_results_count))
            self.intermediate_results_count += 1

        self.current_precedence = precedence
