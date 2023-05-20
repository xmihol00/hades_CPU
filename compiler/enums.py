from enum import Enum

class Tokens(Enum):
    KEYWORD = 1
    TYPE = 2
    IDENTIFIER = 3
    OPENED_BRACKET = 4
    CLOSED_BRACKET = 5
    OPENED_CURLY_BRACKET = 6
    CLOSED_CURLY_BRACKET = 7
    INTEGER = 8
    BOOLEAN = 9
    OPERATOR = 10
    ASSIGNMENT = 11
    SEMICOLON = 12
    COMMA = 13

class Keywords(Enum):
    RETURN = "return"
    IF = "if"
    ELSE = "else"
    ELSE_IF = "else if"
    WHILE = "while"
    FOR = "for"
    BREAK = "break"

class Types(Enum):
    VOID = "void"
    INT = "int"
    BOOLEAN = "bool"


class HighAssemblyInstructions(Enum):
    LOAD = "LOAD"
    STORE = "STORE"
    MOV = "MOV"
    PUSH = "PUSH"
    POP = "POP"
    ADD = "ADD"
    SUB = "SUB"
    MUL = "MUL"
    CALL = "CALL"
    RETURN = "RET"
    OR = "OR"
    AND = "AND"
    XOR = "XOR"
    NOT = "NOT"
    NEG = "NEG"
    SHL = "SHL"
    SHR = "SHR"
    ROL = "ROL"
    ROR = "ROR"
    LT = "LT"
    LTE = "LTE"
    GT = "GT"
    GTE = "GTE"
    EQ = "EQ"
    NEQ = "NEQ"

    def __str__(self) -> str:
        return f"{self.value}"

class Operators(Enum):
    LOGICAL_NOT = "!"                   # precedence 11
    BITWISE_NOT = "~"
    UNARY_PLUS = "U+"
    UNARY_MINUS = "U-"

    MULTIPLY = "*"                      # precedence 10

    PLUS = "+"                          # precedence 9
    MINUS = "-"

    RIGHT_SHIFT = ">>"                  # precedence 8
    LEFT_SHIFT = "<<"
    RIGHT_ROTATION_SHIFT = ">>>"
    LEFT_ROTATION_SHIFT = "<<<"

    LOGICAL_LESS = "<"                  # precedence 7
    LOGICAL_LESS_OR_EQUAL = "<="
    LOGICAL_GREATER = ">"
    LOGICAL_GREATER_OR_EQUAL = ">="
    
    LOGICAL_EQUAL = "=="                # precedence 6
    LOGICAL_NOT_EQUAL = "!="

    BITWISE_AND = "&"                   # precedence 5

    BITWISE_XOR = "^"                   # precedence 4

    BITWISE_OR = "|"                    # precedence 3

    LOGICAL_AND = "&&"                  # precedence 2

    LOGICAL_OR = "||"                   # precedence 1

    ASSIGNMENT = "="                    # precedence 0
    PARAMETER_ASSIGNMENT = ":="
    PARAMETER_POSSIBLE_ASSIGNMENT = "?="

    def to_high_assembly_instruction(self) -> HighAssemblyInstructions:
        if self == Operators.PLUS:
            return HighAssemblyInstructions.ADD
        elif self == Operators.MINUS:
            return HighAssemblyInstructions.SUB
        elif self == Operators.MULTIPLY:
            return HighAssemblyInstructions.MUL
        elif self == Operators.LOGICAL_OR:
            return HighAssemblyInstructions.OR
        elif self == Operators.LOGICAL_AND:
            return HighAssemblyInstructions.AND
        elif self == Operators.BITWISE_XOR:
            return HighAssemblyInstructions.XOR
        elif self == Operators.BITWISE_NOT:
            return HighAssemblyInstructions.NOT
        elif self == Operators.BITWISE_OR:
            return HighAssemblyInstructions.OR
        elif self == Operators.BITWISE_AND:
            return HighAssemblyInstructions.AND
        elif self == Operators.RIGHT_SHIFT:
            return HighAssemblyInstructions.SHR
        elif self == Operators.LEFT_SHIFT:
            return HighAssemblyInstructions.SHL
        elif self == Operators.RIGHT_ROTATION_SHIFT:
            return HighAssemblyInstructions.ROR
        elif self == Operators.LEFT_ROTATION_SHIFT:
            return HighAssemblyInstructions.ROL
        elif self == Operators.LOGICAL_LESS:
            return HighAssemblyInstructions.LT
        elif self == Operators.LOGICAL_LESS_OR_EQUAL:
            return HighAssemblyInstructions.LTE
        elif self == Operators.LOGICAL_GREATER:
            return HighAssemblyInstructions.GT
        elif self == Operators.LOGICAL_GREATER_OR_EQUAL:
            return HighAssemblyInstructions.GTE
        elif self == Operators.LOGICAL_EQUAL:
            return HighAssemblyInstructions.EQ
        elif self == Operators.LOGICAL_NOT_EQUAL:
            return HighAssemblyInstructions.NEQ
        elif self == Operators.ASSIGNMENT:
            return HighAssemblyInstructions.MOV
        elif self == Operators.PARAMETER_ASSIGNMENT:
            return HighAssemblyInstructions.PUSH
        elif self == Operators.UNARY_MINUS:
            return HighAssemblyInstructions.NEG
        else:
            raise Exception(f"Operator {self} does not have a high assembly instruction.")

class VariableUsage(Enum):
    DECLARATION = 1
    ASSIGNMENT = 2
    DECLARATION_WITH_ASSIGNMENT = 3
    EXPRESSION = 4

PRINT_INDENT = ""
class InternalAlphabet(Enum):
    EXPRESSION_END = 0
    FUNCTION_START = 1
    FUNCTION_END = 2
    SCOPE_INCREMENT = 3
    SCOPE_DECREMENT = 4

    def __str__(self) -> str:
        global PRINT_INDENT

        old_indent = PRINT_INDENT
        if self == InternalAlphabet.SCOPE_INCREMENT or self == InternalAlphabet.FUNCTION_START:
            PRINT_INDENT += "  "
        elif self == InternalAlphabet.SCOPE_DECREMENT or self == InternalAlphabet.FUNCTION_END:
            PRINT_INDENT = PRINT_INDENT[:-2]
            old_indent = PRINT_INDENT

        pre_new_line = f"\n{old_indent}" if self != InternalAlphabet.EXPRESSION_END else ''
        return f"{pre_new_line}{self.__class__.__name__}.{self.name}\n{PRINT_INDENT}"

class ScopeTypes(Enum):
    GLOBAL = 1
    FUNCTION = 2
    IF = 3
    ELSE = 4
    WHILE = 5
    FOR_HEADER = 6
    FOR_BODY = 7
    BLOCK = 8

class RegisterStates(Enum):
    FREE = 1
    USED = 2
    EMPTY = 3

class PushedTypes(Enum):
    SAVED_REGISTER = 1
    FUNCTION_PARAMETER = 2
