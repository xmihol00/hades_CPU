from enums import InternalAlphabet, Keywords, Operators, Types, VariableUsage

class Construct():
    def __init__(self, comment, line_number: int = None, token_number: int = None):
        self.comment = comment
        self.line_number = line_number
        self.token_number = token_number
    
    def to_comment(self):
        return self.comment

class Variable(Construct):
    def __init__(self, type: str = None, offset: int = None, name: str = None, usage: VariableUsage = None):
        super().__init__(name)
        self.type = None
        if type:
            self.type = Types(type)
        self.name = name
        self.usage = usage
        self.offset = offset
    
    def set_usage(self, usage: VariableUsage):
        if self.type and usage == VariableUsage.ASSIGNMENT:
            self.usage = VariableUsage.DECLARATION_WITH_ASSIGNMENT
        else:
            self.usage = usage
    
    def set_name(self, name: str):
        self.name = name
        self.comment = name
    
    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

class Function(Construct):
    def __init__(self, return_type: str = None, name: str = None):
        super().__init__(f"{name}()")
        self.return_type = Types(return_type)
        self.name = name
        self.parameters: list[Variable] = []
        self.body: list[Variable|Constant|ReturnValue|IntermediateResult|FunctionCall|InternalAlphabet|Types|Operators|Keywords] = []
        self.number_of_parameters = 0
    
    def assign_parameters_offset(self):
        for i, parameter in enumerate(self.parameters):
            parameter.offset = self.number_of_parameters - i + 1
    
    def add_parameter(self, parameter: Variable):
        self.parameters.append(parameter)
        self.number_of_parameters += 1
        self.comment = f"{self.name}({'.' * self.number_of_parameters})"
        
    def __str__(self) -> str:
        return f"{self.return_type} {self.__class__.__name__}.{self.name}({', '.join([str(parameter).strip() for parameter in self.parameters])}) {' '.join([str(expression) for expression in self.body])}"

class FunctionCall(Construct):
    def __init__(self, name: str = None, number_of_parameters: int = 0):
        super().__init__(f"call of {name}({'.' * number_of_parameters})")
        self.name = name
        self.number_of_parameters = number_of_parameters
    
    def add_parameter(self):
        self.number_of_parameters += 1
        self.comment = f"call of {self.name}({'.' * self.number_of_parameters})"
    
    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}(...)"

class Constant(Construct):
    def __init__(self, type: str = None, value: str|int|float|bool = None):
        super().__init__(value)
        self.type = None
        if type:
            self.type = Types(type)
        self.value = value
    
    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.value}"

class IntermediateResult(Construct):
    def __init__(self, number: int):
        super().__init__(f"intermediate_result_{number}")
        self.number = number
    
    def set_comment(self, comment: str):
        self.comment = f"({comment})"
    
    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.number}"

class Parameter(Construct):
    def __init__(self, number: int, function: FunctionCall):
        super().__init__(f"parameter {number}")
        self.number = number
        self.function = function
    
    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.number}"

class ReturnValue(Construct):
    def __init__(self, function: FunctionCall):
        super().__init__(f"{function.name}({'.' * function.number_of_parameters})")
        self.function = function
    
    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.function.name}"
