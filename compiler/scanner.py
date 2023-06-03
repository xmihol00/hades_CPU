import re
import sys
from enums import Tokens

class Scanner:
    def __init__(self, program: str):
        self.regex = (
            r"(\n)|" +                                                              # new line
            r"(//.*\n|#.*\n)|" +                                                    # line comment or preprocessor directive
            r"(return|if|else|for|while|break)|" +                                  # keywords
            r"(int)|" +                                                             # types
            r"([a-zA-Z_][a-zA-Z0-9_]*)|" +                                          # identifiers
            r"(\()|(\))|(\{)|(\})|(\[)|(\])|" +                                     # brackets
            r"(\d+)|" +                                                             # integers
            r"(true|false)|"                                                        # booleans
            r"(\+|-|\*|<<<|>>>|<<|>>|&&|&|\|\||\||\^|>=|<=|>|<|==|!=|!|~)|" +       # operators
            r"(=)|" +                                                               # assignment
            r"(;)|" +                                                               # semicolon
            r"(,)|" +                                                               # comma
            r"('.'|'\\.'|'\\\d\d'|'\\\d\d\d')|" +                                   # character
            r"([^\s]*?)|"                                                           # not a whitespace
        )
        self.program = program
        self.line_number = 1
        self.token_number = 0
    
    def scan(self) -> tuple[Tokens, str, int, int]:
        for match in re.finditer(self.regex, self.program):
            for i in range(1, len(match.groups()) + 1):
                if match.group(i):
                    if i <= 2:
                        self.line_number += 1
                        self.token_number = 0
                    elif i == len(match.groups()):
                        raise Exception(f"Unexpected character{'s' if len(match.group(i)) > 1 else ''} '{match.group(i)}' at line {self.line_number}")
                    else:
                        self.token_number += 1
                        yield Tokens(i - 2), match.group(i), self.line_number, self.token_number
