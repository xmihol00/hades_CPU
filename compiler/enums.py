from enum import Enum

class Tokens(Enum):
    KEYWORD = 1
    TYPE = 2
    IDENTIFIER = 3
    OPENED_BRACKET = 4
    CLOSED_BRACKET = 5
    OPENED_PARENTHESES = 6
    CLOSED_PARENTHESES = 7
    INTEGER = 8
    BOOLEAN = 9
    ASSIGNMENT = 10
    OPERATOR = 11
    SEMICOLON = 12

class Keywords(Enum):
    RETURN = "return"
    IF = "if"
    ELSE = "else"

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

class InnerAlphabet(Enum):
    LAST_RESULT = "<LR>"
    EXPRESSION_END = "<EE>"
    FUNCTION_START = "<FS>"
    FUNCTION_END = "<FE>"
