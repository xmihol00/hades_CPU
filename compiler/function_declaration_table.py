from constructs import Function
import re

class FunctionDeclarationTable():
    def __init__(self):
        self.functions = {}
    
    def add(self, function: Function):
        if function.name in self.functions:
            raise Exception(f"Function {function.name} already exists.")
        self.functions[function.name] = function
    
    def __str__(self) -> str:
        return "\n\n".join([ '\n'.join(filter(lambda x: not re.match(r"^\s*$", x), str(function).split('\n'))) for function in self.functions.values()])
