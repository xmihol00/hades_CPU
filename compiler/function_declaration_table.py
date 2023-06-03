from constructs import Function
import re

class FunctionDeclarationTable():
    def __init__(self):
        self.functions: list[Function] = {}
    
    def add(self, function: Function):
        if function.name in self.functions:
            raise Exception(f"Function {function.name} already exists.")
        self.functions[function.name] = function
    
    def exists(self, name: str, number_of_parameters: int) -> bool:
        if name in self.functions:
            return self.functions[name].number_of_parameters == number_of_parameters
        return False

    def main_exists(self) -> bool:
        return "main" in self.functions and self.functions["main"].number_of_parameters == 0
    
    def __str__(self) -> str:
        return "\n\n".join(['\n'.join(filter(lambda x: not re.match(r"^\s*$", x), str(function).split('\n'))) for function in self.functions.values()])
