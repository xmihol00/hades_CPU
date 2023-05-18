from enums import Types, VariableUsage

class Function():
    def __init__(self, return_type: str = None, name: str = None):
        self.return_type = Types(return_type)
        self.name = name
        self.parameters = []
        self.body = []
    
    def __str__(self) -> str:
        return f"{self.return_type} {self.__class__.__name__}.{self.name}({', '.join([str(parameter).strip() for parameter in self.parameters])}) {' '.join([str(expression) for expression in self.body])}"

class FunctionCall():
    def __init__(self, name: str = None, number_of_parameters: int = 0):
        self.name = name
        self.number_of_parameters = number_of_parameters
    
    def add_parameter(self):
        self.number_of_parameters += 1
    
    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}({','.join([str(parameter) for parameter in self.number_of_parameters])})"

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
        return f"{self.__class__.__name__}.{self.name}"

class Constant():
    def __init__(self, type: str = None, value: str|int|float|bool = None):
        self.type = None
        if type:
            self.type = Types(type)
        self.value = value
    
    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.value}"

class IntermediateResult():
    def __init__(self, number: int):
        self.number = number
    
    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.number}"

class Parameter():
    def __init__(self, number: int, function: FunctionCall):
        self.number = number
        self.function = function
    
    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.number}"

class ReturnValue():
    def __init__(self, function: FunctionCall):
        self.function = function
    
    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.function.name}"
