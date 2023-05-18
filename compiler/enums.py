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


class VariableUsage(Enum):
    DECLARATION = 1
    ASSIGNMENT = 2
    DECLARATION_WITH_ASSIGNMENT = 3
    EXPRESSION = 4

PRINT_INDENT = ""
class InnerAlphabet(Enum):
    EXPRESSION_END = 0
    FUNCTION_START = 1
    FUNCTION_END = 2
    SCOPE_INCREMENT = 3
    SCOPE_DECREMENT = 4

    def __str__(self) -> str:
        global PRINT_INDENT

        old_indent = PRINT_INDENT
        if self == InnerAlphabet.SCOPE_INCREMENT or self == InnerAlphabet.FUNCTION_START:
            PRINT_INDENT += "  "
        elif self == InnerAlphabet.SCOPE_DECREMENT or self == InnerAlphabet.FUNCTION_END:
            PRINT_INDENT = PRINT_INDENT[:-2]
            old_indent = PRINT_INDENT

        pre_new_line = f"\n{old_indent}" if self != InnerAlphabet.EXPRESSION_END else ''
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