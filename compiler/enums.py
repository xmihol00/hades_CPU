from enum import Enum

class Tokens(Enum):
    KEYWORD = 1
    TYPE = 2
    IDENTIFIER = 3
    OPENED_BRACKET = 4
    CLOSED_BRACKET = 5
    OPENED_CURLY_BRACKET = 6
    CLOSED_CURLY_BRACKET = 7
    OPENED_SQUARE_BRACKET = 8
    CLOSED_SQUARE_BRACKET = 9
    INTEGER = 10
    BOOLEAN = 11
    OPERATOR = 12
    ASSIGNMENT = 13
    SEMICOLON = 14
    COMMA = 15
    CHARACTER = 16

class Keywords(Enum):
    def __init__(self, value) -> None:
        super().__init__()
        self.comment = ""

    RETURN = "return"
    IF = "if"
    ELSE = "else"
    ELSE_IF = "else_if"
    WHILE = "while"
    FOR = "for"
    BREAK = "break"

    def set_comment(self, comment: str):
        self.comment = comment
    
    def to_label(self, function_name: str, scope_ids: list[int], scope_index: int, else_if_counter: int = None):
        if self.value == Keywords.ELSE_IF.value:
            return f"{function_name}.{self.value}_{'_'.join(map(str, scope_ids[:scope_index + 1]))}.{else_if_counter}"
        else:
            return f"{function_name}.{self.value}_{'_'.join(map(str, scope_ids[:scope_index + 1]))}"

class Types(Enum):
    VOID = "void"
    INT = "int"
    PTR = "ptr"

class HighAssemblyInstructions(Enum):
    LOAD = "LOAD"
    STORE = "STORE"
    MOV = "MOV"
    PUSH = "PUSH"
    PUSHA = "PUSHA"
    POP = "POP"
    POPA = "POPA"
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
    JZ = "JZ"
    JNZ = "JNZ"
    JMP = "JMP"
    IN = "IN"
    OUT = "OUT"

    def __str__(self) -> str:
        return f"{self.value}"
    
    def to_regex(self) -> str:
        if self == HighAssemblyInstructions.PUSH:
            return r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_]*)\s*(;\s*(.*))*$)|"  # PUSH <register> (4 groups)
        elif self == HighAssemblyInstructions.POP:
            return r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_]*)\s*(;\s*(.*))*$)|"  # POP <register>  (4 groups)
        elif self == HighAssemblyInstructions.PUSHA:
            return r"(^\s*" + self.value + r"\s*(;\s*(.*))*$)|"  # PUSHA           (3 group)
        elif self == HighAssemblyInstructions.POPA:
            return r"(^\s*" + self.value + r"\s*(;\s*(.*))*$)|"  # POPA            (3 group)
        elif self == HighAssemblyInstructions.LOAD:
            return (
                r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_]*)\s+\[([a-z_][a-z0-9_]*)"
                    r"(?:(\+|\-)(\d+)){0,1}\]\s*(;\s*(.*))*$)|" +                                        # LOAD <register> <memory>          (7 groups)
                r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_]*)\s+@([a-z_][a-z0-9_]*)\s*(;\s*(.*))*$)|"  # LOAD <register> <global variable> (5 groups)
            )
        elif self == HighAssemblyInstructions.MOV:
            return (
                r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_]*)\s+(-{0,1}\d+)\s*(;\s*(.*))*$)|" +       # LOAD <register> <constant> (5 groups)
                r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_]*)\s+([a-z_][a-z0-9_]*)\s*(;\s*(.*))*$)|"  # LOAD <register> <register> (5 groups)
            )
        elif self == HighAssemblyInstructions.STORE:
            return (
                r"(^\s*" + self.value + r"\s+\[([a-z_][a-z0-9_]*)(?:(\+|\-)(\d+)){0,1}\]"
                    r"\s+([a-z_][a-z0-9_]*)\s*(;\s*(.*))*$)|" +                                         # STORE <memory> <register>          (7 groups)
                r"(^\s*" + self.value + r"\s+@([a-z_][a-z0-9_]*)\s+([a-z_][a-z0-9_]*)\s*(;\s*(.*))*$)|" # STORE <global variable> <register> (5 groups)
            )
        elif self == HighAssemblyInstructions.CALL:
            return r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_]*)\s*(;\s*(.*))*$)|"     # CALL <function label> (4 groups)
        elif self == HighAssemblyInstructions.RETURN:
            return (
                r"(^\s*" + self.value + r"\s+(\d+)\s*(;\s*(.*))*$)|" +    # RETURN <number of cleared parameters from the stack> (4 groups)
                r"(^\s*" + self.value + r"\s*(;\s*(.*))*$)|"              # RETURN                                               (3 groups)
            )                  
        elif self == HighAssemblyInstructions.JMP:
            return r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_\.]*)\s*(;\s*(.*))*$)|"     # JMP <label> (4 groups)
        elif self == HighAssemblyInstructions.JZ or self == HighAssemblyInstructions.JNZ:
            return r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_]*)\s+([a-z_][a-z0-9_\.]*)\s*(;\s*(.*))*$)|" # JZ/JNZ <register> <label> (5 groups)
        elif self == HighAssemblyInstructions.NOT or self == HighAssemblyInstructions.NEG:
            return (
                r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_]*)\s+(-{0,1}\d+)\s*(;\s*(.*))*$)|" +        # NOT/NEG <register> <constant> (5 groups)
                r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_]*)\s+([a-z_][a-z0-9_]*)\s*(;\s*(.*))*$)|"   # NOT/NEG <register> <register> (5 groups)
            )
        elif self == HighAssemblyInstructions.IN or self == HighAssemblyInstructions.OUT:
            return r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_]*)\s+(\d+)\s*(;\s*(.*))*$)|"     # IN/OUT <register> <positive constant> (5 groups)
        else:
            return self._ALU_instruction_to_regex()
    
    def _ALU_instruction_to_regex(self):
        return (
            r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_]*)\s+([a-z_][a-z0-9_]*)\s+(-{0,1}\d+)\s*(;\s*(.*))*$)|" +      # <ALU instruction> <register> <register> <constant> (6 groups)
            r"(^\s*" + self.value + r"\s+([a-z_][a-z0-9_]*)\s+([a-z_][a-z0-9_]*)\s+([a-z_][a-z0-9_]*)\s*(;\s*(.*))*$)|" # <ALU instruction> <register> <register> <register> (6 groups)
        )

