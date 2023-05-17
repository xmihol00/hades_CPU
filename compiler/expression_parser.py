from enum import Enum
from enums import InnerAlphabet, Operators, Types, VariableUsage
from constructs import Variable, Constant

class ExpressionParserStates(Enum):
    UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET = 1
    BINARY_OPERATOR_OR_CLOSED_BRACKET = 2

UNARY_OPERATORS = [
    Operators.LOGICAL_NOT,
    Operators.BITWISE_NOT,
    Operators.UNARY_PLUS,
    Operators.UNARY_MINUS,
    Operators.ASSIGNMENT
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
    Operators.LOGICAL_OR
]

class ExpressionParser:
    def __init__(self) -> None:
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
            Operators.ASSIGNMENT: 0
        }
        self.current_precedence = -1
        self.precedence_stack = []
        self.state = ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET
        self.expression = []
        self.operand_stack = []
        self.operator_stack = []
    
    def add_assignment(self):
        if (ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET == self.state and 
            len(self.operand_stack) == 0 and len(self.operator_stack) == 0 and len(self.expression) == 0):
            self.operator_stack.append(Operators.ASSIGNMENT)
            self.current_precedence = self.operator_precedence[Operators.ASSIGNMENT]
        else:
            raise Exception()
    
    def add_variable_operand(self, operand: str):
        if ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET == self.state:
            operand = Variable(name=operand, usage=VariableUsage.EXPRESSION)
            self.operand_stack.append(operand)
            self.state = ExpressionParserStates.BINARY_OPERATOR_OR_CLOSED_BRACKET
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
        precedence = self.operator_precedence[operator]
        if (operator == Operators.PLUS or operator == Operators.MINUS) and ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET == self.state:
            operator = Operators.UNARY_PLUS if operator == Operators.PLUS else Operators.UNARY_MINUS

        if (operator in UNARY_OPERATORS and ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET or
            operator in BINARY_OPERATORS and ExpressionParserStates.BINARY_OPERATOR_OR_CLOSED_BRACKET == self.state):
            if precedence > self.current_precedence:
                self.state = ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET
                self.current_precedence = precedence
                self.operator_stack.append(operator)
            else:
                self._pop_stacks_insert_expression(precedence)
        else:
            raise Exception()

    def add_opened_bracket(self):
        pass

    def add_closed_bracket(self):
        pass

    def add_semicolon(self):
        precedence = -1
        if ExpressionParserStates.BINARY_OPERATOR_OR_CLOSED_BRACKET:
            self._pop_stacks_insert_expression(precedence)
        else:
            raise Exception()
    
    def retrieve_expression(self) -> list:
        if (ExpressionParserStates.BINARY_OPERATOR_OR_CLOSED_BRACKET == self.state and 
            self.current_precedence == -1 and len(self.operator_stack) == 0 and len(self.precedence_stack) == 0):
            self.operand_stack = []
            expression = self.expression
            self.expression = []
            self.operand_stack = []
            self.state = ExpressionParserStates.UNARY_OPERATOR_OR_OPERAND_OR_OPENED_BRACKET
        else:
            raise Exception()
        return expression
    
    def _pop_stacks_insert_expression(self, precedence: int):
        while len(self.operator_stack) and precedence <= self.operator_precedence[self.operator_stack[-1]]:
            popped_operator = self.operator_stack.pop()
            self.expression.append(popped_operator)

            if popped_operator in UNARY_OPERATORS:
                self.expression.append(self.operand_stack.pop())
            elif popped_operator in BINARY_OPERATORS:
                operand2 = self.operand_stack.pop()
                operand1 = self.operand_stack.pop()
                self.expression.append(operand1)
                self.expression.append(operand2)

            self.operand_stack.append(InnerAlphabet.LAST_RESULT)
        self.current_precedence = precedence
