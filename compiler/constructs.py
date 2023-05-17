from enums import Types, VariableUsage

class Function():
    def __init__(self, return_type: str = None, name: str = None):
        self.return_type = Types(return_type)
        self.name = name
        self.parameters = []
        self.body = []
    
    def __str__(self) -> str:
        return f"{self.return_type} {self.name}({', '.join([str(parameter) for parameter in self.parameters])}) {' '.join([str(expression) for expression in self.body])}'"

class FunctionCall():
    def __init__(self, name: str = None, parameters: list = None):
        self.name = name
        self.parameters = parameters
    
    def __str__(self) -> str:
        return f"FunctionCalls.{self.name}({', '.join([str(parameter) for parameter in self.parameters])})"

class Variable():
    def __init__(self, type: str = None, name: str = None, usage: VariableUsage = None):
        self.type = None
        if type:
            self.type = Types(type)
        self.name = name
        self.usage = usage
    
    def set_usage(self, usage: VariableUsage):
        if self.type and usage == VariableUsage.ASSIGNMENT:
            self.usage = VariableUsage.DECLARATION_WITH_ASSIGNMENT
        else:
            self.usage = usage
    
    def __str__(self) -> str:
        return f"Variables.{self.name}"

class Constant():
    def __init__(self, type: str = None, value: str|int|float|bool = None):
        self.type = None
        if type:
            self.type = Types(type)
        self.value = value
    
    def __str__(self) -> str:
        return f"Constants.{self.value}"