class Operators(Enum):
    LOGICAL_NOT = "!"                   # precedence 11
    BITWISE_NOT = "~"
    UNARY_PLUS = "U+"
    UNARY_MINUS = "U-"
    DEREFERENCE = "U*"
    ASSIGNMENT_DEREFERENCE = "U*="
    OFFSET_DEREFERENCE = "[]"
    OFFSET_ASSIGNMENT_DEREFERENCE = "[]="

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
        if self == Operators.PLUS or self == Operators.UNARY_PLUS or self == Operators.OFFSET_DEREFERENCE:
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
        elif self == Operators.DEREFERENCE or self == Operators.ASSIGNMENT_DEREFERENCE:
            return HighAssemblyInstructions.LOAD
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
    EQUAL_ZERO_JUMP = 5

    def __str__(self) -> str:
        global PRINT_INDENT

        old_indent = PRINT_INDENT
        if self == InternalAlphabet.SCOPE_INCREMENT or self == InternalAlphabet.FUNCTION_START:
            PRINT_INDENT += "  "
        elif self == InternalAlphabet.SCOPE_DECREMENT or self == InternalAlphabet.FUNCTION_END:
            PRINT_INDENT = PRINT_INDENT[:-2]
            old_indent = PRINT_INDENT

        pre_new_line = f"\n{old_indent}" if self != InternalAlphabet.EXPRESSION_END and self != InternalAlphabet.EQUAL_ZERO_JUMP else ''
        post_new_line = f"\n{PRINT_INDENT}" if self != InternalAlphabet.EQUAL_ZERO_JUMP else ''
        return f"{pre_new_line}{self.__class__.__name__}.{self.name}{post_new_line}"

class ScopeTypes(Enum):
    GLOBAL = 1
    FUNCTION = 2
    IF = 3
    ELSE = 4
    WHILE = 5
    FOR_HEADER = 6
    FOR_BODY = 7
    BLOCK = 8
    IF_OPENED = 9
    WHILE_OPENED = 10
    FOR_HEADER_OPENED = 6

    def to_opened(self):
        if self == ScopeTypes.IF:
            return ScopeTypes.IF_OPENED
        elif self == ScopeTypes.WHILE:
            return ScopeTypes.WHILE_OPENED
        elif self == ScopeTypes.FOR_HEADER:
            return ScopeTypes.FOR_HEADER_OPENED
        else:
            return self

class RegisterStates(Enum):
    FREE = 1
    USED = 2
    EMPTY = 3

class TargetAssemblyHelpers(Enum):
    DATA_LABEL = "@data"
    CODE_LABEL = "@code"
    SCOPE_OPEN = "{"
    SCOPE_CLOSE = "@}\n"
    CONSTANT_PREFIX = "#"
    DEFINE_PREFIX = "@def"

    def __str__(self) -> str:
        return self.value

class TargetAssemblyInstructions(Enum):
    LOAD = "LOAD"
    STORE = "STORE"
    LDI = "LDI"
    MOV = "MOV"
    ADD = "ADD"
    ADDI = "ADDI"
    SUB = "SUB"
    SUBI = "SUBI"
    MUL = "MUL"
    MULI = "MULI"
    AND = "AND"
    ANDI = "ANDI"
    OR = "OR"
    ORI = "ORI"
    XOR = "XOR"
    XORI = "XORI"
    XNOR = "XNOR"
    XNORI = "XNORI"
    SHL = "SHL"
    SHLI = "SHLI"
    SHR = "SHR"
    SHRI = "SHRI"
    CSHL = "CSHL"
    CSHLI = "CSHLI"
    CSHR = "CSHR"
    CSHRI = "CSHRI"
    JAL = "JAL"
    JMP = "JMP"
    JREG = "JREG"
    BEQZ = "BEQZ"
    BNEZ = "BNEZ"
    BOV = "BOV"
    SEQ = "SEQ"
    SEQI = "SEQI"
    SNE = "SNE"
    SNEI = "SNEI"
    SLT = "SLT"
    SLTI = "SLTI"
    SLE = "SLE"
    SLEI = "SLEI"
    SGT = "SGT"
    SGTI = "SGTI"
    SGR = "SGE"
    SGRI = "SGEI"
    IN = "IN"
    OUT = "OUT"

    def __str__(self) -> str:
        return self.value

class TargetAssemblyRegisters(Enum):
    R0 = "r0"
    R1 = "r1"
    R2 = "r2"
    R3 = "r3"
    EAX = "@eax"
    EDX = "@edx"
    EBP = "@ebp"
    ESP = "@esp"

    def __str__(self) -> str:
        return self.value
