from constructs import Function

class FunctionTable():
    def __init__(self):
        self.functions = {}
    
    def add(self, function: Function):
        if function.name in self.functions:
            raise Exception(f"Function {function.name} already exists.")
        self.functions[function.name] = function
    
    def __str__(self) -> str:
        return "\n\n".join([str(function) for function in self.functions])
